package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"dating-app/im-server/internal/auth"
	"dating-app/im-server/internal/store"
	"dating-app/im-server/internal/ws"
	"dating-app/im-server/pkg/logger"

	"github.com/gorilla/websocket"
)

// Config holds application configuration read from environment variables.
type Config struct {
	Port         string
	RedisHost    string
	RedisPort    int
	RedisPass    string
	PostgresHost string
	PostgresPort int
	PostgresUser string
	PostgresPass string
	PostgresDB   string
	JWTSecret    string
}

func loadConfig() *Config {
	return &Config{
		Port:         envOrDefault("IM_PORT", "8081"),
		RedisHost:    envOrDefault("REDIS_HOST", "localhost"),
		RedisPort:    envIntOrDefault("REDIS_PORT", 6379),
		RedisPass:    envOrDefault("REDIS_PASSWORD", ""),
		PostgresHost: envOrDefault("POSTGRES_HOST", "localhost"),
		PostgresPort: envIntOrDefault("POSTGRES_PORT", 5432),
		PostgresUser: envOrDefault("POSTGRES_USER", "postgres"),
		PostgresPass: envOrDefault("POSTGRES_PASSWORD", "postgres"),
		PostgresDB:   envOrDefault("POSTGRES_DB", "dating_app"),
		JWTSecret:    envOrDefault("JWT_SECRET", "change-me-in-production"),
	}
}

func main() {
	// Initialize logger.
	debug := envOrDefault("DEBUG", "false") == "true"
	logger.Init(debug)
	defer logger.Sync()

	cfg := loadConfig()
	logger.Info("starting IM server", "port", cfg.Port)

	// Initialize Redis.
	redisAddr := fmt.Sprintf("%s:%d", cfg.RedisHost, cfg.RedisPort)
	redisStore, err := store.NewRedisStore(redisAddr, cfg.RedisPass, 0)
	if err != nil {
		logger.Fatal("failed to connect to Redis", "error", err)
	}
	defer redisStore.Close()
	logger.Info("connected to Redis", "addr", redisAddr)

	// Initialize PostgreSQL.
	pgStore, err := store.NewPostgresStore(
		cfg.PostgresHost, cfg.PostgresPort,
		cfg.PostgresUser, cfg.PostgresPass, cfg.PostgresDB,
	)
	if err != nil {
		logger.Fatal("failed to connect to PostgreSQL", "error", err)
	}
	defer pgStore.Close()
	logger.Info("connected to PostgreSQL",
		"host", cfg.PostgresHost, "port", cfg.PostgresPort, "db", cfg.PostgresDB)

	// Run database migrations.
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	if err := pgStore.InitTables(ctx); err != nil {
		logger.Fatal("failed to initialize tables", "error", err)
	}
	cancel()
	logger.Info("database tables initialized")

	// Create hub and message handler.
	hub := ws.NewHub()
	go hub.Run()

	handler := ws.NewMessageHandler(hub, redisStore, pgStore)
	jwtValidator := auth.NewJWTValidator(cfg.JWTSecret)

	// WebSocket upgrader.
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin: func(r *http.Request) bool {
			// TODO: restrict origins in production
			return true
		},
	}

	// Subscribe to Redis pub/sub for cross-node message delivery.
	subCtx, subCancel := context.WithCancel(context.Background())
	defer subCancel()
	msgChan, err := redisStore.Subscribe(subCtx)
	if err != nil {
		logger.Warn("failed to subscribe to Redis pub/sub", "error", err)
	} else {
		go func() {
			for msg := range msgChan {
				hub.SendToUser(msg.To, msg)
			}
		}()
		logger.Info("subscribed to Redis pub/sub channel")
	}

	// HTTP routes.
	mux := http.NewServeMux()

	// WebSocket endpoint.
	mux.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		// Extract token from query parameter or Authorization header.
		token := r.URL.Query().Get("token")
		if token == "" {
			token = r.Header.Get("Authorization")
			if len(token) > 7 && token[:7] == "Bearer " {
				token = token[7:]
			}
		}

		if token == "" {
			http.Error(w, "missing authentication token", http.StatusUnauthorized)
			return
		}

		userID, err := jwtValidator.ValidateToken(token)
		if err != nil {
			logger.Warn("auth failed", "error", err, "remote", r.RemoteAddr)
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}

		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			logger.Error("websocket upgrade failed", "error", err)
			return
		}

		client := ws.NewClient(hub, conn, userID, handler)
		hub.Register(client)

		// Start read and write pumps.
		go client.WritePump()
		go client.ReadPump()

		// Deliver any offline messages.
		go deliverOfflineMessages(redisStore, hub, userID)
	})

	// Health check endpoint.
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `{"status":"ok","online":%d}`, hub.OnlineCount())
	})

	// Start HTTP server.
	addr := ":" + cfg.Port
	server := &http.Server{
		Addr:         addr,
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown.
	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGTERM)

	go func() {
		logger.Info("HTTP server listening", "addr", addr)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", "error", err)
		}
	}()

	// Block until a shutdown signal is received.
	sig := <-done
	logger.Info("received shutdown signal", "signal", sig)

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		logger.Error("server shutdown error", "error", err)
	}

	subCancel()
	logger.Info("IM server stopped")
}

// deliverOfflineMessages sends any stored offline messages to a user who just
// connected, then clears the offline queue.
func deliverOfflineMessages(redisStore *store.RedisStore, hub *ws.Hub, userID string) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	messages, err := redisStore.GetOfflineMessages(ctx, userID)
	if err != nil {
		logger.Error("failed to get offline messages", "error", err, "userID", userID)
		return
	}

	if len(messages) == 0 {
		return
	}

	logger.Info("delivering offline messages", "userID", userID, "count", len(messages))
	for _, msg := range messages {
		hub.SendToUser(userID, msg)
	}

	if err := redisStore.DeleteOfflineMessages(ctx, userID); err != nil {
		logger.Error("failed to delete offline messages", "error", err, "userID", userID)
	}
}

// envOrDefault returns the value of the environment variable named by key,
// or defaultVal if the variable is not set.
func envOrDefault(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

// envIntOrDefault returns the integer value of the environment variable named
// by key, or defaultVal if the variable is not set or cannot be parsed.
func envIntOrDefault(key string, defaultVal int) int {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}
	n, err := strconv.Atoi(val)
	if err != nil {
		return defaultVal
	}
	return n
}

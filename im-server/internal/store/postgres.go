package store

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"dating-app/im-server/internal/protocol"

	_ "github.com/lib/pq"
)

// PostgresStore provides PostgreSQL-backed persistent storage for chat messages.
type PostgresStore struct {
	db *sql.DB
}

// NewPostgresStore opens a connection to PostgreSQL and verifies connectivity.
func NewPostgresStore(host string, port int, user, password, dbname string) (*PostgresStore, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("open postgres: %w", err)
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("ping postgres: %w", err)
	}

	return &PostgresStore{db: db}, nil
}

// InitTables creates the messages table if it does not already exist.
func (s *PostgresStore) InitTables(ctx context.Context) error {
	query := `
	CREATE TABLE IF NOT EXISTS messages (
		id          VARCHAR(36) PRIMARY KEY,
		from_user   VARCHAR(36) NOT NULL,
		to_user     VARCHAR(36) NOT NULL,
		type        INTEGER     NOT NULL DEFAULT 1,
		content     TEXT        NOT NULL,
		timestamp   BIGINT      NOT NULL,
		status      INTEGER     NOT NULL DEFAULT 0,
		created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
	);

	CREATE INDEX IF NOT EXISTS idx_messages_from_to
		ON messages (from_user, to_user, timestamp DESC);

	CREATE INDEX IF NOT EXISTS idx_messages_to_from
		ON messages (to_user, from_user, timestamp DESC);
	`
	_, err := s.db.ExecContext(ctx, query)
	if err != nil {
		return fmt.Errorf("init tables: %w", err)
	}
	return nil
}

// SaveMessage persists a single chat message to the database.
func (s *PostgresStore) SaveMessage(ctx context.Context, msg *protocol.Message) error {
	query := `
	INSERT INTO messages (id, from_user, to_user, type, content, timestamp, status)
	VALUES ($1, $2, $3, $4, $5, $6, $7)
	ON CONFLICT (id) DO NOTHING
	`
	_, err := s.db.ExecContext(ctx, query,
		msg.ID, msg.From, msg.To, msg.Type, msg.Content, msg.Timestamp, msg.Status,
	)
	if err != nil {
		return fmt.Errorf("save message: %w", err)
	}
	return nil
}

// GetMessageHistory retrieves the conversation history between two users,
// ordered by timestamp descending, with pagination via limit and offset.
func (s *PostgresStore) GetMessageHistory(ctx context.Context, user1ID, user2ID string, limit, offset int) ([]*protocol.Message, error) {
	query := `
	SELECT id, from_user, to_user, type, content, timestamp, status
	FROM messages
	WHERE (from_user = $1 AND to_user = $2)
	   OR (from_user = $2 AND to_user = $1)
	ORDER BY timestamp DESC
	LIMIT $3 OFFSET $4
	`
	rows, err := s.db.QueryContext(ctx, query, user1ID, user2ID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("get message history: %w", err)
	}
	defer rows.Close()

	var messages []*protocol.Message
	for rows.Next() {
		var msg protocol.Message
		if err := rows.Scan(
			&msg.ID, &msg.From, &msg.To, &msg.Type,
			&msg.Content, &msg.Timestamp, &msg.Status,
		); err != nil {
			return nil, fmt.Errorf("scan message row: %w", err)
		}
		messages = append(messages, &msg)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate message rows: %w", err)
	}

	return messages, nil
}

// UpdateMessageStatus updates the delivery status of a message by ID.
func (s *PostgresStore) UpdateMessageStatus(ctx context.Context, messageID string, status int) error {
	query := `UPDATE messages SET status = $1 WHERE id = $2`
	_, err := s.db.ExecContext(ctx, query, status, messageID)
	if err != nil {
		return fmt.Errorf("update message status: %w", err)
	}
	return nil
}

// Close closes the database connection pool.
func (s *PostgresStore) Close() error {
	return s.db.Close()
}

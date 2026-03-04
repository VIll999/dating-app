package ws

import (
	"sync"

	"dating-app/im-server/internal/protocol"
	"dating-app/im-server/pkg/logger"
)

// Hub maintains the set of active clients and routes messages between them.
type Hub struct {
	// clients maps userID to the active Client connection.
	clients map[string]*Client

	// register is a channel for clients requesting to join the hub.
	register chan *Client

	// unregister is a channel for clients requesting to leave the hub.
	unregister chan *Client

	// broadcast is a channel for messages that should be delivered to a target user.
	broadcast chan *protocol.Message

	mu sync.RWMutex
}

// NewHub creates and returns a new Hub instance.
func NewHub() *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		register:   make(chan *Client, 64),
		unregister: make(chan *Client, 64),
		broadcast:  make(chan *protocol.Message, 256),
	}
}

// Run starts the hub's main event loop. It should be launched as a goroutine.
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			// If the user already has an active connection, close the old one.
			if existing, ok := h.clients[client.UserID]; ok {
				logger.Warn("replacing existing connection", "userID", client.UserID)
				close(existing.send)
				delete(h.clients, client.UserID)
			}
			h.clients[client.UserID] = client
			h.mu.Unlock()
			logger.Info("client registered", "userID", client.UserID, "online", h.OnlineCount())

		case client := <-h.unregister:
			h.mu.Lock()
			if existing, ok := h.clients[client.UserID]; ok && existing == client {
				close(client.send)
				delete(h.clients, client.UserID)
			}
			h.mu.Unlock()
			logger.Info("client unregistered", "userID", client.UserID, "online", h.OnlineCount())

		case msg := <-h.broadcast:
			h.mu.RLock()
			client, ok := h.clients[msg.To]
			h.mu.RUnlock()
			if ok {
				data, err := msg.Encode()
				if err != nil {
					logger.Error("failed to encode broadcast message", "error", err)
					continue
				}
				select {
				case client.send <- data:
				default:
					logger.Warn("client send buffer full, dropping message", "userID", msg.To)
				}
			}
		}
	}
}

// SendToUser delivers a message to a specific user if they are online.
// Returns true if the message was queued for delivery, false if the user is offline.
func (h *Hub) SendToUser(userID string, msg *protocol.Message) bool {
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()

	if !ok {
		return false
	}

	data, err := msg.Encode()
	if err != nil {
		logger.Error("failed to encode message", "error", err)
		return false
	}

	select {
	case client.send <- data:
		return true
	default:
		logger.Warn("client send buffer full", "userID", userID)
		return false
	}
}

// IsOnline checks whether a user currently has an active WebSocket connection.
func (h *Hub) IsOnline(userID string) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	_, ok := h.clients[userID]
	return ok
}

// GetOnlineUsers returns a slice of user IDs for all currently connected users.
func (h *Hub) GetOnlineUsers() []string {
	h.mu.RLock()
	defer h.mu.RUnlock()

	users := make([]string, 0, len(h.clients))
	for uid := range h.clients {
		users = append(users, uid)
	}
	return users
}

// OnlineCount returns the number of currently connected users.
func (h *Hub) OnlineCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// Register queues a client for registration with the hub.
func (h *Hub) Register(client *Client) {
	h.register <- client
}

// Unregister queues a client for removal from the hub.
func (h *Hub) Unregister(client *Client) {
	h.unregister <- client
}

// Broadcast queues a message for delivery via the hub's broadcast loop.
func (h *Hub) Broadcast(msg *protocol.Message) {
	h.broadcast <- msg
}

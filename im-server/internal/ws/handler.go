package ws

import (
	"context"
	"time"

	"dating-app/im-server/internal/protocol"
	"dating-app/im-server/internal/store"
	"dating-app/im-server/pkg/logger"

	"github.com/google/uuid"
)

// MessageHandler routes incoming WebSocket messages to the appropriate handler
// based on message type and manages delivery to online/offline users.
type MessageHandler struct {
	hub      *Hub
	redis    *store.RedisStore
	postgres *store.PostgresStore
}

// NewMessageHandler creates a new handler with references to the hub and stores.
func NewMessageHandler(hub *Hub, redis *store.RedisStore, postgres *store.PostgresStore) *MessageHandler {
	return &MessageHandler{
		hub:      hub,
		redis:    redis,
		postgres: postgres,
	}
}

// HandleMessage parses a raw WebSocket message and routes it by type.
func (h *MessageHandler) HandleMessage(client *Client, rawMessage []byte) {
	msg, err := protocol.DecodeMessage(rawMessage)
	if err != nil {
		logger.Warn("failed to decode message", "userID", client.UserID, "error", err)
		h.sendError(client, "invalid message format")
		return
	}

	// Enforce the sender identity from the authenticated connection.
	msg.From = client.UserID

	switch msg.Type {
	case protocol.MessageTypeText, protocol.MessageTypeImage:
		h.handleTextMessage(client, msg)
	case protocol.MessageTypeReadReceipt:
		h.handleReadReceipt(client, msg)
	default:
		logger.Warn("unknown message type", "type", msg.Type, "userID", client.UserID)
		h.sendError(client, "unsupported message type")
	}
}

// handleTextMessage processes a text or image message: persists it, then
// delivers it to the target user (directly if online, or via offline storage).
func (h *MessageHandler) handleTextMessage(client *Client, msg *protocol.Message) {
	// Assign a server-side ID and timestamp if not already set.
	if msg.ID == "" {
		msg.ID = uuid.New().String()
	}
	if msg.Timestamp == 0 {
		msg.Timestamp = time.Now().UnixMilli()
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Persist the message to PostgreSQL.
	if h.postgres != nil {
		if err := h.postgres.SaveMessage(ctx, msg); err != nil {
			logger.Error("failed to save message", "error", err, "msgID", msg.ID)
		}
	}

	// Attempt direct delivery to the target user.
	if h.hub.SendToUser(msg.To, msg) {
		logger.Debug("message delivered directly", "from", msg.From, "to", msg.To)
		return
	}

	// Target is offline; store the message for later delivery.
	if h.redis != nil {
		if err := h.redis.StoreOfflineMessage(ctx, msg.To, msg); err != nil {
			logger.Error("failed to store offline message", "error", err, "to", msg.To)
		} else {
			logger.Debug("message stored offline", "from", msg.From, "to", msg.To)
		}
	}
}

// handleReadReceipt processes a read receipt: updates the message status in the
// database and forwards the receipt to the original sender if they are online.
func (h *MessageHandler) handleReadReceipt(client *Client, msg *protocol.Message) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Update message status in the database.
	if h.postgres != nil {
		if err := h.postgres.UpdateMessageStatus(ctx, msg.ID, protocol.StatusRead); err != nil {
			logger.Error("failed to update read receipt", "error", err, "msgID", msg.ID)
		}
	}

	// Forward the read receipt to the original sender.
	h.hub.SendToUser(msg.To, msg)
}

// sendError sends a system error message back to the client.
func (h *MessageHandler) sendError(client *Client, errMsg string) {
	sysMsg := protocol.NewSystemMessage(client.UserID, errMsg)
	data, err := sysMsg.Encode()
	if err != nil {
		return
	}
	select {
	case client.send <- data:
	default:
	}
}

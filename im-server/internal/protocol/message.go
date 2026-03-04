package protocol

import (
	"encoding/json"
	"time"
)

// MessageType constants define the types of messages supported by the IM system.
const (
	MessageTypeText        = 1
	MessageTypeImage       = 2
	MessageTypeSystem      = 3
	MessageTypeReadReceipt = 4
)

// MessageStatus constants define the delivery status of a message.
const (
	StatusSent      = 0
	StatusDelivered = 1
	StatusRead      = 2
)

// Message represents a chat message exchanged between users.
type Message struct {
	ID        string `json:"id"`
	From      string `json:"from"`
	To        string `json:"to"`
	Type      int    `json:"type"`
	Content   string `json:"content"`
	Timestamp int64  `json:"timestamp"`
	Status    int    `json:"status"`
}

// NewTextMessage creates a new text message with a generated ID and current timestamp.
func NewTextMessage(id, from, to, content string) *Message {
	return &Message{
		ID:        id,
		From:      from,
		To:        to,
		Type:      MessageTypeText,
		Content:   content,
		Timestamp: time.Now().UnixMilli(),
		Status:    StatusSent,
	}
}

// NewSystemMessage creates a new system-level message.
func NewSystemMessage(to, content string) *Message {
	return &Message{
		ID:        "",
		From:      "system",
		To:        to,
		Type:      MessageTypeSystem,
		Content:   content,
		Timestamp: time.Now().UnixMilli(),
		Status:    StatusSent,
	}
}

// Encode serializes the message to JSON bytes.
func (m *Message) Encode() ([]byte, error) {
	return json.Marshal(m)
}

// DecodeMessage deserializes JSON bytes into a Message.
func DecodeMessage(data []byte) (*Message, error) {
	var msg Message
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, err
	}
	return &msg, nil
}

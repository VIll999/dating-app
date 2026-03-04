package ws

import (
	"time"

	"dating-app/im-server/pkg/logger"

	"github.com/gorilla/websocket"
)

const (
	// writeWait is the time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// pongWait is the time allowed to read the next pong message from the peer.
	pongWait = 60 * time.Second

	// pingPeriod sends pings to the peer at this interval. Must be less than pongWait.
	pingPeriod = (pongWait * 9) / 10

	// maxMessageSize is the maximum message size allowed from the peer (64 KB).
	maxMessageSize = 64 * 1024

	// sendBufferSize is the size of the outbound message channel.
	sendBufferSize = 256
)

// Client represents a single WebSocket connection for a specific user.
type Client struct {
	hub    *Hub
	conn   *websocket.Conn
	UserID string

	// send is a buffered channel of outbound messages.
	send chan []byte

	// handler processes inbound messages from this client.
	handler *MessageHandler
}

// NewClient creates a new Client and associates it with the given hub and handler.
func NewClient(hub *Hub, conn *websocket.Conn, userID string, handler *MessageHandler) *Client {
	return &Client{
		hub:     hub,
		conn:    conn,
		UserID:  userID,
		send:    make(chan []byte, sendBufferSize),
		handler: handler,
	}
}

// ReadPump pumps messages from the WebSocket connection to the hub.
// It runs in its own goroutine per client. The application ensures there is at
// most one reader on a connection by executing ReadPump in a single goroutine.
func (c *Client) ReadPump() {
	defer func() {
		c.hub.Unregister(c)
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	_ = c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		_ = c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway,
				websocket.CloseNormalClosure,
			) {
				logger.Warn("unexpected websocket close", "userID", c.UserID, "error", err)
			}
			break
		}
		c.handler.HandleMessage(c, message)
	}
}

// WritePump pumps messages from the send channel to the WebSocket connection.
// It runs in its own goroutine per client. The application ensures there is at
// most one writer on a connection by executing WritePump in a single goroutine.
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// The hub closed the channel.
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			_, _ = w.Write(message)

			// Drain any queued messages into the current write frame.
			n := len(c.send)
			for i := 0; i < n; i++ {
				_, _ = w.Write([]byte{'\n'})
				_, _ = w.Write(<-c.send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

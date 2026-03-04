package store

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"dating-app/im-server/internal/protocol"

	"github.com/redis/go-redis/v9"
)

const (
	offlineKeyPrefix    = "im:offline:"
	offlineMsgTTL       = 7 * 24 * time.Hour // 7 days
	pubsubChannel       = "im:messages"
)

// RedisStore provides Redis-backed storage for offline messages and
// pub/sub for cross-node message routing.
type RedisStore struct {
	client *redis.Client
}

// NewRedisStore creates a new RedisStore connected to the given address.
func NewRedisStore(addr, password string, db int) (*RedisStore, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("redis ping failed: %w", err)
	}

	return &RedisStore{client: client}, nil
}

// StoreOfflineMessage stores a message for a user who is currently offline.
// Messages are kept in a Redis list and expire after offlineMsgTTL.
func (s *RedisStore) StoreOfflineMessage(ctx context.Context, userID string, msg *protocol.Message) error {
	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("marshal message: %w", err)
	}

	key := offlineKeyPrefix + userID
	pipe := s.client.Pipeline()
	pipe.RPush(ctx, key, data)
	pipe.Expire(ctx, key, offlineMsgTTL)
	_, err = pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("store offline message: %w", err)
	}
	return nil
}

// GetOfflineMessages retrieves all pending offline messages for a user.
func (s *RedisStore) GetOfflineMessages(ctx context.Context, userID string) ([]*protocol.Message, error) {
	key := offlineKeyPrefix + userID
	data, err := s.client.LRange(ctx, key, 0, -1).Result()
	if err != nil {
		return nil, fmt.Errorf("get offline messages: %w", err)
	}

	messages := make([]*protocol.Message, 0, len(data))
	for _, raw := range data {
		var msg protocol.Message
		if err := json.Unmarshal([]byte(raw), &msg); err != nil {
			continue // skip malformed messages
		}
		messages = append(messages, &msg)
	}
	return messages, nil
}

// DeleteOfflineMessages removes all stored offline messages for a user.
func (s *RedisStore) DeleteOfflineMessages(ctx context.Context, userID string) error {
	key := offlineKeyPrefix + userID
	return s.client.Del(ctx, key).Err()
}

// Publish publishes a message to the cross-node pub/sub channel.
func (s *RedisStore) Publish(ctx context.Context, msg *protocol.Message) error {
	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("marshal message for publish: %w", err)
	}
	return s.client.Publish(ctx, pubsubChannel, data).Err()
}

// Subscribe returns a channel that receives messages from other IM server nodes.
func (s *RedisStore) Subscribe(ctx context.Context) (<-chan *protocol.Message, error) {
	sub := s.client.Subscribe(ctx, pubsubChannel)

	// Wait for subscription confirmation
	_, err := sub.Receive(ctx)
	if err != nil {
		return nil, fmt.Errorf("subscribe: %w", err)
	}

	msgChan := make(chan *protocol.Message, 256)

	go func() {
		defer close(msgChan)
		ch := sub.Channel()
		for {
			select {
			case <-ctx.Done():
				_ = sub.Close()
				return
			case redisMsg, ok := <-ch:
				if !ok {
					return
				}
				var msg protocol.Message
				if err := json.Unmarshal([]byte(redisMsg.Payload), &msg); err != nil {
					continue
				}
				select {
				case msgChan <- &msg:
				default:
					// drop message if consumer is too slow
				}
			}
		}
	}()

	return msgChan, nil
}

// Close closes the Redis client connection.
func (s *RedisStore) Close() error {
	return s.client.Close()
}

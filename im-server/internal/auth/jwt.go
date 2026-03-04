package auth

import (
	"errors"
	"fmt"

	"github.com/golang-jwt/jwt/v5"
)

var (
	ErrInvalidToken = errors.New("invalid or expired token")
	ErrNoClaims     = errors.New("unable to extract claims from token")
	ErrNoUserID     = errors.New("token does not contain a user ID")
)

// JWTValidator provides JWT token validation using a shared secret with the
// NestJS backend. Both services must use the same JWT_SECRET.
type JWTValidator struct {
	secret []byte
}

// NewJWTValidator creates a new validator with the given secret.
func NewJWTValidator(secret string) *JWTValidator {
	return &JWTValidator{
		secret: []byte(secret),
	}
}

// ValidateToken parses and validates a JWT token string.
// Returns the userID embedded in the token claims, or an error.
func (v *JWTValidator) ValidateToken(tokenString string) (string, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Ensure the signing method is HMAC (same as NestJS default)
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return v.secret, nil
	})
	if err != nil {
		return "", fmt.Errorf("%w: %v", ErrInvalidToken, err)
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return "", ErrNoClaims
	}

	// NestJS typically stores the user identifier in the "sub" claim.
	sub, ok := claims["sub"]
	if !ok {
		return "", ErrNoUserID
	}

	userID, ok := sub.(string)
	if !ok {
		// sub might be stored as a number; handle that case.
		if numID, ok := sub.(float64); ok {
			userID = fmt.Sprintf("%.0f", numID)
		} else {
			return "", ErrNoUserID
		}
	}

	return userID, nil
}

# API Documentation

## Base URL
- Development: `http://localhost/api`
- WebSocket: `ws://localhost/ws`

## Authentication

All protected endpoints require `Authorization: Bearer <token>` header.

### POST /api/auth/register
Register a new user.

**Body:**
```json
{
  "phone": "13800138000",
  "password": "securePassword123"
}
```

**Response:** `201`
```json
{
  "code": 0,
  "data": { "accessToken": "eyJhbG..." },
  "message": "success"
}
```

### POST /api/auth/login
Login with phone and password.

**Body:**
```json
{
  "phone": "13800138000",
  "password": "securePassword123"
}
```

**Response:** `200`
```json
{
  "code": 0,
  "data": { "accessToken": "eyJhbG..." },
  "message": "success"
}
```

---

## Users

### GET /api/users/me
Get current user info. **Protected.**

### GET /api/users/:id
Get user by ID. **Protected.**

---

## Profiles

### GET /api/profiles/me
Get current user's profile. **Protected.**

### PUT /api/profiles/me
Update current user's profile. **Protected.**

**Body:**
```json
{
  "bio": "Love hiking and coffee",
  "gender": "female",
  "birthday": "1995-06-15",
  "latitude": 31.2304,
  "longitude": 121.4737,
  "interests": ["travel", "photography", "coffee"]
}
```

---

## Matching

### GET /api/matching/cards?limit=10
Get recommended user cards. **Protected.**

### POST /api/matching/swipe
Record a swipe action. **Protected.**

**Body:**
```json
{
  "targetUserId": "uuid-here",
  "direction": "RIGHT"
}
```

### GET /api/matching/matches
Get all matches. **Protected.**

---

## Upload

### POST /api/upload
Upload a photo. **Protected.** Multipart form data.

**Form Field:** `file` (image/jpeg, image/png, max 5MB)

**Response:** `201`
```json
{
  "code": 0,
  "data": { "url": "http://localhost/uploads/photo-uuid.jpg" },
  "message": "success"
}
```

---

## WebSocket IM Protocol

### Connection
```
ws://localhost/ws/?token=<jwt-token>
```

### Message Format
```json
{
  "id": "msg-uuid",
  "from": "user-uuid",
  "to": "target-user-uuid",
  "type": 1,
  "content": "Hello!",
  "timestamp": 1708300000000,
  "status": 0
}
```

### Message Types
| Type | Value | Description |
|------|-------|-------------|
| TEXT | 1 | Text message |
| IMAGE | 2 | Image URL |
| SYSTEM | 3 | System notification |
| READ_RECEIPT | 4 | Read receipt |

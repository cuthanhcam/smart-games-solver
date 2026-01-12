# Smart Games Solver - API Documentation

## Friend Management API

### Base URL
```
/api/friends
```

### Endpoints

#### 1. Search Users
```
GET /search?query={query}&skip={skip}&limit={limit}
```
**Description**: Search for users by username or email

**Authentication**: Required (Bearer token)

**Query Parameters**:
- `query` (string, required): Search term (username or email)
- `skip` (int, optional): Number of results to skip (default: 0)
- `limit` (int, optional): Maximum results to return (default: 10)

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "is_admin": false,
    "created_at": "2024-01-11T10:00:00"
  }
]
```

---

#### 2. Get Friends List
```
GET /list
```
**Description**: Get all accepted friends of the current user

**Authentication**: Required (Bearer token)

**Response** (200 OK):
```json
[
  {
    "id": 2,
    "username": "jane_doe",
    "email": "jane@example.com",
    "friend_id": 2,
    "created_at": "2024-01-10T10:00:00"
  }
]
```

---

#### 3. Get Incoming Friend Requests
```
GET /requests/incoming
```
**Description**: Get all pending friend requests received by current user

**Authentication**: Required (Bearer token)

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "sender_id": 3,
    "username": "alice_smith",
    "email": "alice@example.com",
    "created_at": "2024-01-11T09:30:00"
  }
]
```

---

#### 4. Get Outgoing Friend Requests
```
GET /requests/outgoing
```
**Description**: Get all pending friend requests sent by current user

**Authentication**: Required (Bearer token)

**Response** (200 OK):
```json
[
  {
    "id": 2,
    "receiver_id": 4,
    "username": "bob_jones",
    "email": "bob@example.com",
    "created_at": "2024-01-11T08:00:00"
  }
]
```

---

#### 5. Send Friend Request
```
POST /request
Content-Type: application/json
```
**Description**: Send a friend request to another user

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "receiver_id": 5
}
```

**Response** (201 Created):
```json
{
  "message": "Friend request sent successfully",
  "friendship_id": 3
}
```

**Error Response** (400 Bad Request):
```json
{
  "detail": "Already friends with this user"
}
```

---

#### 6. Accept Friend Request
```
POST /request/accept
Content-Type: application/json
```
**Description**: Accept a pending friend request

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "friendship_id": 1
}
```

**Response** (200 OK):
```json
{
  "message": "Friend request accepted"
}
```

---

#### 7. Reject Friend Request
```
POST /request/reject
Content-Type: application/json
```
**Description**: Reject a pending friend request

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "friendship_id": 1
}
```

**Response** (200 OK):
```json
{
  "message": "Friend request rejected"
}
```

---

#### 8. Remove Friend
```
DELETE /remove/{friend_id}
```
**Description**: Remove a friend from your friend list

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `friend_id` (int): ID of friend to remove

**Response** (200 OK):
```json
{
  "message": "Friend removed successfully"
}
```

---

#### 9. Get Friendship Status
```
GET /status/{user_id}
```
**Description**: Get friendship status between current user and another user

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `user_id` (int): ID of the other user

**Response Status Values**:
- `friends`: Users are friends
- `pending_sent`: Current user sent pending request
- `pending_received`: Other user sent pending request
- `rejected`: Request was rejected
- `none`: No friendship

**Response** (200 OK):
```json
{
  "status": "pending_received",
  "friendship_id": 1
}
```

---

## Message API

### Base URL
```
/api/messages
```

### Endpoints

#### 1. Send Message
```
POST /send
Content-Type: application/json
```
**Description**: Send a message to another user

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "receiver_id": 2,
  "content": "Hello, how are you?"
}
```

**Response** (201 Created):
```json
{
  "id": 1,
  "sender_id": 1,
  "receiver_id": 2,
  "content": "Hello, how are you?",
  "is_read": false,
  "created_at": "2024-01-11T10:30:00"
}
```

---

#### 2. Get Messages with User
```
GET /with/{user_id}?skip={skip}&limit={limit}
```
**Description**: Get all messages between current user and another user

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `user_id` (int): ID of the other user

**Query Parameters**:
- `skip` (int, optional): Number of messages to skip (default: 0)
- `limit` (int, optional): Maximum messages to return (default: 50)

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "sender_id": 1,
    "receiver_id": 2,
    "content": "Hello!",
    "is_read": true,
    "created_at": "2024-01-11T10:00:00"
  },
  {
    "id": 2,
    "sender_id": 2,
    "receiver_id": 1,
    "content": "Hi there!",
    "is_read": true,
    "created_at": "2024-01-11T10:05:00"
  }
]
```

---

#### 3. Get Chat List
```
GET /list
```
**Description**: Get list of all chats with friends (shows last message and unread count)

**Authentication**: Required (Bearer token)

**Response** (200 OK):
```json
[
  {
    "user_id": 2,
    "username": "jane_doe",
    "email": "jane@example.com",
    "last_message": "See you later!",
    "last_message_time": "2024-01-11T15:30:00",
    "is_read": true,
    "is_sent_by_me": true,
    "unread_count": 0
  },
  {
    "user_id": 3,
    "username": "alice_smith",
    "email": "alice@example.com",
    "last_message": "That sounds great!",
    "last_message_time": "2024-01-11T14:00:00",
    "is_read": false,
    "is_sent_by_me": false,
    "unread_count": 2
  }
]
```

---

#### 4. Mark Message as Read
```
POST /mark-read
Content-Type: application/json
```
**Description**: Mark a single message as read

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "message_id": 1
}
```

**Response** (200 OK):
```json
{
  "message": "Message marked as read"
}
```

---

#### 5. Mark All Messages Read
```
POST /mark-all-read/{user_id}
```
**Description**: Mark all messages from a specific user as read

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `user_id` (int): ID of the user whose messages to mark as read

**Response** (200 OK):
```json
{
  "message": "Marked 5 messages as read"
}
```

---

#### 6. Get Unread Count
```
GET /unread-count
```
**Description**: Get total unread message count for current user

**Authentication**: Required (Bearer token)

**Response** (200 OK):
```json
{
  "unread_count": 3
}
```

---

#### 7. Delete Message
```
DELETE /delete/{message_id}
```
**Description**: Delete own message

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `message_id` (int): ID of message to delete

**Response** (200 OK):
```json
{
  "message": "Message deleted successfully"
}
```

---

## Announcement API

### Base URL
```
/api/announcements
```

### Endpoints

#### 1. Create Announcement
```
POST /create
Content-Type: application/json
```
**Description**: Create a new announcement (admin only)

**Authentication**: Required (Bearer token with admin role)

**Request Body**:
```json
{
  "title": "New Feature Released",
  "content": "We're excited to announce a new feature!",
  "type": "success"
}
```

**Type Values**: `info`, `warning`, `success`, `error`

**Response** (201 Created):
```json
{
  "id": 1,
  "admin_id": 1,
  "title": "New Feature Released",
  "content": "We're excited to announce a new feature!",
  "type": "success",
  "is_active": true,
  "created_at": "2024-01-11T10:00:00",
  "updated_at": "2024-01-11T10:00:00"
}
```

---

#### 2. Get Announcements List
```
GET /list?skip={skip}&limit={limit}&active_only={active_only}
```
**Description**: Get all announcements (users see only active ones)

**Authentication**: Required (Bearer token)

**Query Parameters**:
- `skip` (int, optional): Number of announcements to skip (default: 0)
- `limit` (int, optional): Maximum announcements to return (default: 20)
- `active_only` (bool, optional): Filter only active announcements (default: true)

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "admin_id": 1,
    "title": "System Maintenance",
    "content": "The platform will be down for maintenance...",
    "type": "warning",
    "is_active": true,
    "created_at": "2024-01-11T10:00:00",
    "updated_at": "2024-01-11T10:00:00"
  }
]
```

---

#### 3. Get Single Announcement
```
GET /{announcement_id}
```
**Description**: Get a specific announcement by ID

**Authentication**: Required (Bearer token)

**Path Parameters**:
- `announcement_id` (int): ID of announcement

**Response** (200 OK):
```json
{
  "id": 1,
  "admin_id": 1,
  "title": "System Maintenance",
  "content": "The platform will be down for maintenance...",
  "type": "warning",
  "is_active": true,
  "created_at": "2024-01-11T10:00:00",
  "updated_at": "2024-01-11T10:00:00"
}
```

---

#### 4. Update Announcement
```
PATCH /{announcement_id}
Content-Type: application/json
```
**Description**: Update an announcement (admin only)

**Authentication**: Required (Bearer token with admin role)

**Path Parameters**:
- `announcement_id` (int): ID of announcement to update

**Request Body** (all fields optional):
```json
{
  "title": "Updated Title",
  "content": "Updated content",
  "type": "info",
  "is_active": false
}
```

**Response** (200 OK):
```json
{
  "id": 1,
  "admin_id": 1,
  "title": "Updated Title",
  "content": "Updated content",
  "type": "info",
  "is_active": false,
  "created_at": "2024-01-11T10:00:00",
  "updated_at": "2024-01-11T11:00:00"
}
```

---

#### 5. Delete Announcement
```
DELETE /{announcement_id}
```
**Description**: Delete an announcement (admin only)

**Authentication**: Required (Bearer token with admin role)

**Path Parameters**:
- `announcement_id` (int): ID of announcement to delete

**Response** (200 OK):
```json
{
  "message": "Announcement deleted successfully"
}
```

---

#### 6. Activate Announcement
```
POST /{announcement_id}/activate
```
**Description**: Activate an announcement (admin only)

**Authentication**: Required (Bearer token with admin role)

**Path Parameters**:
- `announcement_id` (int): ID of announcement

**Response** (200 OK):
```json
{
  "id": 1,
  "admin_id": 1,
  "title": "New Feature",
  "content": "...",
  "type": "success",
  "is_active": true,
  "created_at": "2024-01-11T10:00:00",
  "updated_at": "2024-01-11T11:00:00"
}
```

---

#### 7. Deactivate Announcement
```
POST /{announcement_id}/deactivate
```
**Description**: Deactivate an announcement (admin only)

**Authentication**: Required (Bearer token with admin role)

**Path Parameters**:
- `announcement_id` (int): ID of announcement

**Response** (200 OK):
```json
{
  "id": 1,
  "admin_id": 1,
  "title": "New Feature",
  "content": "...",
  "type": "success",
  "is_active": false,
  "created_at": "2024-01-11T10:00:00",
  "updated_at": "2024-01-11T11:00:00"
}
```

---

## Error Responses

### Standard Error Format
```json
{
  "detail": "Error message describing what went wrong"
}
```

### Common HTTP Status Codes

| Status | Meaning |
|--------|---------|
| 200 | OK - Request successful |
| 201 | Created - Resource created successfully |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Missing or invalid token |
| 403 | Forbidden - Not permitted (e.g., not admin) |
| 404 | Not Found - Resource doesn't exist |
| 422 | Unprocessable Entity - Validation error |
| 500 | Server Error - Internal server error |

---

## Authentication

All endpoints (except public-facing ones) require JWT token in header:

```
Authorization: Bearer {token}
```

Tokens are obtained from login endpoint:
```
POST /api/auth/login
```

---

## Rate Limiting
Currently no rate limiting is implemented. Recommended for production:
- 100 requests per minute for authenticated users
- 10 requests per minute for unauthenticated users

---

## Pagination
Endpoints supporting pagination use:
- `skip`: Number of items to skip (0-indexed)
- `limit`: Maximum number of items to return

Example:
```
GET /api/friends/search?query=john&skip=0&limit=10
```

---

## Data Validation

### Friend Request
- `receiver_id`: Required, positive integer

### Message
- `receiver_id`: Required, positive integer
- `content`: Required, 1-1000 characters

### Announcement
- `title`: Required, 1-200 characters
- `content`: Required, minimum 1 character
- `type`: Required, one of: `info`, `warning`, `success`, `error`

---

**Last Updated**: January 11, 2024

# Mobile API Integration Guide

## Quick Reference for Mobile Developers

### ApiClient Usage

The `ApiClient` class provides all necessary methods for API communication. It handles:
- Token management (save/load/clear)
- Request headers with authentication
- Error handling
- Network timeouts

### Friend Management

#### Search for Users
```dart
final response = await apiClient.searchUsers('john', limit: 10);
if (response.statusCode == 200) {
  List users = jsonDecode(response.body);
}
```

#### Get Friends List
```dart
final response = await apiClient.getFriendsList();
if (response.statusCode == 200) {
  List friends = jsonDecode(response.body);
}
```

#### Get Friend Requests
```dart
// Incoming requests
final incomingResponse = await apiClient.getIncomingFriendRequests();

// Outgoing requests
final outgoingResponse = await apiClient.getOutgoingFriendRequests();
```

#### Send Friend Request
```dart
final response = await apiClient.sendFriendRequest(userId);
if (response.statusCode == 201) {
  // Request sent successfully
  var data = jsonDecode(response.body);
  int friendshipId = data['friendship_id'];
}
```

#### Accept/Reject Friend Request
```dart
// Accept
final response = await apiClient.acceptFriendRequest(friendshipId);

// Reject
final response = await apiClient.rejectFriendRequest(friendshipId);
```

#### Remove Friend
```dart
final response = await apiClient.removeFriend(friendId);
if (response.statusCode == 200) {
  // Friend removed
}
```

#### Check Friendship Status
```dart
final response = await apiClient.getFriendshipStatus(userId);
if (response.statusCode == 200) {
  var data = jsonDecode(response.body);
  String status = data['status']; // 'friends', 'pending_sent', 'pending_received', 'rejected', 'none'
}
```

---

### Message Management

#### Send Message
```dart
final response = await apiClient.sendMessage(receiverId, 'Hello!');
if (response.statusCode == 201) {
  Map message = jsonDecode(response.body);
  int messageId = message['id'];
}
```

#### Get Messages with User
```dart
final response = await apiClient.getMessagesWithUser(userId, skip: 0, limit: 50);
if (response.statusCode == 200) {
  List messages = jsonDecode(response.body);
}
```

#### Get Chat List
```dart
final response = await apiClient.getChatList();
if (response.statusCode == 200) {
  List chats = jsonDecode(response.body);
  // Each chat contains:
  // - user_id, username, email
  // - last_message, last_message_time
  // - is_read, is_sent_by_me
  // - unread_count
}
```

#### Mark Messages as Read
```dart
// Mark single message
final response = await apiClient.markMessageAsRead(messageId);

// Mark all from user
final response = await apiClient.markAllMessagesRead(userId);
```

#### Get Unread Count
```dart
final response = await apiClient.getUnreadMessageCount();
if (response.statusCode == 200) {
  Map data = jsonDecode(response.body);
  int unreadCount = data['unread_count'];
}
```

#### Delete Message
```dart
final response = await apiClient.deleteMessage(messageId);
if (response.statusCode == 200) {
  // Message deleted
}
```

---

### Announcement Management

#### Get Announcements
```dart
final response = await apiClient.getAnnouncements(skip: 0, limit: 20);
if (response.statusCode == 200) {
  List announcements = jsonDecode(response.body);
}
```

#### Get Single Announcement
```dart
final response = await apiClient.getAnnouncement(announcementId);
if (response.statusCode == 200) {
  Map announcement = jsonDecode(response.body);
}
```

---

## Repository Pattern Usage

### FriendRequestRepository
```dart
final friendRepo = FriendRequestRepository();

// Search users
final user = await friendRepo.findUserByUsernameOrEmail('john');

// Send request
bool success = await friendRepo.sendFriendRequest(senderId, receiverId);

// Get requests
List requests = await friendRepo.getReceivedFriendRequests(userId);

// Accept/Reject
await friendRepo.acceptFriendRequest(requestId);
await friendRepo.rejectFriendRequest(requestId);

// Get friends list
List friends = await friendRepo.getFriends(userId);

// Check status
bool areFriends = await friendRepo.areFriends(userId1, userId2);
String? status = await friendRepo.getFriendRequestStatus(userId1, userId2);
```

### MessageRepository
```dart
final messageRepo = MessageRepository();

// Send message
int messageId = await messageRepo.sendMessage(senderId, receiverId, 'Hello');

// Get messages
List messages = await messageRepo.getMessages(userId1, userId2);

// Chat list
List chats = await messageRepo.getChatList(userId);

// Mark as read
await messageRepo.markMessageAsRead(messageId);
await messageRepo.markAllMessagesRead(userId);

// Delete
bool success = await messageRepo.deleteMessage(messageId);

// Unread count
int count = await messageRepo.getUnreadMessageCount(userId);
```

### AnnouncementRepository
```dart
final announceRepo = AnnouncementRepository();

// Get all announcements
List announcements = await announceRepo.getAllAnnouncements(skip: 0, limit: 20);

// Get active only
List active = await announceRepo.getActiveAnnouncements();

// Get specific announcement
Map? announcement = await announceRepo.getAnnouncement(announcementId);
```

---

## Error Handling

### Standard Response Pattern
```dart
try {
  final response = await apiClient.someMethod();
  
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    // Handle success
  } else if (response.statusCode == 404) {
    // Handle not found
  } else {
    // Handle other errors
    var error = jsonDecode(response.body);
    String detail = error['detail'];
  }
} on Exception catch (e) {
  // Handle network/connection errors
  print('Error: $e');
}
```

### Common Status Codes
| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized (invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 422 | Validation Error |

---

## Token Management

### Save Token (after login)
```dart
await apiClient.saveToken(token);
```

### Get Token
```dart
String? token = await apiClient.getToken();
```

### Clear Token (on logout)
```dart
await apiClient.clearToken();
```

---

## UI Integration Examples

### Friend Search Screen
```dart
List<dynamic> users = [];

Future<void> searchUsers(String query) async {
  try {
    final response = await apiClient.searchUsers(query);
    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
      });
    }
  } catch (e) {
    // Show error dialog
  }
}

// Build UI with users list
ListView.builder(
  itemCount: users.length,
  itemBuilder: (context, index) {
    var user = users[index];
    return ListTile(
      title: Text(user['username']),
      subtitle: Text(user['email']),
      onTap: () {
        // Send friend request
        friendRepo.sendFriendRequest(currentUserId, user['id']);
      },
    );
  },
)
```

### Chat List Screen
```dart
List<dynamic> chats = [];

Future<void> loadChats() async {
  try {
    final response = await apiClient.getChatList();
    if (response.statusCode == 200) {
      setState(() {
        chats = jsonDecode(response.body);
      });
    }
  } catch (e) {
    // Handle error
  }
}

// Build UI showing unread count
ListView.builder(
  itemCount: chats.length,
  itemBuilder: (context, index) {
    var chat = chats[index];
    return ListTile(
      title: Text(chat['username']),
      subtitle: Text(chat['last_message'] ?? 'No messages'),
      trailing: chat['unread_count'] > 0
        ? Badge(
            label: Text(chat['unread_count'].toString()),
            child: Icon(Icons.chat),
          )
        : null,
      onTap: () {
        // Navigate to chat detail
      },
    );
  },
)
```

### Announcement Display
```dart
List<dynamic> announcements = [];

Future<void> loadAnnouncements() async {
  try {
    final response = await apiClient.getAnnouncements();
    if (response.statusCode == 200) {
      setState(() {
        announcements = jsonDecode(response.body);
      });
    }
  } catch (e) {
    // Handle error
  }
}

// Build UI with color coding by type
ListView.builder(
  itemCount: announcements.length,
  itemBuilder: (context, index) {
    var ann = announcements[index];
    Color bgColor = _getColorForType(ann['type']);
    return Card(
      color: bgColor,
      child: ListTile(
        title: Text(ann['title']),
        subtitle: Text(ann['content']),
      ),
    );
  },
)

Color _getColorForType(String type) {
  switch (type) {
    case 'success': return Colors.green.shade100;
    case 'warning': return Colors.orange.shade100;
    case 'error': return Colors.red.shade100;
    default: return Colors.blue.shade100;
  }
}
```

---

## Best Practices

1. **Always wrap API calls in try-catch**
   ```dart
   try {
     final response = await apiClient.method();
   } catch (e) {
     // Handle error
   }
   ```

2. **Check status codes**
   ```dart
   if (response.statusCode == 200) {
     // Success
   } else {
     // Handle error based on status code
   }
   ```

3. **Use repositories for business logic**
   - Don't call apiClient directly from UI
   - Use repositories as intermediary layer

4. **Handle offline scenarios**
   - Check for network connectivity
   - Show appropriate error messages

5. **Cache data when appropriate**
   - Store friends list locally
   - Update on app startup

6. **Show loading indicators**
   - Show while fetching data
   - Disable buttons during requests

7. **Validate user input**
   - Check message length
   - Validate email/username format

---

## Debugging

### Enable Request Logging
```dart
// In ApiClient, add logging:
print('Request: ${response.request?.url}');
print('Status: ${response.statusCode}');
print('Response: ${response.body}');
```

### Test API Endpoints
Use Postman or similar tool to test endpoints:
1. Set Authorization header with Bearer token
2. Use JSON format for request body
3. Verify response structure matches expected format

### Common Issues

**Issue**: "Unauthorized" (401)
- **Solution**: Token may have expired, re-login user

**Issue**: "Not Found" (404)
- **Solution**: Check if resource exists, verify ID

**Issue**: "Network Error"
- **Solution**: Check internet connection, verify API URL

---

**Last Updated**: January 11, 2024

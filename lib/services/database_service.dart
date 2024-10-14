import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getUserChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> createUser(AppUser user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user');
    }
  }

  Future<List<AppUser>> searchUsers(String query) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => AppUser.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  Future<String> createChat(String userId1, String userId2) async {
    try {
      DocumentReference chatRef = await _db.collection('chats').add({
        'participants': [userId1, userId2],
        'lastMessage': null,
        'lastMessageTime': null,
        'typingUsers': [],
      });
      return chatRef.id;
    } catch (e) {
      print('Error creating chat: $e');
      throw Exception('Failed to create chat');
    }
  }

  Future<void> sendMessage(String chatId, String senderId, String content, {MessageType type = MessageType.text}) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      await _db.collection('chats').doc(chatId).collection('messages').add({
        'senderId': senderId,
        'content': content,
        'timestamp': timestamp,
        'type': type.toString().split('.').last,
        'isRead': false,
      });

      await _db.collection('chats').doc(chatId).update({
        'lastMessage': type == MessageType.text ? content : '${type.toString().split('.').last} message',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
        'unreadCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      QuerySnapshot unreadMessages = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      WriteBatch batch = _db.batch();
      unreadMessages.docs.forEach((doc) {
        batch.update(doc.reference, {'isRead': true});
      });
      await batch.commit();

      await _db.collection('chats').doc(chatId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> updateUserProfile(String userId, String name, String email) async {
    try {
      await _db.collection('users').doc(userId).update({
        'name': name,
        'email': email,
      });
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  Future<void> updateUserProfilePicture(String userId, String pictureUrl) async {
    try {
      await _db.collection('users').doc(userId).update({
        'profilePictureUrl': pictureUrl,
      });
    } catch (e) {
      print('Error updating profile picture: $e');
      throw Exception('Failed to update profile picture');
    }
  }

  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      await _db.collection('chats').doc(chatId).update({
        'typingUsers': isTyping
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print('Error setting typing status: $e');
    }
  }

  Stream<List<String>> getTypingUsers(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data() as Map<String, dynamic>;
      return List<String>.from(data['typingUsers'] ?? []);
    });
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).delete();
    } catch (e) {
      print('Error deleting message: $e');
      throw Exception('Failed to delete message');
    }
  }
}
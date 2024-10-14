import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/user_avatar.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final AppUser currentUser;
  final AppUser otherUser;

  const ChatRoomPage({
    Key? key,
    required this.chatId,
    required this.currentUser,
    required this.otherUser,
  }) : super(key: key);

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    _databaseService.markMessagesAsRead(widget.chatId, widget.currentUser.id).catchError((error) {
      print('Error marking messages as read: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update message status')),
      );
    });
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<List<String>>(
      stream: _databaseService.getTypingUsers(widget.chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox.shrink();
        final typingUsers = snapshot.data!;
        if (typingUsers.contains(widget.otherUser.id)) {
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('${widget.otherUser.name} is typing...'),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(
              name: widget.otherUser.name,
              imageUrl: widget.otherUser.profilePictureUrl,
              size: 40,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.name, style: TextStyle(fontSize: 16)),
                  Text('Online', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet'));
                }
                List<Message> messages = snapshot.data!.docs
                    .map((doc) => Message.fromDocument(doc))
                    .toList();
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    Message message = messages[index];
                    bool isCurrentUser = message.senderId == widget.currentUser.id;
                    return ChatBubble(
                      message: message.content,
                      isCurrentUser: isCurrentUser,
                      messageType: message.type,
                      timestamp: message.timestamp,
                      isRead: message.isRead,
                      onDelete: isCurrentUser ? () => _deleteMessage(message.id) : null,
                    );
                  },
                );
              },
            ),
          ),
          _buildTypingIndicator(),
          MessageInput(
            onSendMessage: (String message, MessageType type) {
              _databaseService.sendMessage(
                widget.chatId,
                widget.currentUser.id,
                message,
                type: type,
              );
            },
            onTypingStatusChanged: (bool isTyping) {
              _databaseService.setTypingStatus(
                widget.chatId,
                widget.currentUser.id,
                isTyping,
              );
            },
            chatId: widget.chatId,
            currentUser: widget.currentUser,
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) async {
    try {
      await _databaseService.deleteMessage(widget.chatId, messageId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message')),
      );
    }
  }
}
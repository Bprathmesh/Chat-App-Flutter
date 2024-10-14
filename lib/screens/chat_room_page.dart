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

  const ChatRoomPage({super.key, 
    required this.chatId,
    required this.currentUser,
    required this.otherUser,
  });

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
      // Optionally show a snackbar or some other UI indication that there was an error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update message status')),
      );
    });
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
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.name, style: const TextStyle(fontSize: 16)),
                  const Text('Online', style: TextStyle(fontSize: 12)),
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
                  return const Center(child: Text('Something went wrong'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
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
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            onSendMessage: (String message, MessageType type) {
              _databaseService.sendMessage(
                widget.chatId,
                widget.currentUser.id,
                message,
                type: type,
              );
            },
            chatId: widget.chatId,
          ),
        ],
      ),
    );
  }
}
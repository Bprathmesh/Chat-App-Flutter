import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/user_avatar.dart';

class ChatRoomPage extends StatelessWidget {
  final String chatId;
  final AppUser currentUser;
  final AppUser otherUser;

  const ChatRoomPage({super.key, 
    required this.chatId,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(
              name: otherUser.name,
              imageUrl: otherUser.profilePictureUrl,
              size: 40,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherUser.name, style: const TextStyle(fontSize: 16)),
                  const Text('Online', style: TextStyle(fontSize: 12)),  // You can make this dynamic
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Implement chat options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseService().getChatMessages(chatId),
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
                    bool isCurrentUser = message.senderId == currentUser.id;
                    return ChatBubble(
                      message: message.content,
                      isCurrentUser: isCurrentUser,
                      messageType: message.type,
                      timestamp: message.timestamp,
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            onSendMessage: (String message, MessageType type) {
              DatabaseService().sendMessage(
                chatId,
                currentUser.id,
                message,
                type: type,
              );
            },
             chatId: chatId,
          ),
        ],
      ),
    );
  }
}
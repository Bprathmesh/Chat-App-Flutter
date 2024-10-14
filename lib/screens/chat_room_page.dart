import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/user_avatar.dart';  // Add this import

class ChatRoomPage extends StatelessWidget {
  final String chatId;
  final AppUser currentUser;
  final AppUser otherUser;

  ChatRoomPage({
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
            UserAvatar(  // Add UserAvatar here
              name: otherUser.name,
              imageUrl: otherUser.profilePictureUrl,
              size: 40,
            ),
            SizedBox(width: 8),
            Text(otherUser.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseService().getChatMessages(chatId),
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

                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    bool isCurrentUser = data['senderId'] == currentUser.id;
                    return ChatBubble(
                      message: data['message'],
                      isCurrentUser: isCurrentUser,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          MessageInput(
            onSendMessage: (message) {
              DatabaseService().sendMessage(chatId, currentUser.id, message);
            },
          ),
        ],
      ),
    );
  }
}
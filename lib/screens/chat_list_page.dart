import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'chat_room_page.dart';
import 'user_search_page.dart';
import '../widgets/user_avatar.dart';  // Add this import

class ChatListPage extends StatelessWidget {
  final AppUser currentUser;

  const ChatListPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserSearchPage(currentUser: currentUser),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getUserChats(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String chatId = doc.id;
              String otherUserId = data['participants'].firstWhere((id) => id != currentUser.id);

              return FutureBuilder<AppUser?>(
                future: DatabaseService().getUser(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  AppUser? otherUser = userSnapshot.data;

                  return ListTile(
                    leading: UserAvatar(  // Use UserAvatar here
                      name: otherUser?.name ?? 'Unknown',
                      imageUrl: otherUser?.profilePictureUrl,
                    ),
                    title: Text(otherUser?.name ?? 'Unknown User'),
                    subtitle: Text(data['lastMessage'] ?? 'No messages yet'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomPage(
                            chatId: chatId,
                            currentUser: currentUser,
                            otherUser: otherUser!,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
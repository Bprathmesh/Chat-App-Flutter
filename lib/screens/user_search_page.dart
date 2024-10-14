// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar.dart';  // Import the UserAvatar widget
import 'chat_room_page.dart';

class UserSearchPage extends StatefulWidget {
  final AppUser currentUser;

  const UserSearchPage({super.key, required this.currentUser});

  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<AppUser> _searchResults = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<AppUser> results = await _databaseService.searchUsers(query);
      setState(() {
        _searchResults = results.where((user) => user.id != widget.currentUser.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while searching. Please try again.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startChat(AppUser otherUser) async {
    try {
      String chatId = await _databaseService.createChat(widget.currentUser.id, otherUser.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            chatId: chatId,
            currentUser: widget.currentUser,
            otherUser: otherUser,
          ),
        ),
      );
    } catch (e) {
      print('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start chat. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _performSearch,
              decoration: InputDecoration(
                labelText: 'Search users',
                hintText: 'Enter a name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          AppUser user = _searchResults[index];
                          return ListTile(
                            leading: UserAvatar(
                              name: user.name,
                              imageUrl: user.profilePictureUrl,
                              size: 50,
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            onTap: () => _startChat(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
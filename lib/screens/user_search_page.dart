import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'chat_room_page.dart';

class UserSearchPage extends StatefulWidget {
  final AppUser currentUser;

  UserSearchPage({required this.currentUser});

  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<AppUser> _searchResults = [];

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    List<AppUser> results = await _databaseService.searchUsers(query);
    setState(() {
      _searchResults = results.where((user) => user.id != widget.currentUser.id).toList();
    });
  }

  void _startChat(AppUser otherUser) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _performSearch,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                AppUser user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profilePictureUrl != null
                        ? NetworkImage(user.profilePictureUrl!)
                        : null,
                    child: user.profilePictureUrl == null ? Text(user.name[0]) : null,
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
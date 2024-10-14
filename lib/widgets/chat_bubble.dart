import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final MessageType messageType;
  final DateTime? timestamp;  // Make this nullable
  final bool isRead;

  ChatBubble({
    required this.message,
    required this.isCurrentUser,
    required this.messageType,
    this.timestamp,  // Make this optional
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildMessageContent(),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timestamp != null)  // Only show timestamp if it's not null
                  Text(
                    DateFormat('HH:mm').format(timestamp!),
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                SizedBox(width: 4),
                if (isCurrentUser)
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? Colors.blue[100] : Colors.white70,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMessageContent() {
    switch (messageType) {
      case MessageType.text:
        return Text(
          message,
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black,
          ),
        );
      case MessageType.image:
        return Image.network(
          message,
          height: 200,
          width: 200,
          fit: BoxFit.cover,
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file, color: isCurrentUser ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              'File attachment',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
          ],
        );
    }
  }
}
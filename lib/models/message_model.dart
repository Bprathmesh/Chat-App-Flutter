import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file, voice }

class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime? timestamp;
  final MessageType type;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    this.timestamp,
    required this.type,
    required this.isRead,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : null,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'type': type.toString().split('.').last,
      'isRead': isRead,
    };
  }
}
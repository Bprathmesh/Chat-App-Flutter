import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/message_model.dart';
import '../models/user_model.dart';

class MessageInput extends StatefulWidget {
  final Function(String, MessageType) onSendMessage;
  final Function(bool) onTypingStatusChanged;
  final String chatId;
  final AppUser currentUser;

  MessageInput({
    required this.onSendMessage,
    required this.onTypingStatusChanged,
    required this.chatId,
    required this.currentUser,
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onTypingStatusChanged(_controller.text.isNotEmpty);
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      widget.onSendMessage(_controller.text, MessageType.text);
      _controller.clear();
    }
  }

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        String imageUrl = await _uploadFile(image.path, 'chat_images');
        widget.onSendMessage(imageUrl, MessageType.image);
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image. Please try again.')),
        );
      }
    }
  }

 Future<void> _startRecording() async {
  try {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordingPath = path;
      });
    }
  } catch (e) {
    print('Error starting recording: $e');
  }
}

Future<void> _stopRecording() async {
  try {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      String audioUrl = await _uploadFile(path, 'chat_audios');
      widget.onSendMessage(audioUrl, MessageType.voice);
    }
  } catch (e) {
    print('Error stopping recording: $e');
  }
}

  Future<String> _uploadFile(String filePath, String folder) async {
    File file = File(filePath);
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    Reference ref = FirebaseStorage.instance
        .ref()
        .child(folder)
        .child(widget.chatId)
        .child(fileName);

    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _sendImage,
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
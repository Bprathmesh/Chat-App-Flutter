import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const UserAvatar({
    Key? key,
    required this.name,
    this.imageUrl,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey[300],
      backgroundImage: imageUrl != null
          ? CachedNetworkImageProvider(imageUrl!) as ImageProvider
          : null,
      child: imageUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.black,
                fontSize: size / 2,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
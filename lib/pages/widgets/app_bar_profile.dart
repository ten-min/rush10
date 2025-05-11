import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class AppBarProfile extends StatelessWidget {
  final String? profileImage;
  final String username;
  final VoidCallback onTap;

  const AppBarProfile({
    Key? key,
    required this.profileImage,
    required this.username,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (profileImage != null && profileImage!.isNotEmpty) {
      try {
        final bytes = base64Decode(profileImage!);
        return GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            backgroundImage: MemoryImage(bytes),
            radius: 18,
          ),
        );
      } catch (_) {
        // fallback
      }
    }
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: const Color(0xFFE7EAFE),
        radius: 18,
        child: Text(
          username.substring(0, 1),
          style: const TextStyle(
            color: Color(0xFF5A4FF3),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 
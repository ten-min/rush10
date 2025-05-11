import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class AppBarProfile extends StatelessWidget {
  final String? profileImageUrl;
  final String nickname;
  final VoidCallback onTap;

  const AppBarProfile({
    Key? key,
    required this.profileImageUrl,
    required this.nickname,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      try {
        final bytes = base64Decode(profileImageUrl!);
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
          nickname.substring(0, 1),
          style: const TextStyle(
            color: Color(0xFF5A4FF3),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 
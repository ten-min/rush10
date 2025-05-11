import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/participant.dart';
import '../../constants/sizes.dart';
import '../../constants/colors.dart';

class ProfileAvatar extends StatelessWidget {
  final Participant participant;
  const ProfileAvatar({Key? key, required this.participant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && participant.profileImageUrl.isNotEmpty) {
      try {
        final bytes = base64Decode(participant.profileImageUrl);
        return CircleAvatar(backgroundImage: MemoryImage(bytes), radius: AppSizes.avatar);
      } catch (_) {
        return _defaultAvatar(participant.name);
      }
    } else if (!kIsWeb && participant.profileImageUrl.isNotEmpty) {
      return CircleAvatar(backgroundImage: FileImage(File(participant.profileImageUrl)), radius: AppSizes.avatar);
    } else {
      return _defaultAvatar(participant.name);
    }
  }

  Widget _defaultAvatar(String name) => CircleAvatar(
    backgroundColor: AppColors.hostBadge,
    radius: AppSizes.avatar,
    child: Text(name.substring(0, 1), style: TextStyle(color: AppColors.hostBadgeText, fontWeight: FontWeight.bold, fontSize: AppSizes.subtitle)),
  );
} 
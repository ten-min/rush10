import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';

class Participant {
  final String id;
  final String name;
  final bool isHost;
  final String profileImageUrl;
  bool completed;
  Uint8List? photoBytes;
  File? photoFile;
  String description;

  Participant({
    required this.id,
    required this.name,
    required this.isHost,
    this.profileImageUrl = '',
    this.completed = false,
    this.photoBytes,
    this.photoFile,
    this.description = '',
  });
}
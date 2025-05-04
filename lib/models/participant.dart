import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';

class Participant {
  final int id;
  final String name;
  final bool isHost;
  bool completed;
  Uint8List? photoBytes;
  File? photoFile;
  String description;

  Participant({
    required this.id,
    required this.name,
    required this.isHost,
    this.completed = false,
    this.photoBytes,
    this.photoFile,
    this.description = '',
  });
}
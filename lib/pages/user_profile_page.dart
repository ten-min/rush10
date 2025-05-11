// user_profile_page.dart - 사용자 프로필 페이지

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';

class UserProfilePage extends StatefulWidget {
  final User user;
  final Function(User) onUserUpdated;

  const UserProfilePage({
    Key? key,
    required this.user,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late TextEditingController _usernameController;
  String? _profileImagePath;
  Uint8List? _profileImageBytes; // 웹용
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    if (kIsWeb && widget.user.profileImage.isNotEmpty) {
      _profileImageBytes = base64Decode(widget.user.profileImage);
      _profileImagePath = null;
    } else {
      _profileImagePath = widget.user.profileImage.isNotEmpty ? widget.user.profileImage : null;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _selectProfileImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 90,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
          _profileImagePath = null;
        });
      } else {
        setState(() {
          _profileImagePath = image.path;
          _profileImageBytes = null;
        });
      }
    }
  }

  Future<void> _saveUserProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageData;
      if (kIsWeb && _profileImageBytes != null) {
        imageData = base64Encode(_profileImageBytes!);
      } else {
        imageData = _profileImagePath ?? '';
      }

      // 사용자 정보 업데이트
      final updatedUser = widget.user.copyWith(
        username: _usernameController.text.trim(),
        profileImage: imageData,
      );

      // DB에 저장
      await DatabaseHelper.instance.updateUser(updatedUser);

      // 부모 위젯에 업데이트된 사용자 정보 전달
      widget.onUserUpdated(updatedUser);

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 업데이트되었습니다'),
          backgroundColor: Colors.green,
        ),
      );

      // 페이지 닫기
      Navigator.of(context).pop();
    } catch (e) {
      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImage() {
    if (kIsWeb) {
      if (_profileImageBytes != null) {
        return CircleAvatar(
          backgroundImage: MemoryImage(_profileImageBytes!),
          radius: 36,
        );
      } else {
        return CircleAvatar(
          backgroundColor: const Color(0xFFE7EAFE),
          radius: 36,
          child: Icon(Icons.person, color: Color(0xFF5A4FF3), size: 36),
        );
      }
    } else {
      if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
        return CircleAvatar(
          backgroundImage: FileImage(File(_profileImagePath!)),
          radius: 36,
        );
      } else {
        return CircleAvatar(
          backgroundColor: const Color(0xFFE7EAFE),
          radius: 36,
          child: Icon(Icons.person, color: Color(0xFF5A4FF3), size: 36),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('프로필 설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // 프로필 이미지
              GestureDetector(
                onTap: _selectProfileImage,
                child: _buildProfileImage(),
              ),
              
              const SizedBox(height: 30),
              
              // 사용자 정보 입력 필드
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이름',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: '이름을 입력하세요',
                        filled: true,
                        fillColor: const Color(0xFFF6F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '사용자 ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.user.userId,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          const Icon(Icons.lock, color: Colors.grey, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '가입일',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.user.createdAt.year}년 ${widget.user.createdAt.month}월 ${widget.user.createdAt.day}일',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 저장 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A4FF3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
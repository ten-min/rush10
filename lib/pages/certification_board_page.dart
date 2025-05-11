import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/certification_post.dart';
import '../models/challenge_room.dart';
import '../repositories/certification_repository.dart';
import '../utils/time_utils.dart';

class CertificationBoardPage extends StatefulWidget {
  final ChallengeRoom room;
  final String currentUserId;

  const CertificationBoardPage({
    Key? key,
    required this.room,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<CertificationBoardPage> createState() => _CertificationBoardPageState();
}

class _CertificationBoardPageState extends State<CertificationBoardPage> {
  List<CertificationPost>? _posts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await CertificationRepository.instance.getPostsByRoomId(widget.room.id);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('게시물 로딩 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물을 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${widget.room.title} - 인증 목록',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5A4FF3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts == null || _posts!.isEmpty
              ? _buildEmptyState()
              : _buildPostsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '아직 인증 게시물이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '도전 참가자들이 인증을 완료하면 여기에 표시됩니다',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    final sortedPosts = List<CertificationPost>.from(_posts!)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPosts.length,
      itemBuilder: (context, index) {
        final post = sortedPosts[index];
        final isCurrentUser = post.userId == widget.currentUserId;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 헤더 (작성자 정보)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildProfileImage(post.profileImagePath, post.username),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isCurrentUser)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5A4FF3).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '내 인증',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5A4FF3),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(post.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 인증 사진
              if (post.photoBytes != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Image.memory(
                    post.photoBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                  ),
                ),

              // 설명
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  post.description,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(String? imagePath, String username) {
    if (imagePath != null && imagePath.isNotEmpty) {
      if (kIsWeb) {
        try {
          final bytes = base64Decode(imagePath);
          return CircleAvatar(
            backgroundImage: MemoryImage(bytes),
            radius: 24,
          );
        } catch (_) {
          return _defaultAvatar(username);
        }
      } else {
        return CircleAvatar(
          backgroundImage: FileImage(File(imagePath)),
          radius: 24,
        );
      }
    } else {
      return _defaultAvatar(username);
    }
  }

  Widget _defaultAvatar(String name) {
    return CircleAvatar(
      backgroundColor: const Color(0xFFE7EAFE),
      radius: 24,
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF5A4FF3),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
} 
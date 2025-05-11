import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class CreateRoomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const CreateRoomFAB({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, right: 12),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.fab,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.fabRadius),
        ),
        child: Icon(Icons.add_circle_outline, size: AppSizes.icon, color: Colors.white),
        tooltip: '도전방 생성',
        splashColor: AppColors.fabSplash,
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../../models/challenge_room.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/sizes.dart';

class RoomCard extends StatelessWidget {
  final ChallengeRoom room;
  final VoidCallback onTap;
  final bool isJoined;
  final bool isWaiting;
  final bool isRunning;

  const RoomCard({
    Key? key,
    required this.room,
    required this.onTap,
    this.isJoined = false,
    this.isWaiting = false,
    this.isRunning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('[ChallengePage] build 호출됨!');
    Color statusColor;
    String statusText;
    if (isRunning) {
      statusColor = AppColors.running;
      statusText = AppStrings.running;
    } else if (isWaiting) {
      statusColor = AppColors.waiting;
      statusText = AppStrings.waiting;
    } else {
      statusColor = Colors.grey;
      statusText = '';
    }
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSizes.padding),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: AppSizes.small),
                    Text(room.description, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: AppSizes.medium),
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.grey[500], size: AppSizes.icon),
                        const SizedBox(width: AppSizes.small),
                        Text('${room.participantCount}명', style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: AppSizes.badge),
                        if (statusText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.badge, vertical: AppSizes.small),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSizes.badge),
                            ),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontSize: AppSizes.small, fontWeight: FontWeight.bold)),
                          ),
                        if (isJoined)
                          Container(
                            margin: const EdgeInsets.only(left: AppSizes.small),
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.badge, vertical: AppSizes.small),
                            decoration: BoxDecoration(
                              color: AppColors.hostBadge,
                              borderRadius: BorderRadius.circular(AppSizes.badge),
                            ),
                            child: const Text(AppStrings.joined, style: TextStyle(color: AppColors.hostBadgeText, fontSize: AppSizes.small)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey, size: AppSizes.icon),
            ],
          ),
        ),
      ),
    );
  }
} 
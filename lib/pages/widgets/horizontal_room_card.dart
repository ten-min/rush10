import 'package:flutter/material.dart';
import '../../models/challenge_room.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/sizes.dart';

class HorizontalRoomCard extends StatelessWidget {
  final ChallengeRoom room;
  final VoidCallback onTap;
  final String statusText;
  final String timerText;
  final Color statusColor;
  final bool isWaiting;
  final bool isRunning;

  const HorizontalRoomCard({
    Key? key,
    required this.room,
    required this.onTap,
    required this.statusText,
    required this.timerText,
    required this.statusColor,
    this.isWaiting = false,
    this.isRunning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.horizontalCardWidth,
        margin: EdgeInsets.only(right: AppSizes.badge, bottom: AppSizes.medium),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                room.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSizes.small),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.badge, vertical: AppSizes.small),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(AppSizes.badge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: AppSizes.icon,
                    ),
                    SizedBox(width: AppSizes.small),
                    Text(
                      timerText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.subtitle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (statusText.isNotEmpty) ...[
                      SizedBox(width: AppSizes.badge),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.small,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
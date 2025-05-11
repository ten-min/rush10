import 'package:flutter/material.dart';
import '../../models/participant.dart';
import 'profile_avatar.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/sizes.dart';


class ParticipantTile extends StatelessWidget {
  final Participant participant;

  const ParticipantTile({
    Key? key,
    required this.participant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(participant: participant),
        SizedBox(width: AppSizes.small),
        Text(participant.name, style: TextStyle(fontSize: AppSizes.subtitle)),
        if (participant.isHost)
          Padding(
            padding: EdgeInsets.only(left: AppSizes.small),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.badge, vertical: AppSizes.small),
              decoration: BoxDecoration(
                color: AppColors.hostBadge,
                borderRadius: BorderRadius.circular(AppSizes.badge),
              ),
              child: Text(AppStrings.host, style: TextStyle(color: AppColors.hostBadgeText, fontSize: AppSizes.small)),
            ),
          ),
      ],
    );
  }
} 
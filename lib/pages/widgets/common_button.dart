import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool expanded;

  const CommonButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.expanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF5A4FF3),
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return expanded ? Expanded(child: btn) : btn;
  }
} 
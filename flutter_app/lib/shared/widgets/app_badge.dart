import 'package:flutter/material.dart';
import '../../core/theme/app_extensions.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color color;

  const AppBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: context.typography.statusLabel.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}

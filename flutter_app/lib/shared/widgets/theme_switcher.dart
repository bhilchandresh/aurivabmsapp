import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/theme_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return Obx(() {
      // We use Obx but we actually just rebuild it since it switches Get Material theme immediately
      final isDark = themeService.isDarkMode.value;

      return GestureDetector(
        onTap: () {
          themeService.switchTheme();
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Icon(
            isDark ? LucideIcons.moon : LucideIcons.sun,
            size: 20,
            color: Theme.of(context).iconTheme.color,
          )
              .animate(key: ValueKey(isDark))
              .fade(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8)),
        ),
      );
    });
  }
}

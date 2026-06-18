import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showMenu;
  final bool showProfile;
  final bool showBadge;
  final bool? showBackButton;
  final VoidCallback? onBack;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showMenu = false,
    this.showProfile = true,
    this.showBadge = true,
    this.showBackButton,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? canPop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E293B).withOpacity(0.95) : Colors.white.withOpacity(0.95);
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.border;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              // Dynamic Leading Icon based on pop state & showMenu override
              if (shouldShowBack) ...[
                IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: titleColor),
                  onPressed: onBack ?? () => Get.back(),
                ),
                const SizedBox(width: 4),
              ] else if (showMenu) ...[
                IconButton(
                  icon: Icon(LucideIcons.menu, color: subtitleColor),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ] else ...[
                const SizedBox(width: 24), // Elegant left padding for primary tabs without icons
              ],

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SYSTEM LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subtitleColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Role Badge (Only shown if showBadge is true)
              if (showBadge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.blue.shade800.withOpacity(0.4) : Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.hexagon, size: 12, color: isDark ? Colors.blue.shade300 : AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.blue.shade300 : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
              
              // Profile Avatar (Only shown if showProfile is true)
              if (showProfile) ...[
                Container(
                  height: 40,
                  width: 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'A', // First letter of Name
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

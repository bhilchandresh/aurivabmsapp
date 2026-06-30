import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/notifications/notification_controller.dart';
import '../../features/notifications/notification_screen.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showMenu;
  final bool showProfile;
  final bool showBadge;
  final bool showNotification;
  final bool? showBackButton;
  final VoidCallback? onBack;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showMenu = false,
    this.showProfile = true,
    this.showBadge = true,
    this.showNotification = false,
    this.showBackButton,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? canPop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).cardTheme.color ?? Colors.white;
    final borderColor = Theme.of(context).colorScheme.outline;
    final titleColor = Theme.of(context).textTheme.displayLarge?.color;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Container(
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
                  const SizedBox(
                    width: 24,
                  ), // Elegant left padding for primary tabs without icons
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
                              decoration: BoxDecoration(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.hexagon,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Obx(() {
                          final authCtrl = Get.isRegistered<AuthController>()
                              ? Get.find<AuthController>()
                              : Get.put(AuthController());
                          final role = authCtrl.userRole.value.toUpperCase();
                          String displayRole = 'USER';
                          if (role.isNotEmpty) {
                            displayRole = role.replaceAll('_', ' ');
                          }
                          return Text(
                            displayRole,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Notification Icon
                if (showNotification) ...[
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(CupertinoIcons.bell, color: titleColor),
                        onPressed: () {
                          Get.to(() => const NotificationScreen());
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GetX<NotificationController>(
                          init: Get.isRegistered<NotificationController>()
                              ? Get.find<NotificationController>()
                              : Get.put(NotificationController()),
                          builder: (controller) {
                            if (controller.unreadCount.value > 0) {
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${controller.unreadCount.value}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
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
                      border: Border.all(
                        color: Theme.of(context).cardTheme.color ?? Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Obx(() {
                        final authCtrl = Get.isRegistered<AuthController>()
                            ? Get.find<AuthController>()
                            : Get.put(AuthController());
                        final role = authCtrl.userRole.value.toUpperCase();

                        String letter = 'U';
                        if (role.contains('ADMIN')) {
                          letter = 'A';
                        } else if (role.contains('USER')) {
                          letter = 'U';
                        } else if (authCtrl.userName.value.isNotEmpty) {
                          letter = authCtrl.userName.value[0].toUpperCase();
                        }

                        return Text(
                          letter,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        );
                      }),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../auth/auth_controller.dart';
import '../notifications/super_admin_notifications_screen.dart';

class SuperAdminTopBar extends StatelessWidget {
  const SuperAdminTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: context.colorSchemeExtension.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Text Logo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Auriva',
                    style: context.typography.screenTitle.copyWith(
                      fontSize: isMobile ? 22 : 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'BMS',
                    style: context.typography.screenTitle.copyWith(
                      fontSize: isMobile ? 22 : 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2563EB),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'BUSINESS MANAGEMENT SYSTEM',
                style: context.typography.screenTitle.copyWith(
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          // Right Side: Actions
          Row(
            children: [
              // Notification Bell
              GestureDetector(
                onTap: () =>
                    Get.to(() => const SuperAdminNotificationsScreen()),
                child: const Icon(
                  CupertinoIcons.bell,
                  color: Color(0xFF64748B),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Vertical Divider
              Container(height: 36, width: 1, color: Colors.grey.shade200),

              const SizedBox(width: 16),

              // Profile Info (Hidden on very small mobile)
              if (!isMobile) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SUPER ADMIN',
                      style: context.typography.inputText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'SECURE SESSION',
                      style: context.typography.helperText.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
              ],

              // Profile Badge
              GestureDetector(
                onTap: () {
                  final authController = Get.find<AuthController>();
                  authController.logout();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'S',
                      style: context.typography.screenTitle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

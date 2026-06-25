import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationController>() 
        ? Get.find<NotificationController>() 
        : Get.put(NotificationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Notifications',
        subtitle: 'Your recent updates',
        showMenu: false,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.bell, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];
            final bool isRead = notif.isRead;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (!isRead) {
                      controller.markAsRead(notif.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead ? Colors.grey.shade100 : Colors.blue.shade100,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isRead ? 0.02 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIconContainer(notif.type),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.message,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                        color: isRead ? Colors.grey.shade800 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      margin: const EdgeInsets.only(left: 12, top: 4),
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blueAccent,
                                            blurRadius: 4,
                                          )
                                        ],
                                      ),
                                    )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(LucideIcons.clock, size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeago.format(notif.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (notif.actionLink != null && notif.actionLink!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'View Details',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildIconContainer(String type) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case 'warning':
        bgColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        icon = LucideIcons.alertTriangle;
        break;
      case 'success':
        bgColor = Colors.green.shade50;
        iconColor = Colors.green.shade600;
        icon = LucideIcons.checkCircle2;
        break;
      case 'error':
        bgColor = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        icon = LucideIcons.xCircle;
        break;
      case 'info':
      default:
        bgColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade600;
        icon = LucideIcons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}

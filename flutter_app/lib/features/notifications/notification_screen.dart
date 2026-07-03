import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_extensions.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'notifications'.tr,
        subtitle: 'notifications_sub'.tr,
        showMenu: false,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: context.colorScheme.primary),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.bell, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'no_notifications'.tr,
                  style: context.typography.emptyStateDescription.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
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
                      color: isRead
                          ? Theme.of(context).cardTheme.color
                          : Theme.of(context).primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                            : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isRead ? 0.01 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIconContainer(context, notif.type),
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
                                      style: context.typography.inputText.copyWith(
                                        fontSize: 14,
                                        height: 1.4,
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        color: isRead
                                            ? Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6)
                                            : Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        left: 12,
                                        top: 4,
                                      ),
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blueAccent,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.clock,
                                    size: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeago.format(notif.createdAt),
                                    style: context.typography.helperText.copyWith(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (notif.actionLink != null &&
                                  notif.actionLink!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        'view_details'.tr,
                                        style: context.typography.buttonText.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: context.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        size: 14,
                                        color: context.colorScheme.primary,
                                      ),
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

  Widget _buildIconContainer(BuildContext context, String type) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case 'warning':
        bgColor = isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50;
        iconColor = isDark ? Colors.orange.shade400 : Colors.orange.shade700;
        icon = LucideIcons.alertTriangle;
        break;
      case 'success':
        bgColor = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
        iconColor = isDark ? Colors.green.shade400 : Colors.green.shade600;
        icon = LucideIcons.checkCircle2;
        break;
      case 'error':
        bgColor = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
        iconColor = isDark ? Colors.red.shade400 : Colors.red.shade600;
        icon = LucideIcons.xCircle;
        break;
      case 'info':
      default:
        bgColor = isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50;
        iconColor = isDark ? Colors.blue.shade400 : Colors.blue.shade600;
        icon = LucideIcons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}

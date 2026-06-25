import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'super_admin_notifications_controller.dart';

class SuperAdminNotificationsScreen extends StatelessWidget {
  const SuperAdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuperAdminNotificationsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Obx(() {
                            if (controller.isLoading.value) {
                              return const Padding(
                                padding: EdgeInsets.all(60.0),
                                child: Center(child: CircularProgressIndicator(color: Colors.blue)),
                              );
                            }
                            
                            if (controller.notifications.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(60.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(LucideIcons.bellRing, size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No new notifications',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: controller.notifications.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                              itemBuilder: (context, index) {
                                final notif = controller.notifications[index];
                                final isRead = notif['isRead'] == true;
                                final type = notif['type'] ?? 'info';
                                
                                Color iconColor = Colors.blue;
                                IconData iconData = LucideIcons.info;
                                
                                if (type == 'success') {
                                  iconColor = Colors.green;
                                  iconData = LucideIcons.checkCircle;
                                } else if (type == 'warning') {
                                  iconColor = Colors.orange;
                                  iconData = LucideIcons.alertTriangle;
                                } else if (type == 'error') {
                                  iconColor = Colors.red;
                                  iconData = LucideIcons.xCircle;
                                }

                                String timeStr = '';
                                if (notif['createdAt'] != null) {
                                  try {
                                    final dt = DateTime.parse(notif['createdAt']).toLocal();
                                    timeStr = DateFormat('MMM dd, hh:mm a').format(dt);
                                  } catch (e) {
                                    timeStr = '';
                                  }
                                }

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  tileColor: isRead ? Colors.transparent : Colors.blue.shade50.withOpacity(0.3),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: iconColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(iconData, color: iconColor, size: 24),
                                  ),
                                  title: Text(
                                    notif['message'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                    ),
                                  ),
                                  onTap: () {
                                    if (!isRead) {
                                      controller.markAsRead(notif['_id'], index);
                                    }
                                  },
                                );
                              },
                            );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

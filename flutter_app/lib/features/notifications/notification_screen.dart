import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_extensions.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'notification_controller.dart';
import 'notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<String> _tabs = ['All', 'System', 'Invoices', 'Inventory', 'Expenses'];
  String _selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'notifications'.tr,
        showMenu: false,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabs(),
          Expanded(
            child: Obx(() {
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

              final filtered = _getFilteredNotifications(controller.notifications);
              
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No $_selectedTab notifications',
                    style: context.typography.emptyStateDescription.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              final grouped = _groupNotifications(filtered);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final groupKey = grouped.keys.elementAt(index);
                  final items = grouped[groupKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                        child: Text(
                          '$groupKey (${items.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...items.map((notif) => _buildNotificationCard(context, notif, controller)),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.withValues(alpha: 0.15) : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<AppNotification> _getFilteredNotifications(List<AppNotification> all) {
    if (_selectedTab == 'All') return all;
    return all.where((n) {
      final t = n.type.toLowerCase();
      if (_selectedTab == 'Invoices') return t.contains('invoice') || t.contains('bill');
      if (_selectedTab == 'Inventory') return t.contains('inventory') || t.contains('stock') || t.contains('item');
      if (_selectedTab == 'Expenses') return t.contains('expense');
      if (_selectedTab == 'System') return t.contains('system') || t.contains('summary') || t.contains('info');
      return false;
    }).toList();
  }

  Map<String, List<AppNotification>> _groupNotifications(List<AppNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AppNotification>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (var n in notifications) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (date == today) {
        grouped['Today']!.add(n);
      } else if (date == yesterday) {
        grouped['Yesterday']!.add(n);
      } else {
        grouped['Earlier']!.add(n);
      }
    }

    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notif, NotificationController controller) {
    final isRead = notif.isRead;
    final type = notif.type.toLowerCase();
    
    Color baseColor = Colors.blue;
    String badgeText = 'SUMMARY';
    
    if (type.contains('invoice')) {
      baseColor = Colors.red;
      badgeText = 'INVOICE';
    } else if (type.contains('inventory') || type.contains('stock')) {
      baseColor = Colors.orange;
      badgeText = 'INVENTORY';
    } else if (type.contains('expense')) {
      baseColor = Colors.green;
      badgeText = 'EXPENSE';
    } else if (type.contains('system') || type.contains('warning')) {
      baseColor = Colors.purple;
      badgeText = 'SYSTEM';
    }

    String title = notif.message;
    String subtitle = '';
    if (notif.message.contains('\n')) {
      final parts = notif.message.split('\n');
      title = parts[0];
      subtitle = parts.sublist(1).join('\n');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isRead) {
              controller.markAsRead(notif.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: baseColor,
                      width: 4,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: baseColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: baseColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(notif.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: SvgPicture.asset(
                        isRead ? 'assets/SVG/doubletick.svg' : 'assets/SVG/tick.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          isRead ? Colors.blue : Colors.grey.shade400,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

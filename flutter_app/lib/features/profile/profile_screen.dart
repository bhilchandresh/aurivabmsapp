import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_controller.dart';
import '../inventory/inventory_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../expenses/expenses_screen.dart';
import '../team/team_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/notification_controller.dart';
import '../notifications/notifications_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _hoveredIndex;

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    
    final NotificationController notificationController = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController(), permanent: true);

    return SafeArea(
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gorgeous Header Hero with Premium Gradient (FIXED - DOES NOT SCROLL)
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // slate-900
                  Color(0xFF1E3A8A), // dark blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Account',
                          style: AppTextStyles.heading2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.bell, color: Colors.white),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const NotificationsBottomSheet(),
                                );
                              },
                            ),
                            Obx(() {
                              if (notificationController.unreadCount.value > 0) {
                                return Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${notificationController.unreadCount.value}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Elegant Circular Avatar with Glowing Gradient Border
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.tealAccent, AppColors.primary],
                            ),
                          ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Obx(() => Text(
                              _getInitials(authController.userName.value),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 0.5,
                              ),
                            )),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Text(
                              authController.userName.value.isNotEmpty
                                  ? authController.userName.value
                                  : 'My Account',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  ),
                                  child: Obx(() {
                                    final role = authController.userRole.value.isNotEmpty
                                        ? authController.userRole.value
                                        : 'USER';
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.shield, color: Colors.tealAccent, size: 10),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${role.toUpperCase()} ACCESS',
                                          style: const TextStyle(
                                            color: Colors.tealAccent,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable Body Content (Menu Items and Operations)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Business Operations
                _buildSectionHeader('BUSINESS OPERATIONS'),
                const SizedBox(height: 8),
                
                // Animated Block 1
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1.0 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuRow(
                          context,
                          index: 0,
                          title: 'Inventory',
                          subtitle: 'Stock tracking & products',
                          icon: LucideIcons.package,
                          iconColor: Colors.blue.shade600,
                          iconBg: Colors.blue.shade50,
                          onTap: () => Get.to(() => const InventoryScreen()),
                        ),
                        _buildDivider(),
                        _buildMenuRow(
                          context,
                          index: 1,
                          title: 'Suppliers',
                          subtitle: 'Manage vendors & history',
                          icon: LucideIcons.truck,
                          iconColor: Colors.orange.shade600,
                          iconBg: Colors.orange.shade50,
                          onTap: () => Get.to(() => const SuppliersScreen()),
                        ),
                        _buildDivider(),
                        _buildMenuRow(
                          context,
                          index: 2,
                          title: 'Expenses',
                          subtitle: 'Track outflows & bills',
                          icon: LucideIcons.wallet,
                          iconColor: Colors.green.shade600,
                          iconBg: Colors.green.shade50,
                          onTap: () => Get.to(() => const ExpensesScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Administration
                _buildSectionHeader('ADMINISTRATION'),
                const SizedBox(height: 8),

                // Animated Block 2
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1.0 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuRow(
                          context,
                          index: 3,
                          title: 'Team & Access',
                          subtitle: 'Permissions & staff logs',
                          icon: LucideIcons.shieldCheck,
                          iconColor: Colors.purple.shade600,
                          iconBg: Colors.purple.shade50,
                          onTap: () => Get.to(() => const TeamScreen()),
                        ),
                        _buildDivider(),
                        _buildMenuRow(
                          context,
                          index: 4,
                          title: 'Settings',
                          subtitle: 'App & business settings',
                          icon: LucideIcons.settings,
                          iconColor: Colors.blueGrey.shade600,
                          iconBg: Colors.blueGrey.shade50,
                          onTap: () => Get.to(() => const SettingsScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Stylish Custom Logout Button with Soft Shadow
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1.0 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () => authController.logout(),
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: const Text(
                        'SIGN OUT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade200, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.red.shade50.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // Padding to avoid overlap with floating bottom nav
              ],
            ),
          ),
        ),
      ],
      ),
     ),
  );
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.5,
      ),
    ),
  );
}

Widget _buildMenuRow(
  BuildContext context, {
  required int index,
  required String title,
  required String subtitle,
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required VoidCallback onTap,
}) {
  final isHovered = _hoveredIndex == index;

  return InkWell(
    onTap: onTap,
    onHover: (hovering) {
      setState(() {
        _hoveredIndex = hovering ? index : null;
      });
    },
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: isHovered ? AppColors.primary.withOpacity(0.02) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHovered ? AppColors.primary.withOpacity(0.15) : iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isHovered ? AppColors.primary : iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isHovered ? AppColors.primary : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isHovered ? AppColors.primary.withOpacity(0.7) : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: isHovered ? AppColors.primary : Colors.grey.shade400,
          ),
        ],
      ),
    ),
  );
}

Widget _buildDivider() {
  return Divider(
    height: 1,
    thickness: 1,
    indent: 72, // Perfect alignment with text and icon spacing
    color: Colors.grey.shade100,
  );
}
}

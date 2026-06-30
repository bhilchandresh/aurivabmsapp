import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_controller.dart';
import '../inventory/inventory_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../expenses/expenses_screen.dart';
import '../team/team_screen.dart';
import '../settings/settings_screen.dart';
import '../import_data/import_data_screen.dart';
import '../notifications/notification_controller.dart';
import '../notifications/notification_screen.dart';
import 'your_information_screen.dart';
import '../../core/theme/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _hoveredIndex;

  void _showLogoutConfirmDialog(BuildContext context, AuthController authController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.red.shade100,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red icon badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade600,
                  size: 26,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'sign_out'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              // Subtitle
              Text(
                'sign_out_confirm'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: dividerColor, height: 1),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm Sign Out
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        authController.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.red.withValues(alpha: 0.85)
                            : Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'sign_out'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

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

    final NotificationController notificationController =
        Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController(), permanent: true);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Code-generated Logo Header matching Super Admin Profile
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                decoration: BoxDecoration(
                  color: Color(0xFF1E293B), // Dark background from screenshot
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // App Icon (White square, blue hexagon)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.hexagon,
                          color: Color(0xFF2563EB),
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // AurivaBMS Text — font locked to Inter so weight never
                    // changes when the app language switches to a non-Latin locale.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Auriva',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'BMS',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.blue.shade600,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'BUSINESS MANAGEMENT SYSTEM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body Content (Menu Items and Operations)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Business Operations
                    _buildSectionHeader('business_operations'.tr),
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
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuRow(
                              context,
                              index: 99, // Unique index for your info
                              title: 'your_information'.tr,
                              subtitle: 'your_info_sub'.tr,
                              icon: LucideIcons.user,
                              iconColor: Colors.blue.shade600,
                              iconBg: Colors.blue.shade50,
                              onTap: () =>
                                  Get.to(() => const YourInformationScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 0,
                              title: 'inventory'.tr,
                              subtitle: 'inventory_sub'.tr,
                              icon: LucideIcons.package,
                              iconColor: Colors.blue.shade600,
                              iconBg: Colors.blue.shade50,
                              onTap: () =>
                                  Get.to(() => const InventoryScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 1,
                              title: 'suppliers'.tr,
                              subtitle: 'suppliers_sub'.tr,
                              icon: LucideIcons.truck,
                              iconColor: Colors.orange.shade600,
                              iconBg: Colors.orange.shade50,
                              onTap: () =>
                                  Get.to(() => const SuppliersScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 2,
                              title: 'expenses'.tr,
                              subtitle: 'expenses_sub'.tr,
                              icon: LucideIcons.wallet,
                              iconColor: Colors.green.shade600,
                              iconBg: Colors.green.shade50,
                              onTap: () => Get.to(() => const ExpensesScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 5, // Unique index
                              title: 'import_data'.tr,
                              subtitle: 'import_data_sub'.tr,
                              icon: LucideIcons.database,
                              iconColor: Colors.teal.shade600,
                              iconBg: Colors.teal.shade50,
                              onTap: () => Get.to(() => ImportDataScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 10,
                              title: 'notifications'.tr,
                              subtitle: 'notifications_sub'.tr,
                              icon: LucideIcons.bell,
                              iconColor: Colors.red.shade500,
                              iconBg: Colors.red.shade50,
                              onTap: () =>
                                  Get.to(() => const NotificationScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 6,
                              title: 'language'.tr,
                              subtitle: 'change_language_sub'.tr,
                              icon: LucideIcons.languages,
                              iconColor: Colors.indigo.shade600,
                              iconBg: Colors.indigo.shade50,
                              onTap: () => Get.toNamed('/language'),
                            ),
                            _buildDivider(),
                            Obx(() {
                              final isDark = Get.find<ThemeService>().isDarkMode.value;
                              return _buildMenuRow(
                                context,
                                index: 7,
                                title: isDark ? 'light_mode'.tr : 'dark_mode'.tr,
                                subtitle: 'toggle_theme'.tr,
                                icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                                iconColor: isDark ? Colors.amber.shade600 : Colors.blueGrey.shade600,
                                iconBg: isDark ? Colors.amber.shade50 : Colors.blueGrey.shade50,
                                onTap: () {
                                  Get.find<ThemeService>().switchTheme();
                                },
                                trailing: CupertinoSwitch(
                                  value: isDark,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    Get.find<ThemeService>().switchTheme();
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Administration
                    _buildSectionHeader('administration'.tr),
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
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuRow(
                              context,
                              index: 3,
                              title: 'team_access'.tr,
                              subtitle: 'team_access_sub'.tr,
                              icon: LucideIcons.shieldCheck,
                              iconColor: Colors.purple.shade600,
                              iconBg: Colors.purple.shade50,
                              onTap: () => Get.to(() => const TeamScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 4,
                              title: 'settings'.tr,
                              subtitle: 'settings_sub'.tr,
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
                          onPressed: () => _showLogoutConfirmDialog(context, authController),
                          icon: Icon(LucideIcons.logOut, size: 18),
                          label: Text(
                            'sign_out'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade400 : Colors.red.shade600,
                            side: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade900.withValues(alpha: 0.5) : Colors.red.shade200,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.red.withValues(alpha: 0.06)
                                : Colors.red.shade50.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 100,
                    ), // Padding to avoid overlap with floating bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
    required bool showBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: Colors.grey.shade100))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    Widget? trailing,
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
          color: isHovered
              ? AppColors.primary.withOpacity(0.02)
              : Colors.transparent,
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
                      color: isHovered
                          ? AppColors.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isHovered
                          ? AppColors.primary.withOpacity(0.7)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(
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
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
    );
  }
}

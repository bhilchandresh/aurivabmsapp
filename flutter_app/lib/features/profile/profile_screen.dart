import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_extensions.dart';
import '../auth/auth_controller.dart';
import '../inventory/inventory_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../expenses/expenses_screen.dart';
import '../team/team_screen.dart';
import '../settings/settings_screen.dart';
import '../import_data/import_data_screen.dart';
import '../notifications/notification_screen.dart';
import 'your_information_screen.dart';
import '../support/contact_screen.dart';
import '../support/info_screen.dart';
import '../../core/theme/theme_service.dart';
import '../../navigation/main_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _hoveredIndex;

  void _showLogoutConfirmDialog(BuildContext context, AuthController authController) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? Colors.grey.shade900 : Colors.white);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    // Centered Icon with subtle rings
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.withValues(alpha: 0.05), width: 1),
                          ),
                        ),
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.withValues(alpha: 0.1), width: 1),
                          ),
                        ),
                        Positioned(
                          top: 10, right: 10,
                          child: Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), shape: BoxShape.circle)),
                        ),
                        Positioned(
                          bottom: 10, left: 10,
                          child: Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.3), shape: BoxShape.circle)),
                        ),
                        Positioned(
                          bottom: 25, right: 5,
                          child: Container(width: 5, height: 5, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), shape: BoxShape.circle)),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SvgPicture.asset(
                            'assets/SVG/logout.svg',
                            colorFilter: ColorFilter.mode(Colors.red.shade500, BlendMode.srcIn),
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle
                    Text(
                      'Are you sure you want to sign out\nfrom your account?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Warning Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SvgPicture.asset(
                              'assets/SVG/shield.svg',
                              colorFilter: ColorFilter.mode(Colors.red.shade500, BlendMode.srcIn),
                              width: 18,
                              height: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You will need to sign in again to access your account and data.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        // Cancel
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.grey.shade300,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/SVG/logout.svg',
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sign Out',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Close button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

//   String _getInitials(String name) {
//     if (name.isEmpty) return '??';
//     final parts = name.trim().split(RegExp(r'\s+'));
//     if (parts.length > 1) {
//       return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
//     }
//     return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
//   }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
        
    final isAdmin = authController.userRole.value.toLowerCase().contains('admin');

//     final NotificationController notificationController =
//         Get.isRegistered<NotificationController>()
//         ? Get.find<NotificationController>()
//         : Get.put(NotificationController(), permanent: true);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF1E293B),
            pinned: true,
            expandedHeight: 260.0,
            toolbarHeight: 64.0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () {
                if (Get.isRegistered<MainLayoutController>()) {
                  Get.find<MainLayoutController>().changeIndex(0);
                } else {
                  Get.back();
                }
              },
            ),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                final statusBarHeight = MediaQuery.of(context).padding.top;
                final minHeight = statusBarHeight + 64.0;
                const expandedHeight = 260.0;

                double t = (expandedHeight - top) / (expandedHeight - minHeight);
                t = t.clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Optional subtle hex pattern for background
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        LucideIcons.hexagon,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      top: 40,
                      child: Icon(
                        LucideIcons.hexagon,
                        size: 120,
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                    
                    // Expanded Content (Fades out)
                    Opacity(
                      opacity: (1 - t * 2).clamp(0.0, 1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
                          const SizedBox(height: 16),
                          Row(
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
                          const SizedBox(height: 4),
                          Text(
                            'BUSINESS MANAGEMENT SYSTEM',
                            style: context.typography.categoryHeader.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Collapsed Content (Fades in)
                    Positioned(
                      left: 56.0,
                      bottom: 12.0,
                      child: Opacity(
                        opacity: ((t - 0.5) * 2).clamp(0.0, 1.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'Auriva',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'BMS',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blue.shade600,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Settings',
                              style: context.typography.categoryHeader.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Body Content (Menu Items and Operations)
          SliverToBoxAdapter(
            child: Padding(
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
                              color: Colors.black.withValues(alpha: 0.01),
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
                              iconAsset: 'assets/SVG/profile.svg',
                              iconColor: Colors.blue.shade600,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                              onTap: () =>
                                  Get.to(() => const YourInformationScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 0,
                              title: 'inventory'.tr,
                              subtitle: 'inventory_sub'.tr,
                              iconAsset: 'assets/SVG/inventory.svg',
                              iconColor: Colors.blue.shade600,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                              onTap: () =>
                                  Get.to(() => const InventoryScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 1,
                              title: 'suppliers'.tr,
                              subtitle: 'suppliers_sub'.tr,
                              iconAsset: 'assets/SVG/supplier.svg',
                              iconColor: Colors.orange.shade600,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.shade50,
                              onTap: () =>
                                  Get.to(() => const SuppliersScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 2,
                              title: 'expenses'.tr,
                              subtitle: 'expenses_sub'.tr,
                              iconAsset: 'assets/SVG/expance.svg',
                              iconColor: Colors.green.shade600,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50,
                              onTap: () => Get.to(() => const ExpensesScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 5, // Unique index
                              title: 'import_data'.tr,
                              subtitle: 'import_data_sub'.tr,
                              iconAsset: 'assets/SVG/import.svg',
                              iconColor: Colors.teal.shade600,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.teal.withValues(alpha: 0.1) : Colors.teal.shade50,
                              onTap: () => Get.to(() => const ImportDataScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 10,
                              title: 'notifications'.tr,
                              subtitle: 'notifications_sub'.tr,
                              iconAsset: 'assets/SVG/notification.svg',
                              iconColor: Colors.red.shade500,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50,
                              onTap: () =>
                                  Get.to(() => const NotificationScreen()),
                            ),
                            _buildDivider(),
                            Obx(() {
                              final isDark = Get.find<ThemeService>().isDarkMode.value;
                              return _buildMenuRow(
                                context,
                                index: 7,
                                title: isDark ? 'light_mode'.tr : 'dark_mode'.tr,
                                subtitle: 'toggle_theme'.tr,
                                iconAsset: isDark ? 'assets/SVG/light.svg' : 'assets/SVG/dark.svg',
                                iconColor: isDark ? Colors.amber.shade600 : Colors.blueGrey.shade600,
                                iconBg: isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.blueGrey.shade50,
                                onTap: () {
                                  Get.find<ThemeService>().switchTheme();
                                },
                                trailing: CupertinoSwitch(
                                  value: isDark,
                                  activeTrackColor: context.colorScheme.primary,
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

                    // Section: Support & Info
                    _buildSectionHeader('support_info'.tr),
                    const SizedBox(height: 8),

                    // Animated Block for Support
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 10 * (1.0 - value)),
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
                        ),
                        child: Column(
                          children: [
                            _buildMenuRow(
                              context,
                              index: 20,
                              title: 'contact_us'.tr,
                              subtitle: 'contact_us_sub'.tr,
                              iconAsset: 'assets/SVG/mail.svg',
                              iconColor: Colors.blue.shade600,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                              onTap: () => Get.to(() => const ContactScreen()),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 21,
                              title: 'privacy_policy'.tr,
                              subtitle: 'privacy_policy_sub'.tr,
                              iconAsset: 'assets/SVG/privacy.svg',
                              iconColor: Colors.green.shade600,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50,
                              onTap: () => Get.to(() => InfoScreen(
                                title: 'privacy_policy'.tr,
                                endpoint: '/public/legal/privacy_policy',
                                headerColor: const Color(0xFF0F9D58),
                                icon: LucideIcons.shieldCheck,
                                fallbackText: 'Auriva BMS ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our web application and mobile application.\n\n1. Information We Collect\nWe collect personal information that you voluntarily provide to us when you register on the Service, such as your name, email address, phone number, and company details.\n\n2. How We Use Your Information\nWe use the information we collect primarily to provide, maintain, and improve our Service.',
                              )),
                            ),
                            _buildDivider(),
                            _buildMenuRow(
                              context,
                              index: 22,
                              title: 'terms_conditions_1'.tr,
                              subtitle: 'terms_conditions_sub'.tr,
                              iconAsset: 'assets/SVG/tearmandcondition.svg',
                              iconColor: Colors.blue.shade600,
                              iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                              onTap: () => Get.to(() => InfoScreen(
                                title: 'terms_conditions_1'.tr,
                                endpoint: '/public/legal/terms_and_conditions',
                                headerColor: const Color(0xFF2563EB),
                                icon: LucideIcons.fileText,
                                fallbackText: 'Welcome to Auriva BMS. By accessing or using our Business Management System, web application, and mobile application (collectively, the "Service"), you agree to be bound by these Terms and Conditions.\n\n1. General Usage\nAuriva BMS provides a software-as-a-service (SaaS) platform for invoicing, quotation management, and business tracking.\n\n2. User Responsibilities\nYou are responsible for maintaining the confidentiality of your account credentials. Any activity occurring under your account is your sole responsibility.',
                              )),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isAdmin) ...[
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
                                color: Colors.black.withValues(alpha: 0.01),
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
                                iconAsset: 'assets/SVG/teamandaccess.svg',
                                iconColor: Colors.purple.shade600,
                                iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.purple.withValues(alpha: 0.1) : Colors.purple.shade50,
                                onTap: () => Get.to(() => const TeamScreen()),
                              ),
                              _buildDivider(),
                              _buildMenuRow(
                                context,
                                index: 4,
                                title: 'settings'.tr,
                                subtitle: 'settings_sub'.tr,
                                iconAsset: 'assets/SVG/setting-2.svg',
                                iconColor: Colors.blueGrey.shade600,
                                iconBg: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey.withValues(alpha: 0.1) : Colors.blueGrey.shade50,
                                onTap: () => Get.to(() => const SettingsScreen()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

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
                          icon: SvgPicture.asset(
                            'assets/SVG/logout.svg',
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? Colors.red.shade400 : Colors.red.shade600, BlendMode.srcIn),
                          ),
                          label: Text(
                            'sign_out'.tr,
                            style: context.typography.buttonText.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.red.shade400 : Colors.red.shade600,
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
                                : Colors.red.shade50.withValues(alpha: 0.3),
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
            ),
          ],
        ),
      );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Text(
        title.toUpperCase(),
        style: context.typography.categoryHeader.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

//   Widget _buildProfileItem({
//     required String iconAsset,
//     required String title,
//     required String value,
//     required bool showBorder,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: showBorder
//             ? Border(bottom: BorderSide(color: Colors.grey.shade100))
//             : null,
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: Colors.blue.shade600, size: 20),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: context.typography.inputLabel.copyWith(
//                     fontSize: 12,
//                     color: Colors.grey.shade500,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: context.typography.inputText.copyWith(
//                     fontSize: 15,
//                     color: const Color(0xFF1E293B),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

  Widget _buildMenuRow(
    BuildContext context, {
    required int index,
    required String title,
    required String subtitle,
    required String iconAsset,
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
              ? AppColors.primary.withValues(alpha: 0.02)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isHovered ? AppColors.primary.withValues(alpha: 0.15) : iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isHovered ? AppColors.primary : iconColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.typography.settingsTitle.copyWith(
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
                    style: context.typography.cardSubtitle.copyWith(
                      fontSize: 12,
                      color: isHovered
                          ? AppColors.primary.withValues(alpha: 0.7)
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

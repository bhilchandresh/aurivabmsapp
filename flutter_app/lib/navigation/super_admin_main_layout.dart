import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../features/super_admin/dashboard/super_admin_dashboard_screen.dart';
import '../features/super_admin/broadcast/super_admin_broadcast_screen.dart';
import '../features/super_admin/logs/super_admin_logs_screen.dart';
import '../features/super_admin/companies/super_admin_add_company_screen.dart';
import '../features/super_admin/profile/super_admin_profile_screen.dart';
import '../features/super_admin/analytics/super_admin_analytics_screen.dart';

class SuperAdminMainLayoutController extends GetxController {
  var currentIndex = 0.obs;

  final List<Widget> screens = [
    SuperAdminDashboardScreen(),
    const SuperAdminBroadcastScreen(),
    const SuperAdminAnalyticsScreen(),
    const SizedBox.shrink(), // Dummy widget for index 3 (New Company which navigates away)
    const SuperAdminProfileScreen(),
  ];

  void changeIndex(int index) {
    if (index == 3) {
      Get.to(() => const SuperAdminAddCompanyScreen());
      return;
    }
    currentIndex.value = index;
  }
}

class SuperAdminMainLayout extends StatelessWidget {
  const SuperAdminMainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuperAdminMainLayoutController());
    
    return Obx(() {
      final isFirstTab = controller.currentIndex.value == 0;
      return PopScope(
        canPop: isFirstTab,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          controller.changeIndex(0);
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.background,
          body: Obx(() {
            final activeScreen = controller.screens[controller.currentIndex.value];
            return activeScreen;
          }),
          bottomNavigationBar: SafeArea(
            child: Container(
              height: 80,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // slate-900
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(0, LucideIcons.layoutDashboard, 'Dashboard', controller),
                  _buildBottomNavItem(1, LucideIcons.radio, 'Broadcast', controller),
                  _buildBottomNavItem(2, LucideIcons.barChart2, 'Analytics', controller),
                  _buildBottomNavItem(3, LucideIcons.plusCircle, 'New Company', controller),
                  _buildBottomNavItem(4, LucideIcons.user, 'Profile', controller),
                ],
              ),
            ),
          ),
        ),
        ),
      );
    });
  }

  // Floating Bottom Navigation Nav Item
  Widget _buildBottomNavItem(int index, IconData icon, String label, SuperAdminMainLayoutController controller) {
    return GestureDetector(
      onTap: () => controller.changeIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final isSelected = controller.currentIndex.value == index;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                size: 20,
              ),
              if (isSelected) const SizedBox(width: 8),
              if (isSelected) Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_extensions.dart';
import '../features/super_admin/dashboard/super_admin_dashboard_screen.dart';
import '../features/super_admin/broadcast/super_admin_broadcast_screen.dart';
import '../features/super_admin/companies/super_admin_add_company_screen.dart';
import '../features/super_admin/profile/super_admin_profile_screen.dart';
import '../features/super_admin/analytics/super_admin_analytics_screen.dart';
import '../core/services/permission_manager.dart';

class SuperAdminMainLayoutController extends GetxController {
  var currentIndex = 0.obs;

  final List<Widget> screens = [
    SuperAdminDashboardScreen(),
    const SuperAdminBroadcastScreen(),
    const SuperAdminAnalyticsScreen(),
    const SizedBox.shrink(), // Dummy widget for index 3 (New Company which navigates away)
    const SuperAdminProfileScreen(),
  ];

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(seconds: 1), () {
      PermissionManager.requestNotificationWithExplanationDialog();
    });
  }

  void changeIndex(int index) {
    if (index == 0) {
      PermissionManager.requestNotificationWithExplanationDialog();
    }
    if (index == 3) {
      Get.to(() => const SuperAdminAddCompanyScreen());
      return;
    }
    currentIndex.value = index;
  }
}

class SuperAdminMainLayout extends StatelessWidget {
  const SuperAdminMainLayout({super.key});

  BuildContext get context => Get.context!;

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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Obx(() {
              final isLargeScreen = context.width > 800;
              final activeScreen =
                  controller.screens[controller.currentIndex.value];

              if (isLargeScreen) {
                return Row(
                  children: [
                    _buildResponsiveSidebar(context, controller),
                    Expanded(child: ClipRRect(child: activeScreen)),
                  ],
                );
              }

              return activeScreen;
            }),
            bottomNavigationBar: Builder(
              builder: (context) {
                final isLargeScreen = context.width > 800;
                if (isLargeScreen) return const SizedBox.shrink();

                return SafeArea(
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), // slate-900
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomNavItem(
                          context,
                          0,
                          LucideIcons.layoutDashboard,
                          'Dashboard',
                          controller,
                        ),
                        _buildBottomNavItem(
                          context,
                          1,
                          LucideIcons.radio,
                          'Broadcast',
                          controller,
                        ),
                        _buildBottomNavItem(
                          context,
                          2,
                          LucideIcons.barChart2,
                          'Analytics',
                          controller,
                        ),
                        _buildBottomNavItem(
                          context,
                          3,
                          LucideIcons.plusCircle,
                          'New Company',
                          controller,
                        ),
                        _buildBottomNavItem(
                          context,
                          4,
                          LucideIcons.user,
                          'Profile',
                          controller,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  // Floating Bottom Navigation Nav Item
  Widget _buildBottomNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    SuperAdminMainLayoutController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.changeIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final isSelected = controller.currentIndex.value == index;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                size: 20,
              ),
              if (isSelected) const SizedBox(width: 8),
              if (isSelected)
                Text(
                  label,
                  style: context.typography.navigationLabel.copyWith(
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

  // Premium Dashboard Sidebar (Desktop/Tablet View)
  Widget _buildResponsiveSidebar(
    BuildContext context,
    SuperAdminMainLayoutController controller,
  ) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.only(
              top: 48,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.shieldCheck,
                    size: 32,
                    color: context.colorScheme.primary,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: context.typography.profileName.copyWith(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      const TextSpan(text: 'Super'),
                      TextSpan(
                        text: 'Admin',
                        style: context.typography.profileName.copyWith(color: context.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MASTER CONTROL PANEL',
                  style: context.typography.categoryHeader.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Menu Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarMenuItem(
                  0,
                  'Dashboard',
                  LucideIcons.layoutDashboard,
                  controller,
                ),
                _buildSidebarMenuItem(
                  1,
                  'Broadcast',
                  LucideIcons.radio,
                  controller,
                ),
                _buildSidebarMenuItem(
                  2,
                  'Analytics',
                  LucideIcons.barChart2,
                  controller,
                ),
                _buildSidebarMenuItem(
                  3,
                  'New Company',
                  LucideIcons.plusCircle,
                  controller,
                ),
                _buildSidebarMenuItem(
                  4,
                  'Profile',
                  LucideIcons.user,
                  controller,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar Menu Item builder
  Widget _buildSidebarMenuItem(
    int index,
    String title,
    IconData icon,
    SuperAdminMainLayoutController controller,
  ) {
    return Obx(() {
      final isActive = controller.currentIndex.value == index;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          onTap: () => controller.changeIndex(index),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.grey.shade400,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: context.typography.inputText.copyWith(
                    fontSize: 14,
                    color: isActive ? Colors.white : Colors.grey.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: Colors.white60,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

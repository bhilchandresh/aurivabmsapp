import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/invoices/invoice_list_screen.dart';
import '../features/quotations/quotations_screen.dart';
import '../features/clients/clients_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/auth/auth_controller.dart';

class MainLayoutController extends GetxController {
  var currentIndex = 0.obs;

  final List<Widget> screens = [
    const DashboardScreen(),
    const InvoiceListScreen(),
    const QuotationsScreen(),
    const ClientsScreen(),
    const ProfileScreen(),
  ];

  void changeIndex(int index) {
    currentIndex.value = index;
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainLayoutController());
    
    return Obx(() {
      final isFirstTab = controller.currentIndex.value == 0;
      return PopScope(
        canPop: isFirstTab,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          controller.changeIndex(0);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Obx(() {
            final isLargeScreen = context.width > 800;
            final activeScreen = controller.screens[controller.currentIndex.value];

            if (isLargeScreen) {
              return Row(
                children: [
                  // Sleek, Premium Left Sidebar for Desktop/Tablet
                  _buildResponsiveSidebar(context, controller),
                  
                  // Active Screen Area
                  Expanded(
                    child: ClipRRect(
                      child: activeScreen,
                    ),
                  ),
                ],
              );
            }

            // Standard Mobile View with Bottom Nav
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
                      _buildBottomNavItem(0, LucideIcons.layoutDashboard, 'Home', controller),
                      _buildBottomNavItem(1, LucideIcons.fileText, 'Invoices', controller),
                      _buildBottomNavItem(2, LucideIcons.file, 'Quotes', controller),
                      _buildBottomNavItem(3, LucideIcons.users, 'Clients', controller),
                      _buildBottomNavItem(4, LucideIcons.user, 'Profile', controller),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  // Floating Bottom Navigation Nav Item (Mobile view)
  Widget _buildBottomNavItem(int index, IconData icon, String label, MainLayoutController controller) {
    return GestureDetector(
      onTap: () => controller.changeIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final isSelected = controller.currentIndex.value == index;
        final isSmallScreen = Get.width < 400;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? (isSmallScreen ? 10 : 16) : (isSmallScreen ? 8 : 12),
            vertical: 10
          ),
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
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              AnimatedWidth(
                width: isSelected ? (isSmallScreen ? 4 : 8) : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
                child: isSelected
                    ? Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Premium Dashboard Sidebar (Desktop/Tablet View)
  Widget _buildResponsiveSidebar(BuildContext context, MainLayoutController controller) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.only(top: 48, bottom: 32, left: 24, right: 24),
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
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(LucideIcons.hexagon, size: 32, color: AppColors.primary),
                ),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.heading2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    children: const [
                      TextSpan(text: 'Auriva'),
                      TextSpan(text: 'BMS', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BUSINESS MANAGEMENT SYSTEM',
                  style: TextStyle(
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
                _buildSidebarMenuItem(0, 'Dashboard', LucideIcons.layoutDashboard, controller),
                _buildSidebarMenuItem(1, 'Invoices', LucideIcons.fileText, controller),
                _buildSidebarMenuItem(2, 'Quotations', LucideIcons.file, controller),
                _buildSidebarMenuItem(3, 'Clients', LucideIcons.users, controller),
                _buildSidebarMenuItem(4, 'Profile', LucideIcons.user, controller),
              ],
            ),
          ),

          // Footer with Sign Out Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: InkWell(
              onTap: () {
                final authController = Get.isRegistered<AuthController>()
                    ? Get.find<AuthController>()
                    : Get.put(AuthController(), permanent: true);
                authController.logout();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.red.shade400, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar Menu Item builder
  Widget _buildSidebarMenuItem(int index, String title, IconData icon, MainLayoutController controller) {
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
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ] : null,
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
                  style: AppTextStyles.label.copyWith(
                    color: isActive ? Colors.white : Colors.grey.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  const Icon(LucideIcons.chevronRight, size: 14, color: Colors.white60),
                ]
              ],
            ),
          ),
        ),
      );
    });
  }
}

// Custom Helper Widget to smoothly animate the space between icon and text
class AnimatedWidth extends StatelessWidget {
  final double width;
  final Duration duration;
  final Curve curve;

  const AnimatedWidth({
    super.key,
    required this.width,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: width,
      height: 0,
    );
  }
}

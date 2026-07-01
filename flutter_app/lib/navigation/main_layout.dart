import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_extensions.dart';
import '../core/utils/responsive_layout.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/invoices/invoice_list_screen.dart';
import '../features/quotations/quotations_screen.dart';
import '../features/clients/clients_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/auth/auth_controller.dart';

class MainLayoutController extends GetxController {
  var currentIndex = 0.obs;
  DateTime? lastBackPressTime;

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

    return PopScope(
      canPop: false, // Always intercept back press
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (controller.currentIndex.value != 0) {
          // If not on Dashboard, go to Dashboard
          controller.changeIndex(0);
        } else {
          // If on Dashboard, implement Double Tap to Exit
          final now = DateTime.now();
          if (controller.lastBackPressTime == null ||
              now.difference(controller.lastBackPressTime!) >
                  const Duration(seconds: 2)) {
            // First tap
            controller.lastBackPressTime = now;
            Get.snackbar(
              'Exit App',
              'Press back again to exit',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.black87,
              colorText: Colors.white,
              margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              duration: const Duration(seconds: 2),
            );
          } else {
            // Second tap within 2 seconds
            SystemNavigator.pop();
          }
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Obx(() {
            final activeScreen =
                controller.screens[controller.currentIndex.value];

            return ResponsiveLayout(
              mobile: _buildMobileLayout(context, activeScreen, controller),
              tablet: _buildTabletLayout(context, activeScreen, controller),
              desktop: _buildDesktopLayout(context, activeScreen, controller),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Widget activeScreen, MainLayoutController controller) {
    final screenHeight = MediaQuery.of(context).size.height;
    // 7.5% of screen height, clamped 58–72px — compact on all phones
    final barHeight = (screenHeight * 0.078).clamp(60.0, 74.0);

    return Scaffold(
      body: activeScreen,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: barHeight,
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(0, LucideIcons.layoutDashboard, 'Home', controller, barHeight),
              _buildBottomNavItem(1, LucideIcons.fileText, 'Invoices', controller, barHeight),
              _buildBottomNavItem(2, LucideIcons.file, 'Quotes', controller, barHeight),
              _buildBottomNavItem(3, LucideIcons.users, 'Clients', controller, barHeight),
              _buildBottomNavItem(4, LucideIcons.user, 'Profile', controller, barHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, Widget activeScreen, MainLayoutController controller) {
    final theme = Theme.of(context);
    return Row(
      children: [
        NavigationRail(
          backgroundColor: theme.cardTheme.color,
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: controller.changeIndex,
          labelType: NavigationRailLabelType.all,
          selectedIconTheme: IconThemeData(color: theme.primaryColor),
          unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          selectedLabelTextStyle: context.typography.navigationLabel.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelTextStyle: context.typography.navigationLabel.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          destinations: const [
            NavigationRailDestination(icon: Icon(LucideIcons.layoutDashboard), label: Text('Home')),
            NavigationRailDestination(icon: Icon(LucideIcons.fileText), label: Text('Invoices')),
            NavigationRailDestination(icon: Icon(LucideIcons.file), label: Text('Quotes')),
            NavigationRailDestination(icon: Icon(LucideIcons.users), label: Text('Clients')),
            NavigationRailDestination(icon: Icon(LucideIcons.user), label: Text('Profile')),
          ],
        ),
        VerticalDivider(thickness: 1, width: 1, color: theme.colorScheme.outline),
        Expanded(child: ClipRRect(child: activeScreen)),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Widget activeScreen, MainLayoutController controller) {
    return Row(
      children: [
        _buildResponsiveSidebar(context, controller),
        Expanded(child: ClipRRect(child: activeScreen)),
      ],
    );
  }

  // Floating Bottom Navigation Nav Item (Mobile view)
  Widget _buildBottomNavItem(
    int index,
    IconData icon,
    String label,
    MainLayoutController controller,
    double barHeight,
  ) {
    return GestureDetector(
      onTap: () => controller.changeIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final isSelected = controller.currentIndex.value == index;
        // Scale icon/font proportionally with barHeight
        final iconSize = (barHeight * 0.33).clamp(18.0, 24.0);
        final fontSize = (barHeight * 0.165).clamp(10.0, 13.0);
        final pillH = (barHeight * 0.68).clamp(38.0, 52.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          height: pillH,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 10,
            vertical: 0,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                  size: iconSize,
                ),
              ),
              // Animated gap + label appear for selected only
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isSelected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: isSelected ? 6 : 0),
                          AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: fontSize,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
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
  Widget _buildResponsiveSidebar(
    BuildContext context,
    MainLayoutController controller,
  ) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
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
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.hexagon,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.heading2.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    children: const [
                      TextSpan(text: 'Auriva'),
                      TextSpan(
                        text: 'BMS',
                        style: TextStyle(color: AppColors.primary),
                      ),
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
                _buildSidebarMenuItem(
                  context,
                  0,
                  'Dashboard',
                  LucideIcons.layoutDashboard,
                  controller,
                ),
                _buildSidebarMenuItem(
                  context,
                  1,
                  'Invoices',
                  LucideIcons.fileText,
                  controller,
                ),
                _buildSidebarMenuItem(
                  context,
                  2,
                  'Quotations',
                  LucideIcons.file,
                  controller,
                ),
                _buildSidebarMenuItem(
                  context,
                  3,
                  'Clients',
                  LucideIcons.users,
                  controller,
                ),
                _buildSidebarMenuItem(
                  context,
                  4,
                  'Profile',
                  LucideIcons.user,
                  controller,
                ),
              ],
            ),
          ),

          // Footer with Sign Out Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.logOut,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
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
  Widget _buildSidebarMenuItem(
    BuildContext context,
    int index,
    String title,
    IconData icon,
    MainLayoutController controller,
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
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
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
                  color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: AppColors.primary.withOpacity(0.6),
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

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
import '../core/services/permission_manager.dart';
import '../features/invoices/create_invoice_screen.dart';
import '../features/quotations/create_quotation_screen.dart';
import 'app_routes.dart';
import 'widgets/auriva_expandable_fab.dart';

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
    // 7.5% of screen height, clamped 60-74px
    final barHeight = (screenHeight * 0.078).clamp(60.0, 74.0);
    // Add extra padding for the bottom bar so content isn't obscured
    final isProfileTab = controller.currentIndex.value == 4;
    final paddedScreen = Padding(
      padding: EdgeInsets.only(bottom: isProfileTab ? 0 : barHeight),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Container(
          key: ValueKey<int>(controller.currentIndex.value),
          child: activeScreen,
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          paddedScreen,
          
          // Floating Bottom Navigation Bar
          if (!isProfileTab)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Container(
                  height: barHeight,
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBottomNavItem(context, 0, LucideIcons.layoutGrid, 'Dashboard', controller, barHeight),
                      _buildBottomNavItem(context, 1, LucideIcons.fileText, 'Invoice', controller, barHeight),
                      // Space for FAB
                      const SizedBox(width: 76),
                      _buildBottomNavItem(context, 2, LucideIcons.file, 'Quote', controller, barHeight),
                      _buildBottomNavItem(context, 4, LucideIcons.user, 'Profile', controller, barHeight),
                    ],
                  ),
                ),
              ),
            ),
          
          // Center Expandable FAB overlay
          if (!isProfileTab)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: 0,
              child: SafeArea(
                child: AurivaExpandableFab(
                  distance: 130.0,
                  actions: [
                    AurivaFabAction(
                      icon: LucideIcons.filePlus,
                      label: 'New Invoice',
                      onPressed: () => Get.to(() => const CreateInvoiceScreen()),
                    ),
                    AurivaFabAction(
                      icon: LucideIcons.tag,
                      label: 'New Quote',
                      onPressed: () => Get.to(() => const CreateQuotationScreen()),
                    ),
                    AurivaFabAction(
                      icon: LucideIcons.users,
                      label: 'Client',
                      onPressed: () => Get.to(() => const ClientsScreen()),
                    ),
                    AurivaFabAction(
                      icon: LucideIcons.wallet,
                      label: 'Expenses',
                      onPressed: () => Get.toNamed(AppRoutes.expenses),
                    ),
                    AurivaFabAction(
                      icon: LucideIcons.package,
                      label: 'Inventory',
                      onPressed: () => Get.toNamed(AppRoutes.inventory),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
    BuildContext context,
    int index,
    IconData icon,
    String label,
    MainLayoutController controller,
    double barHeight,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Obx(() {
          final isSelected = controller.currentIndex.value == index;
          // Keep icon and font sizes proportional but clean
          final iconSize = (barHeight * 0.32).clamp(18.0, 22.0);
          final fontSize = (barHeight * 0.16).clamp(10.0, 12.0);

          return Container(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              width: isSelected ? 76 : 60, // Fixed width that gives breathing room to the text
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), // Generous padding so it doesn't look glued
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    child: Icon(
                      icon,
                      color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF64748B),
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 280),
                    style: context.typography.navigationLabel.copyWith(
                      color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: fontSize,
                    ),
                    child: Text(label, maxLines: 1, overflow: TextOverflow.visible),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
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
                        color: context.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.hexagon,
                    size: 32,
                    color: context.colorScheme.primary,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: context.typography.profileName.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      const TextSpan(text: 'Auriva'),
                      TextSpan(
                        text: 'BMS',
                        style: context.typography.profileName.copyWith(color: context.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BUSINESS MANAGEMENT SYSTEM',
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
                      style: context.typography.buttonText.copyWith(
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
                  color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: context.typography.inputText.copyWith(
                    color: isActive ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: context.colorScheme.primary.withValues(alpha: 0.6),
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

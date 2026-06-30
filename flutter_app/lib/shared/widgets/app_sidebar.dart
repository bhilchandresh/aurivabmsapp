import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF1E293B), // slate-800
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.only(
              top: 60,
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
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
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
                      color: Colors.white,
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(
                  context,
                  'Dashboard',
                  '/dashboard',
                  LucideIcons.layoutDashboard,
                ),
                _buildMenuItem(
                  context,
                  'Invoices',
                  '/invoices',
                  LucideIcons.fileText,
                ),
                _buildMenuItem(
                  context,
                  'Quotations',
                  '/quotations',
                  LucideIcons.file,
                ),
                _buildMenuItem(
                  context,
                  'Clients',
                  '/clients',
                  LucideIcons.users,
                ),
                _buildMenuItem(
                  context,
                  'Inventory',
                  '/inventory',
                  LucideIcons.package,
                ),
                _buildMenuItem(
                  context,
                  'Suppliers',
                  '/suppliers',
                  LucideIcons.truck,
                ),
                _buildMenuItem(
                  context,
                  'Expenses',
                  '/expenses',
                  LucideIcons.wallet,
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'admin'.tr,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Team & Access',
                  '/team',
                  LucideIcons.shieldCheck,
                ),
                _buildMenuItem(
                  context,
                  'Settings',
                  '/settings',
                  LucideIcons.settings,
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade800)),
            ),
            child: InkWell(
              onTap: () {
                // Logout logic
                Get.offAllNamed('/login');
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
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
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

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String route,
    IconData icon,
  ) {
    final isActive = currentRoute.startsWith(route);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          Scaffold.of(context).closeDrawer();
          Get.toNamed(route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
                color: isActive ? Colors.white : Colors.grey.shade500,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.label.copyWith(
                  color: isActive ? Colors.white : Colors.grey.shade300,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Icon(
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
  }
}

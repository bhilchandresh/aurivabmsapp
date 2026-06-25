import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../auth/auth_controller.dart';
import '../widgets/super_admin_top_bar.dart';
import '../logs/super_admin_logs_screen.dart';
import '../broadcast/super_admin_broadcast_screen.dart';
import '../notifications/super_admin_notifications_screen.dart';

class SuperAdminProfileScreen extends StatelessWidget {
  const SuperAdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Code-generated Logo Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              color: const Color(0xFF1E293B), // Dark background from screenshot
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
                  // AurivaBMS Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Auriva',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'BMS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'BUSINESS MANAGEMENT SYSTEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Super Admin Data
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildProfileItem(
                                  icon: LucideIcons.user,
                                  title: 'Name',
                                  value: 'Super Admin',
                                  showBorder: true,
                                ),
                                _buildProfileItem(
                                  icon: LucideIcons.shieldCheck,
                                  title: 'Access Level',
                                  value: 'Root / Full Control',
                                  showBorder: false,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Notifications & Settings
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildSettingAction(
                                  icon: LucideIcons.bellRing,
                                  title: 'Notifications',
                                  showBorder: true,
                                  onTap: () => Get.to(() => const SuperAdminNotificationsScreen()),
                                ),
                                _buildSettingAction(
                                  icon: LucideIcons.history,
                                  title: 'System Logs',
                                  showBorder: true,
                                  onTap: () => Get.to(() => const SuperAdminLogsScreen()),
                                ),
                                _buildSettingAction(
                                  icon: LucideIcons.mail,
                                  title: 'Email Config (SMTP)',
                                  showBorder: false,
                                  onTap: () => Get.to(() => const SuperAdminBroadcastScreen(initialIndex: 1)),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final authController = Get.find<AuthController>();
                                authController.logout();
                              },
                              icon: const Icon(LucideIcons.logOut, size: 20),
                              label: const Text(
                                'Secure Logout',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade600,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.red.shade200),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({required IconData icon, required String title, required String value, required bool showBorder}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
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
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingAction({required IconData icon, required String title, required bool showBorder, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.grey.shade600, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

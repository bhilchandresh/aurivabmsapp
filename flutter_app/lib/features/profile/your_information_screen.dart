import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_extensions.dart';
import '../auth/auth_controller.dart';

class YourInformationScreen extends StatelessWidget {
  const YourInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardBgColor = Theme.of(context).cardTheme.color ?? (isDark ? Colors.grey.shade900 : Colors.white);
    final topCardBg = Theme.of(context).cardTheme.color ?? (isDark ? Colors.grey.shade900 : const Color(0xFFEAF1FF));
    final textColor = Theme.of(context).textTheme.displayLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'your_information'.tr,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Profile Card
              _buildTopProfileCard(context, authController, topCardBg, textColor),
              
              const SizedBox(height: 32),

              // "PERSONAL DETAILS"
              Text(
                'PERSONAL DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 16),

              // Details List Card
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? Border.all(color: Colors.white10) : null,
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      iconAsset: 'assets/SVG/profile.svg',
                      iconBg: isDark ? const Color(0xFFEBF3FF).withValues(alpha: 0.1) : const Color(0xFFEBF3FF),
                      iconColor: const Color(0xFF3B82F6),
                      value: authController.userName.value.isNotEmpty ? authController.userName.value : 'Shukan',
                      textColor: textColor,
                    ),
                    _buildDivider(isDark),
                    _buildDetailRow(
                      context,
                      iconAsset: 'assets/SVG/mail.svg',
                      iconBg: isDark ? const Color(0xFFEBF3FF).withValues(alpha: 0.1) : const Color(0xFFEBF3FF),
                      iconColor: const Color(0xFF3B82F6),
                      value: authController.userEmail.value.isNotEmpty ? authController.userEmail.value : 'demo@auriva.in',
                      textColor: textColor,
                    ),

                    _buildDivider(isDark),
                    _buildDetailRow(
                      context,
                      iconAsset: 'assets/SVG/teamandaccess.svg',
                      iconBg: isDark ? const Color(0xFFFEF3C7).withValues(alpha: 0.1) : const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFF59E0B),
                      value: authController.userRole.value.isNotEmpty ? authController.userRole.value.toUpperCase() : 'ADMIN',
                      textColor: textColor,
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProfileCard(BuildContext context, AuthController authController, Color bgColor, Color textColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            bottom: -30,
            child: Icon(
              LucideIcons.hexagon,
              size: 160,
              color: Colors.blue.shade400.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
            children: [
              // Avatar
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B7FFF), Color(0xFF9055FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B7FFF).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Obx(() {
                    final name = authController.userName.value;
                    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
                    return Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 20),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => Text(
                      authController.userName.value.isNotEmpty ? authController.userName.value : 'Shukan',
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    )),
                    const SizedBox(height: 6),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        authController.userRole.value.isNotEmpty ? authController.userRole.value.toUpperCase() : 'ADMIN',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.blue.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconText(IconData icon, String text, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String iconAsset,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? iconColor.withValues(alpha: 0.15) : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.white10 : Colors.grey.shade100,
      ),
    );
  }
}

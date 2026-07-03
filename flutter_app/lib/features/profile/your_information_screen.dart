import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_extensions.dart';
import '../auth/auth_controller.dart';

class YourInformationScreen extends StatelessWidget {
  const YourInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar:
          true, // Make app bar transparent to show background
      appBar: AppBar(
        title: Text(
          'your_information'.tr,
          style: context.typography.topBarTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Theme.of(context).textTheme.displayLarge?.color,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Get.back(),
        ),
      ),
      body: FloatingBlobsBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Premium Avatar Animation
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Obx(() {
                          final name = authController.userName.value;
                          final initial = name.isNotEmpty
                              ? name[0].toUpperCase()
                              : 'U';
                          return Text(
                            initial,
                            style: context.typography.avatarLetter.copyWith(
                              fontSize: 50,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name Header
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Obx(
                    () => Text(
                      authController.userName.value.isNotEmpty
                          ? authController.userName.value
                          : 'my_account'.tr,
                      style: context.typography.profileName.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.displayLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        authController.userRole.value.toUpperCase(),
                          style: context.typography.roleBadgeText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF8B5CF6),
                            letterSpacing: 1.5,
                          ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Info Cards with Glassmorphism
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Obx(
                    () => _buildGlassProfileItem(
                      context: context,
                      icon: LucideIcons.user,
                      title: 'full_name'.tr,
                      value: authController.userName.value.isNotEmpty
                          ? authController.userName.value
                          : 'my_account'.tr,
                      iconColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Obx(() {
                  if (authController.userEmail.value.isNotEmpty) {
                    return FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: _buildGlassProfileItem(
                        context: context,
                        icon: LucideIcons.mail,
                        title: 'email_address'.tr,
                        value: authController.userEmail.value,
                        iconColor: const Color(0xFFF59E0B),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 16),

                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Obx(
                    () => _buildGlassProfileItem(
                      context: context,
                      icon: LucideIcons.shieldCheck,
                      title: 'access_level'.tr,
                      value: authController.userRole.value.isNotEmpty
                          ? authController.userRole.value.toUpperCase()
                          : 'user_role_default'.tr,
                      iconColor: const Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassProfileItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(
          alpha: 0.6,
        ), // Glassmorphism translucent base
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typography.inputLabel.copyWith(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: context.typography.inputText.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- GLASSMORPHISM ANIMATED BACKGROUND ---

class FloatingBlobsBackground extends StatefulWidget {
  final Widget child;
  const FloatingBlobsBackground({super.key, required this.child});
  @override
  State<FloatingBlobsBackground> createState() =>
      _FloatingBlobsBackgroundState();
}

class _FloatingBlobsBackgroundState extends State<FloatingBlobsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background color
        Container(color: Theme.of(context).scaffoldBackgroundColor),

        // Animated Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.1 +
                      100 * math.sin(_controller.value * 2 * math.pi),
                  left: -50 + 100 * math.cos(_controller.value * 2 * math.pi),
                  child: _buildBlob(
                    const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    350,
                  ),
                ),
                Positioned(
                  bottom:
                      MediaQuery.of(context).size.height * 0.2 +
                      80 * math.cos(_controller.value * 2 * math.pi),
                  right: -50 + 80 * math.sin(_controller.value * 2 * math.pi),
                  child: _buildBlob(
                    const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    300,
                  ),
                ),
                Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.4 +
                      60 * math.cos(_controller.value * 2 * math.pi),
                  right: 50 + 60 * math.sin(_controller.value * 2 * math.pi),
                  child: _buildBlob(
                    const Color(0xFFF43F5E).withValues(alpha: 0.2),
                    250,
                  ),
                ),
              ],
            );
          },
        ),

        // Glass Blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.1)),
          ),
        ),

        // Foreground content
        widget.child,
      ],
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// --- PREMIUM ENTRY ANIMATION HELPER ---

class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeInUp({super.key, required this.child, required this.delay});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

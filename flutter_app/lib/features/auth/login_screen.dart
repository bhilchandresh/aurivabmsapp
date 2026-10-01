import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'auth_controller.dart';
import 'view_legal_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _authController = Get.put(AuthController(), permanent: true);
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
//   final bool _isLoading = false;
  String? _errorMessage;

  // Background floating blobs animations
  late AnimationController _bgAnimationController;
  late Animation<double> _bgAnimation;

  // Intro staggering animations
  late AnimationController _introController;

  @override
  void initState() {
    super.initState();

    // Ambient background drift animation
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );

    // Fade/Slide intro animation for the elements
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _introController.forward();
  }

  void _handleLogin() async {
    if (_authController.isLoading.value) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });


    final success = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!success && mounted) {
      setState(() {
        _errorMessage = 'invalid_credentials'.tr;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgAnimationController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required String iconAsset,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9);
    final iconBgColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  obscureText: isPassword && !_showPassword,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: isPassword && !_showPassword ? 4 : 0,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          if (isPassword)
            IconButton(
              icon: SvgPicture.asset(
                _showPassword ? 'assets/SVG/eyeview.svg' : 'assets/SVG/eyehide.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: baseBgColor,
      body: Stack(
        children: [
          // 1. Flowing Ambient Background blobs
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) {
              final val = _bgAnimation.value;
              return Stack(
                children: [
                  Positioned(
                    top: -120 + (val * 140),
                    left: -100 + (val * 80),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE0E7FF)).withValues(alpha: isDark ? 0.3 : 0.8),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150 + (val * 160),
                    right: -120 + (val * 100),
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? const Color(0xFF4C1D95) : const Color(0xFFF3E8FF)).withValues(alpha: isDark ? 0.2 : 0.8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // High-blur backdrop for smooth gradients
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Lottie & Title
                      StaggeredFadeSlide(
                        controller: _introController,
                        delay: 0.0,
                        child: Column(
                          children: [
                            Lottie.asset(
                              'assets/lottie/business_analytics.json', 
                              height: 220,
                              width: 300,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Lottie Error: $error');
                                return Container(
                                  height: 220,
                                  width: 300,
                                  color: Colors.red.withValues(alpha: 0.1),
                                  child: Center(child: Text('Lottie Error: $error', style: const TextStyle(color: Colors.red))),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600, // Reduced Auriva weight slightly
                                  color: textColor,
                                  letterSpacing: -0.5,
                                  fontFamily: 'Inter',
                                ),
                                children: const [
                                  TextSpan(text: 'Auriva'),
                                  TextSpan(
                                    text: 'BMS',
                                    style: TextStyle(color: Color(0xFF5B61F4), fontWeight: FontWeight.w900), // Made BMS super bold
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Business Management System',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtextColor,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Error Banner
                      if (_errorMessage != null)
                        StaggeredFadeSlide(
                          controller: _introController,
                          delay: 0.1,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50,
                              border: Border(left: BorderSide(color: Colors.red.shade500, width: 4)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.alertTriangle, color: Colors.red.shade500, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            StaggeredFadeSlide(
                              controller: _introController,
                              delay: 0.15,
                              child: _buildCustomTextField(
                                label: 'Email',
                                hint: 'name@company.com',
                                iconAsset: 'assets/SVG/mail.svg',
                                controller: _emailController,
                              ),
                            ),
                            const SizedBox(height: 12),
                            StaggeredFadeSlide(
                              controller: _introController,
                              delay: 0.25,
                              child: _buildCustomTextField(
                                label: 'Password',
                                hint: '••••••••',
                                iconAsset: 'assets/SVG/lock.svg',
                                controller: _passwordController,
                                isPassword: true,
                              ),
                            ),
                            const SizedBox(height: 24),
                            StaggeredFadeSlide(
                              controller: _introController,
                              delay: 0.35,
                              child: Obx(() {
                                final isLoading = _authController.isLoading.value;
                                return Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF5B61F4), Color(0xFF7C5CFC)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5B61F4).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Sign In to Dashboard",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
                                            ],
                                          ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // OR Divider
                      StaggeredFadeSlide(
                        controller: _introController,
                        delay: 0.40,
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: subtextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer
                      StaggeredFadeSlide(
                        controller: _introController,
                        delay: 0.45,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/SVG/shield.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(Color(0xFF5B61F4), BlendMode.srcIn),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Protected by Enterprise Security.",
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "© 2026 Auriva Solutions. All rights reserved.",
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Get.to(() => const ViewLegalScreen(
                                      title: 'Privacy Policy',
                                      documentType: 'privacy_policy',
                                    ));
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Privacy Policy",
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.blueGrey.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  " • ",
                                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.to(() => const ViewLegalScreen(
                                      title: 'Terms & Conditions',
                                      documentType: 'terms_and_conditions',
                                    ));
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Terms & Conditions",
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.blueGrey.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Staggered Entry Animation Helper Widget
class StaggeredFadeSlide extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const StaggeredFadeSlide({
    required this.controller,
    required this.delay,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay,
        (delay + 0.45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

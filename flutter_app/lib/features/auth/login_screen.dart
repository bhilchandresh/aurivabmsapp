import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_input_field.dart';
import 'auth_controller.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final bool _isLoading = false;
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    // Request permissions at login
    try {
      await [
        Permission.camera,
        Permission.storage,
        Permission.photos,
      ].request();
    } catch (e) {
      debugPrint('Permission request error: $e');
    }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic theme colors
    final baseBgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardBgColor = Theme.of(context).cardTheme.color?.withOpacity(0.65) ?? Colors.white.withOpacity(0.8);
    final cardBorderColor = Theme.of(context).colorScheme.outline;
    final textColor = Theme.of(context).textTheme.displayLarge?.color;
    final subtextColor = Theme.of(context).textTheme.bodyMedium?.color;
    final logoBgColor = Theme.of(context).colorScheme.surfaceContainerHighest;

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
                        color:
                            (isDark
                                    ? Color(0xFF1E3A8A)
                                    : Color(0xFFBFDBFE))
                                .withOpacity(isDark ? 0.35 : 0.45),
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
                        color:
                            (isDark
                                    ? Color(0xFF4C1D95)
                                    : Color(0xFFE9D5FF))
                                .withOpacity(isDark ? 0.3 : 0.4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. High-blur backdrop for background glow
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.transparent),
            ),
          ),
          // 4. Centered Interactive Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBorderColor, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.25 : 0.05,
                            ),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top accent line
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 36,
                            ),
                            child: Column(
                              children: [
                                // Brand Header with staggered entry
                                StaggeredFadeSlide(
                                  controller: _introController,
                                  delay: 0.0,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: logoBgColor,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(
                                                    isDark ? 0.3 : 0.1,
                                                  ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            LucideIcons.hexagon,
                                            color: AppColors.primary,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      RichText(
                                        text: TextSpan(
                                          style: AppTextStyles.heading1
                                              .copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.5,
                                              ),
                                          children: const [
                                            TextSpan(text: 'Auriva'),
                                            TextSpan(
                                              text: 'BMS',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'bms_subtitle'.tr,
                                        style: AppTextStyles.label.copyWith(
                                          color: subtextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Error Banner
                                if (_errorMessage != null)
                                  StaggeredFadeSlide(
                                    controller: _introController,
                                    delay: 0.1,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 24),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.red.shade900.withOpacity(
                                                0.3,
                                              )
                                            : Colors.red.shade50,
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.red.shade500,
                                            width: 4,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.alertTriangle,
                                            color: Colors.red.shade500,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.red.shade200
                                                    : Colors.red.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Login Form
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      StaggeredFadeSlide(
                                        controller: _introController,
                                        delay: 0.15,
                                        child: AppInputField(
                                          label: 'work_email'.tr,
                                          hintText: 'name_company_com'.tr,
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          prefixIcon: Icon(
                                            LucideIcons.mail,
                                            size: 20,
                                          ),
                                          validator: (val) =>
                                              val == null || val.isEmpty
                                              ? 'email_req'.tr
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      StaggeredFadeSlide(
                                        controller: _introController,
                                        delay: 0.25,
                                        child: AppInputField(
                                          label: 'password'.tr,
                                          hintText: '••••••••',
                                          controller: _passwordController,
                                          obscureText: !_showPassword,
                                          prefixIcon: Icon(
                                            LucideIcons.lock,
                                            size: 20,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _showPassword
                                                  ? LucideIcons.eyeOff
                                                  : LucideIcons.eye,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                              () => _showPassword =
                                                  !_showPassword,
                                            ),
                                          ),
                                          validator: (val) =>
                                              val == null || val.isEmpty
                                              ? 'password_req'.tr
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      StaggeredFadeSlide(
                                        controller: _introController,
                                        delay: 0.35,
                                        child: Obx(
                                          () => AppButton(
                                            text: 'sign_in_btn'.tr,
                                            isLoading:
                                                _authController.isLoading.value,
                                            onPressed: _handleLogin,
                                            icon: Icon(
                                              LucideIcons.arrowRight,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                StaggeredFadeSlide(
                                  controller: _introController,
                                  delay: 0.45,
                                  child: Column(
                                    children: [
                                      Divider(color: cardBorderColor),
                                      const SizedBox(height: 20),
                                      Text(
                                        'protected_by_security'.tr,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.caption.copyWith(
                                          color: subtextColor,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
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

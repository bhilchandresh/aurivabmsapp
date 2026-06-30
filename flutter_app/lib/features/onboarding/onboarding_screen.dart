import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Get.find<AuthController>().completeOnboarding();
    }
  }

  void _onSkip() {
    Get.find<AuthController>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBgColor = isDark
        ? Color(0xFF090D1A)
        : Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: baseBgColor,
      body: Stack(
        children: [
          // Background blobs
          _buildBackgroundBlobs(isDark),

          // Blur layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top header: Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentPage < 2)
                        TextButton(
                          onPressed: _onSkip,
                          child: Text(
                            'skip'.tr,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    physics: const BouncingScrollPhysics(),
                    children: const [_Slide1(), _Slide2(), _Slide3()],
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(
                          3,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppColors.primary
                                  : (isDark ? Colors.white24 : Colors.black12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Next / Get Started Button
                      GestureDetector(
                        onTap: _onNext,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            horizontal: _currentPage == 2 ? 24 : 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_currentPage == 2)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    'get_started'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              Icon(
                                _currentPage == 2
                                    ? LucideIcons.check
                                    : LucideIcons.arrowRight,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildBackgroundBlobs(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  (isDark ? Color(0xFF1E3A8A) : Color(0xFFBFDBFE))
                      .withOpacity(0.4),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  (isDark ? Color(0xFF4C1D95) : Color(0xFFE9D5FF))
                      .withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// Slide 1: Analytics / Dashboard
// ---------------------------------------------------------
class _Slide1 extends StatefulWidget {
  const _Slide1();

  @override
  State<_Slide1> createState() => _Slide1State();
}

class _Slide1State extends State<_Slide1> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Graphic
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main chart card
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    final scale = Tween<double>(begin: 0.5, end: 1.0)
                        .animate(
                          CurvedAnimation(
                            parent: _ctrl,
                            curve: Curves.easeOutBack,
                          ),
                        )
                        .value;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 200,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBar(
                                  100,
                                  AppColors.primary.withOpacity(0.5),
                                  0.2,
                                ),
                                _buildBar(
                                  140,
                                  AppColors.primary.withOpacity(0.7),
                                  0.4,
                                ),
                                _buildBar(
                                  80,
                                  AppColors.primary.withOpacity(0.4),
                                  0.6,
                                ),
                                _buildBar(180, AppColors.primary, 0.8),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Floating elements
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    final slide = Tween<double>(begin: 50, end: 0)
                        .animate(
                          CurvedAnimation(
                            parent: _ctrl,
                            curve: const Interval(
                              0.4,
                              1.0,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                        )
                        .value;
                    final fade = Tween<double>(begin: 0, end: 1)
                        .animate(
                          CurvedAnimation(
                            parent: _ctrl,
                            curve: const Interval(
                              0.4,
                              1.0,
                              curve: Curves.easeIn,
                            ),
                          ),
                        )
                        .value;

                    return Positioned(
                      top: 40,
                      right: 10,
                      child: Opacity(
                        opacity: fade,
                        child: Transform.translate(
                          offset: Offset(0, slide),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981), // Success green
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(
                                    0xFF10B981,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              LucideIcons.trendingUp,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'smart_dashboard'.tr,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.displayLarge?.color,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'smart_dashboard_desc'.tr,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.grey.shade400 : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color, double delay) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final val = Tween<double>(begin: 0, end: 1)
            .animate(
              CurvedAnimation(
                parent: _ctrl,
                curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
              ),
            )
            .value;
        return Container(
          width: 24,
          height: height * val,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// Slide 2: Inventory & Suppliers
// ---------------------------------------------------------
class _Slide2 extends StatefulWidget {
  const _Slide2();

  @override
  State<_Slide2> createState() => _Slide2State();
}

class _Slide2State extends State<_Slide2> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildFloatingBox(
                  icon: LucideIcons.packageSearch,
                  color: Color(0xFFF59E0B),
                  x: -60,
                  y: -40,
                  delay: 0.1,
                  isDark: isDark,
                  size: 90,
                ),
                _buildFloatingBox(
                  icon: LucideIcons.truck,
                  color: Color(0xFF3B82F6),
                  x: 60,
                  y: 0,
                  delay: 0.3,
                  isDark: isDark,
                  size: 110,
                ),
                _buildFloatingBox(
                  icon: LucideIcons.boxes,
                  color: Color(0xFF8B5CF6),
                  x: -30,
                  y: 60,
                  delay: 0.5,
                  isDark: isDark,
                  size: 80,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'manage_inventory_onboarding'.tr,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.displayLarge?.color,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'manage_inventory_desc'.tr,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.grey.shade400 : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBox({
    required IconData icon,
    required Color color,
    required double x,
    required double y,
    required double delay,
    required bool isDark,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = Tween<double>(begin: 0, end: 1)
            .animate(
              CurvedAnimation(
                parent: _ctrl,
                curve: Interval(delay, 1.0, curve: Curves.elasticOut),
              ),
            )
            .value;

        return Transform.translate(
          offset: Offset(x, y),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: color, size: size * 0.4),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// Slide 3: Seamless Invoicing
// ---------------------------------------------------------
class _Slide3 extends StatefulWidget {
  const _Slide3();

  @override
  State<_Slide3> createState() => _Slide3State();
}

class _Slide3State extends State<_Slide3> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Invoice Document
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    final slide = Tween<double>(begin: 100, end: 0)
                        .animate(
                          CurvedAnimation(
                            parent: _ctrl,
                            curve: const Interval(
                              0.1,
                              0.7,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                        )
                        .value;
                    return Transform.translate(
                      offset: Offset(0, slide),
                      child: Container(
                        width: 180,
                        height: 240,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Logo Placeholder
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    LucideIcons.fileText,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                // Invoice Text & Date
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'invoice_caps'.tr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Bill To Block
                            Container(
                              width: 30,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 80,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 50,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Table Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Item 1
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 90,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Container(
                                  width: 30,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Item 2
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 60,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Container(
                                  width: 30,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Divider
                            Divider(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              height: 16,
                            ),
                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'total'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '₹24,500',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Glowing Checkmark
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    final scale = Tween<double>(begin: 0, end: 1)
                        .animate(
                          CurvedAnimation(
                            parent: _ctrl,
                            curve: const Interval(
                              0.6,
                              1.0,
                              curve: Curves.elasticOut,
                            ),
                          ),
                        )
                        .value;
                    return Positioned(
                      bottom: 10,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.checkCheck,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'seamless_invoicing'.tr,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.displayLarge?.color,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'seamless_invoicing_desc'.tr,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.grey.shade400 : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_extensions.dart';

class AurivaFabAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  AurivaFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

class AurivaExpandableFab extends StatefulWidget {
  final List<AurivaFabAction> actions;
  final double distance;
  final VoidCallback? onToggle;

  const AurivaExpandableFab({
    super.key,
    required this.actions,
    this.distance = 120.0,
    this.onToggle,
  });

  @override
  State<AurivaExpandableFab> createState() => _AurivaExpandableFabState();
}

class _AurivaExpandableFabState extends State<AurivaExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    if (widget.onToggle != null) {
      widget.onToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate safe layout bounds
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Ensure the maximum distances clear the screen edges and bottom navigation
        // Subtract horizontal padding to avoid clipping long text (e.g. 60px safe margin)
        final maxHorizontalDistance = math.min((screenWidth / 2) - 60, 140.0);
        
        // Max vertical distance: assume bottom nav is ~80px tall, FAB is ~68px, safe area ~30px.
        // Screen height - ~180px reserved at bottom = safe vertical expansion area.
        final maxVerticalDistance = math.min(screenHeight - 180.0, 280.0).clamp(160.0, 320.0);

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Background overlay to dim when opened
            if (_isOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _expandAnimation.value * 3.0, // reduced blur for a subtle effect
                          sigmaY: _expandAnimation.value * 3.0,
                        ),
                        child: Container(
                          color: Colors.white.withValues(alpha: _expandAnimation.value * 0.55), // lighter overlay
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            // Render connecting lines
            Positioned.fill(
              child: IgnorePointer(
                child: _buildConnectingLines(maxHorizontalDistance, maxVerticalDistance),
              ),
            ),
            
            // Render action buttons
            ..._buildExpandingActionButtons(maxHorizontalDistance, maxVerticalDistance),
            
            // Render center FAB
            _buildTapToOpenFab(),
          ],
        );
      }
    );
  }

  Widget _buildConnectingLines(double maxHoriz, double maxVert) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _DashedLinesPainter(
            progress: _expandAnimation.value,
            maxHorizontalDistance: maxHoriz,
            maxVerticalDistance: maxVert,
            count: widget.actions.length,
          ),
        );
      },
    );
  }

  List<Widget> _buildExpandingActionButtons(double maxHoriz, double maxVert) {
    final children = <Widget>[];
    final count = widget.actions.length;
    
    // Strict 3-Row Symmetrical Layout
    // Origin (0,0) is the FAB center.
    final positions = [
      const _ActionCoordinate(-1.0, 0.32), // 0: New Invoice (Row 3, Left)
      const _ActionCoordinate(-0.45, 0.66),// 1: New Quote (Row 2, Left)
      const _ActionCoordinate(0.0, 1.0),   // 2: Client (Row 1, Center)
      const _ActionCoordinate(0.45, 0.66), // 3: Expense (Row 2, Right)
      const _ActionCoordinate(1.0, 0.32),  // 4: Inventory (Row 3, Right)
    ];

    // Stagger delays based on visual hierarchy:
    // Client: 0ms, New Quote: 40ms, Expense: 60ms, New Invoice: 80ms, Inventory: 100ms
    final staggerDelays = [80.0, 40.0, 0.0, 60.0, 100.0];

    for (var i = 0; i < count; i++) {
      final staggerStart = staggerDelays[i] / 350.0;
      final itemAnimation = CurvedAnimation(
        parent: _controller,
        curve: Interval(
          staggerStart,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      );

      children.add(
        _ExpandingActionButton(
          coordinate: positions[i % positions.length],
          maxHorizontalDistance: maxHoriz,
          maxVerticalDistance: maxVert,
          progress: itemAnimation,
          action: widget.actions[i],
          onClose: _toggle,
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 12,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _expandAnimation.value * math.pi * 0.25, // rotate 45 degrees
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withRed(120), // slight purple gradient
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashedLinesPainter extends CustomPainter {
  final double progress;
  final double maxHorizontalDistance;
  final double maxVerticalDistance;
  final int count;

  _DashedLinesPainter({
    required this.progress,
    required this.maxHorizontalDistance,
    required this.maxVerticalDistance,
    required this.count,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: progress)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // The FAB is situated at bottom: 12 in the Stack. FAB height is 68.
    // Therefore, FAB center is 12 + 34 = 46px from the bottom.
    final center = Offset(size.width / 2, size.height - 46);

    final positions = [
      const _ActionCoordinate(-1.0, 0.32),
      const _ActionCoordinate(-0.45, 0.66),
      const _ActionCoordinate(0.0, 1.0),
      const _ActionCoordinate(0.45, 0.66),
      const _ActionCoordinate(1.0, 0.32),
    ];

    for (var i = 0; i < count; i++) {
      final pos = positions[i % positions.length];
      
      final targetDx = pos.dx * maxHorizontalDistance * progress;
      final targetDy = pos.dy * maxVerticalDistance * progress;
      
      // Y decreases as it goes up the screen
      final target = Offset(center.dx + targetDx, center.dy - targetDy);
      _drawDashedLine(canvas, center, target, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    
    var distance = (p2 - p1).distance;
    var direction = (p2 - p1) / distance;
    
    var currentDistance = 24.0; // Start lines outside the FAB radius
    while (currentDistance < distance) {
      final start = p1 + direction * currentDistance;
      currentDistance += dashWidth;
      final end = p1 + direction * (currentDistance < distance ? currentDistance : distance);
      canvas.drawLine(start, end, paint);
      currentDistance += dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ExpandingActionButton extends StatelessWidget {
  final _ActionCoordinate coordinate;
  final double maxHorizontalDistance;
  final double maxVerticalDistance;
  final Animation<double> progress;
  final AurivaFabAction action;
  final VoidCallback onClose;

  const _ExpandingActionButton({
    required this.coordinate,
    required this.maxHorizontalDistance,
    required this.maxVerticalDistance,
    required this.progress,
    required this.action,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final targetDx = coordinate.dx * maxHorizontalDistance * progress.value;
        final targetDy = coordinate.dy * maxVerticalDistance * progress.value;
        
        // Map 0.0 -> 1.0 progress to 0.6 -> 1.0 scale as requested
        final scale = 0.6 + (progress.value * 0.4);
        
        return Positioned(
          bottom: 12 + 34 + targetDy, // Anchored mathematically to FAB center + target height
          left: (MediaQuery.of(context).size.width / 2) + targetDx,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0.5), // Perfectly centers the icon+label group over the target coordinate
            child: Opacity(
              opacity: progress.value,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (progress.status == AnimationStatus.reverse || progress.status == AnimationStatus.dismissed) return;
          onClose();
          action.onPressed();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, // Reduced from 54 as requested
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                action.icon,
                color: theme.colorScheme.primary,
                size: 24, // Optimized icon size
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                action.label,
                style: context.typography.navigationLabel.copyWith(
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCoordinate {
  final double dx;
  final double dy;
  const _ActionCoordinate(this.dx, this.dy);
}

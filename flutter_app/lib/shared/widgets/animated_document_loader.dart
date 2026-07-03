import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_extensions.dart';

class AnimatedDocumentLoader extends StatefulWidget {
  final String message;
  const AnimatedDocumentLoader({super.key, required this.message});

  @override
  State<AnimatedDocumentLoader> createState() => _AnimatedDocumentLoaderState();
}

class _AnimatedDocumentLoaderState extends State<AnimatedDocumentLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Animated glowing rings
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary.withValues(
                              alpha: 0.1 * _opacityAnimation.value,
                            ),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(
                                alpha: 0.3 * _opacityAnimation.value,
                              ),
                              width: 2,
                            ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            LucideIcons.fileText,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: context.typography.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please wait a moment while we process your request.",
                textAlign: TextAlign.center,
                style: context.typography.inputText.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 4,
                  width: 140,
                  child: LinearProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                     valueColor: AlwaysStoppedAnimation<Color>(
                       Theme.of(context).colorScheme.primary,
                     ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

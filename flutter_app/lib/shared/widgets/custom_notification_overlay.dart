import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class AurivaNotificationIcon extends StatelessWidget {
  final String type;
  const AurivaNotificationIcon({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    IconData mainIcon;
    IconData badgeIcon;
    
    if (type == 'payment' || type == 'invoice') {
      mainIcon = Icons.insert_drive_file_rounded;
      badgeIcon = Icons.add_rounded;
    } 
    if (type == 'payment') {
      mainIcon = Icons.account_balance_wallet_rounded;
      badgeIcon = Icons.currency_rupee_rounded;
    } else {
      mainIcon = Icons.insert_drive_file_rounded;
      badgeIcon = Icons.add_rounded;
    }

    const primaryBlue = Color(0xFF1D58F7);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 8, left: 8, child: _buildDot(primaryBlue)),
          Positioned(top: 8, right: 8, child: _buildDot(primaryBlue)),
          Positioned(bottom: 8, left: 8, child: _buildDot(primaryBlue)),
          Positioned(bottom: 8, right: 8, child: _buildDot(primaryBlue)),
          Icon(mainIcon, color: primaryBlue, size: 28),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(badgeIcon, color: Colors.white, size: 10),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }
}


class CustomNotificationOverlay {
  static OverlayEntry? _currentEntry;
  static final GlobalKey<_NotificationWidgetState> _widgetKey =
      GlobalKey<_NotificationWidgetState>();

  /// Shows the custom notification toast at the top of the screen.
  static void show({
    BuildContext? context,
    required String title,
    required String message,
    String? amount,
    String? invoiceNumber,
    String type = 'payment', // 'payment', 'invoice', 'success', etc.
  }) {
    final targetContext = context ?? Get.context;
    if (targetContext == null) return;

    // Dismiss existing notification before showing a new one
    dismiss(
      then: () {
        final overlayState = Overlay.of(targetContext);

        _currentEntry = OverlayEntry(
          builder: (ctx) => _NotificationWidget(
            key: _widgetKey,
            title: title,
            message: message,
            amount: amount,
            invoiceNumber: invoiceNumber,
            type: type,
            onRemove: () {
              _currentEntry?.remove();
              _currentEntry = null;
            },
          ),
        );

        overlayState.insert(_currentEntry!);
      },
    );
  }

  /// Animates the notification out and removes it.
  static void dismiss({VoidCallback? then}) {
    if (_currentEntry != null && _widgetKey.currentState != null) {
      _widgetKey.currentState!.dismiss(then: then);
    } else {
      _currentEntry?.remove();
      _currentEntry = null;
      then?.call();
    }
  }
}

class _NotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? amount;
  final String? invoiceNumber;
  final String type;
  final VoidCallback onRemove;

  const _NotificationWidget({
    super.key,
    required this.title,
    required this.message,
    this.amount,
    this.invoiceNumber,
    required this.type,
    required this.onRemove,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  static const Color _primaryBlue = Color(0xFF1D58F7);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation =
        Tween<Offset>(
          begin: const Offset(0, -1.2), // Start completely offscreen top
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack, // Nice springy entrance
          ),
        );

    _controller.forward();

    // Auto dismiss after 5 seconds
    _autoDismissTimer = Timer(const Duration(milliseconds: 5000), () {
      dismiss();
    });
  }

  void dismiss({VoidCallback? then}) {
    if (_isDismissing) {
      then?.call();
      return;
    }
    _isDismissing = true;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      widget.onRemove();
      then?.call();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 8;
    final screenWidth = mediaQuery.size.width;

    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: math.min(screenWidth * 0.94, 520),
            ),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -4) {
                  // Swipe up detected
                  dismiss();
                }
              },
              child: Material(
                color: Colors.transparent,
                child: _buildNotificationCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    final String? displayAmount = widget.amount;
    String? displayAction = '';
    String? displayFor = '';
    String fallbackMessage = widget.message;

    if (widget.amount != null && widget.message.startsWith(widget.amount!)) {
      final remainder = widget.message.substring(widget.amount!.length).trim();
      final parts = remainder.split(' for ');
      if (parts.isNotEmpty) {
        displayAction = parts[0].trim();
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          displayFor = 'for ${parts.sublist(1).join(' for ').trim()}';
        }
        fallbackMessage = '';
      }
    }

    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeftIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    if (fallbackMessage.isEmpty) ...[
                      Row(
                        children: [
                          Text(
                            displayAmount ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayAction ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (displayFor.isNotEmpty)
                        Text(
                          displayFor,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ] else ...[
                      Text(
                        fallbackMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 6),
                    if (widget.invoiceNumber != null && widget.invoiceNumber!.isNotEmpty)
                      Text(
                        '${widget.invoiceNumber} • $dateStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          
          Positioned(
            top: -12,
            right: -8,
            child: GestureDetector(
              onTap: () => dismiss(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Color(0xFF4B5563)),
              ),
            ),
          ),
          
          Positioned(
            bottom: -12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDash(isActive: true),
                const SizedBox(width: 6),
                _buildDash(isActive: false),
                const SizedBox(width: 6),
                _buildDash(isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDash({required bool isActive}) {
    return Container(
      width: isActive ? 16 : 12,
      height: 3,
      decoration: BoxDecoration(
        color: isActive ? _primaryBlue : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  Widget _buildLeftIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 6, left: 6, child: _buildIconDot()),
          Positioned(top: 6, right: 6, child: _buildIconDot()),
          Positioned(bottom: 6, left: 6, child: _buildIconDot()),
          Positioned(bottom: 6, right: 6, child: _buildIconDot()),
          
          if (widget.type == 'payment')
            const Icon(Icons.account_balance_wallet_rounded, color: _primaryBlue, size: 20)
          else
            SvgPicture.asset(
              'assets/SVG/invoice.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(_primaryBlue, BlendMode.srcIn),
            ),
        ],
      ),
    );
  }

  Widget _buildIconDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  HexagonPainter({required this.color, this.strokeWidth = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Flat-top Hexagon
    path.moveTo(width * 0.25, 0);
    path.lineTo(width * 0.75, 0);
    path.lineTo(width, height / 2);
    path.lineTo(width * 0.75, height);
    path.lineTo(width * 0.25, height);
    path.lineTo(0, height / 2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

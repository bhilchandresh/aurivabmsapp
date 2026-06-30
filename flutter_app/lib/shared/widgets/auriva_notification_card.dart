import 'package:flutter/material.dart';

enum AurivaNotificationType { payment, invoice }

class AurivaNotificationCard extends StatelessWidget {
  final AurivaNotificationType type;
  final String title;
  final String time;
  final String bodyText1;
  final String bodyText2;

  const AurivaNotificationCard({
    Key? key,
    required this.type,
    required this.title,
    required this.time,
    required this.bodyText1,
    required this.bodyText2,
  }) : super(key: key);

  static const Color _primaryBlue = Color(0xFF1D58F7);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogo(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AurivaBMS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 13,
                            color: _textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Title Row
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (type == AurivaNotificationType.payment)
                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18)
                        else
                          Icon(Icons.description, color: _primaryBlue, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Body Text
                    Text(
                      bodyText1,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textGrey,
                        height: 1.4,
                      ),
                    ),
                    Text(
                      bodyText2,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildRightIcon(),
            ],
          ),
          
          // Bottom Indicator Pill
          Positioned(
            bottom: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: HexagonPainter(
              color: _primaryBlue,
              strokeWidth: 3.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightIcon() {
    IconData mainIcon;
    IconData badgeIcon;
    
    if (type == AurivaNotificationType.payment) {
      mainIcon = Icons.account_balance_wallet_rounded;
      badgeIcon = Icons.currency_rupee_rounded;
    } else {
      mainIcon = Icons.insert_drive_file_rounded;
      badgeIcon = Icons.add_rounded;
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _primaryBlue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 4 Corner Dots
          Positioned(top: 8, left: 8, child: _buildDot()),
          Positioned(top: 8, right: 8, child: _buildDot()),
          Positioned(bottom: 8, left: 8, child: _buildDot()),
          Positioned(bottom: 8, right: 8, child: _buildDot()),

          // Main Icon
          Icon(mainIcon, color: _primaryBlue, size: 28),

          // Small Badge over Icon
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _primaryBlue,
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

  Widget _buildDot() {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: _primaryBlue.withOpacity(0.15),
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

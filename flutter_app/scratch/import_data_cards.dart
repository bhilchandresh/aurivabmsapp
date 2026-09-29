import 'dart:ui';

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.radius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = Path();
    var distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Replacements for _buildActionCards and _buildActionCard

  Widget _buildActionCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDownloadCard(isDark),
          const SizedBox(height: 24),
          _buildUploadCard(isDark),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E3FF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.fileDown, color: Color(0xFF3B7BF6), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Download Template',
            style: context.typography.cardTitle.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Download the required Excel format\nwith the correct columns and sample data.',
            style: context.typography.cardSubtitle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _controller.downloadTemplate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B7BF6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              icon: const Icon(LucideIcons.download, size: 20),
              label: Text(
                'Download Excel Template',
                style: context.typography.buttonText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D7FF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.fileUp, color: Color(0xFF7C3AED), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload Filled Excel',
            style: context.typography.cardTitle.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload the Excel file with your client data.',
            style: context.typography.cardSubtitle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Drag and drop area
          GestureDetector(
            onTap: _controller.pickFile,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFFC7B1EF),
                radius: 12,
                strokeWidth: 1.5,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    const Icon(LucideIcons.cloudUpload, color: Color(0xFF7C3AED), size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Drag & drop your Excel file here',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'or tap to select a file',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Supported format: .xlsx, .xls (Max 10MB)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Obx(() {
            final btnLabel = _controller.selectedFileName.isNotEmpty
                ? _controller.selectedFileName.value
                : 'Upload Excel File';
            final isBusy = _controller.isParsing.value;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : _controller.pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.folder, size: 20),
                label: Text(
                  btnLabel,
                  style: context.typography.buttonText.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

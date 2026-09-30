import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../core/theme/app_extensions.dart';
import 'import_data_controller.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImportDataController _controller = Get.put(ImportDataController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  int _currentIdx = 0;

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && _tabController.index != _currentIdx) {
      _currentIdx = _tabController.index;
      final tabs = ['clients', 'inventory', 'invoices'];
      if (_currentIdx >= 0 && _currentIdx < tabs.length) {
        _controller.setActiveTab(tabs[_currentIdx]);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'import_legacy_data'.tr,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            children: [
              _buildTabBar(isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTabContent(isDark),
                    _buildTabContent(isDark),
                    _buildTabContent(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [_buildActionCards(isDark), _buildPreviewSection(isDark)],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: AnimatedBuilder(
        animation: _tabController.animation ?? _tabController,
        builder: (context, child) {
          final animationValue = _tabController.animation?.value ?? _tabController.index.toDouble();
          return Row(
            children: [
              _buildCustomTab(
                'clients'.tr,
                'assets/SVG/client01.svg',
                0,
                animationValue,
              ),
              _buildCustomTab(
                'inventory'.tr,
                'assets/SVG/inventory.svg',
                1,
                animationValue,
              ),
              _buildCustomTab(
                'invoices'.tr,
                'assets/SVG/invoice.svg',
                2,
                animationValue,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomTab(
    String label,
    String svgPath,
    int index,
    double animationValue,
  ) {
    // Calculate how 'selected' this tab is (from 0.0 to 1.0) based on the swipe position
    final double selection = (1.0 - (animationValue - index).abs()).clamp(
      0.0,
      1.0,
    );

    // Smoothly calculate flex from 15 to 70 based on selection
    final double flexValue = 15.0 + (55.0 * selection);

    return Expanded(
      flex: flexValue.toInt(),
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          final tabs = ['clients', 'inventory', 'invoices'];
          if (index >= 0 && index < tabs.length) {
            _currentIdx = index;
            _controller.setActiveTab(tabs[index]);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              context.colorScheme.primary,
              selection,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  svgPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Color.lerp(
                      Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey,
                      Colors.white,
                      selection,
                    ) ?? Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                if (selection > 0.3) ...[
                  SizedBox(width: 8 * ((selection - 0.3) / 0.7)),
                  Opacity(
                    opacity: ((selection - 0.3) / 0.7).clamp(0.0, 1.0),
                    child: Text(
                      label,
                      style: context.typography.inputText.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B7BF6).withValues(alpha: 0.1) : const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3B7BF6).withValues(alpha: 0.3) : const Color(0xFFD4E3FF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3B7BF6).withValues(alpha: 0.2) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              'assets/SVG/donwload.svg',
              colorFilter: ColorFilter.mode(
                isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B7BF6),
                BlendMode.srcIn,
              ),
              width: 18,
              height: 18,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Download Template',
            style: context.typography.cardTitle.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Download the required Excel format\nwith the correct columns and sample data.',
            style: context.typography.cardSubtitle.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: SvgPicture.asset(
                'assets/SVG/downloac.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              label: Text(
                'Download Excel Template',
                style: context.typography.buttonText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.1) : const Color(0xFFF9F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.3) : const Color(0xFFE9D7FF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.2) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              'assets/SVG/upload.svg',
              colorFilter: ColorFilter.mode(
                isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                BlendMode.srcIn,
              ),
              width: 18,
              height: 18,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload Filled Excel',
            style: context.typography.cardTitle.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload the Excel file with your client data.',
            style: context.typography.cardSubtitle.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Drag and drop area
          GestureDetector(
            onTap: _controller.pickFile,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.5) : const Color(0xFFC7B1EF),
                radius: 12,
                strokeWidth: 1.5,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/SVG/doc.svg',
                      colorFilter: ColorFilter.mode(
                        isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Drag & drop your Excel file here',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or tap to select a file',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Supported format: .xlsx, .xls (Max 10MB)',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8),
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
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/SVG/file.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        width: 16,
                        height: 16,
                      ),
                label: Text(
                  btnLabel,
                  style: context.typography.buttonText.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

  Widget _buildPreviewSection(bool isDark) {
    return Obx(() {
      if (_controller.parsedData.isEmpty) return const SizedBox.shrink();

      final data = _controller.parsedData.take(50).toList();
      final headers = data.isEmpty ? <String>[] : data.first.keys.toList();

      return Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.checkCircle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_controller.parsedData.length} ${'parsed_rows_ready'.tr}',
                            style: context.typography.inputText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _controller.isImporting.value
                        ? null
                        : _controller.importData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    child: _controller.isImporting.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'start_import'.tr,
                            style: context.typography.buttonText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: data.isEmpty
                  ? const SizedBox.shrink()
                  : DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      dataRowColor: WidgetStateProperty.all(
                        Theme.of(context).cardTheme.color,
                      ),
                      dividerThickness: 1,
                      columns: headers
                          .map(
                            (h) => DataColumn(
                              label: Text(
                                h.toUpperCase(),
                                style: context.typography.tableHeader.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      rows: data.map((row) {
                        return DataRow(
                          cells: headers.map((h) {
                            final val = row[h]?.toString() ?? '-';
                            return DataCell(
                              Text(
                                val.isEmpty ? '-' : val,
                                style: context.typography.tableCell.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
            ),
            if (_controller.parsedData.length > 50)
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Text(
                  'showing_first_50_rows'.tr,
                  style: context.typography.helperText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.radius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 6;
    const double dashSpace = 4;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

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

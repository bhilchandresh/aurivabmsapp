import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import 'expenses_controller.dart';
import 'all_expenses_screen.dart';
import 'widgets/expense_list_item.dart';
import 'widgets/category_picker_bottom_sheet.dart';
import 'widgets/expense_details_bottom_sheet.dart';
import 'expense_components.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpensesController _controller = Get.put(ExpensesController());

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'expenses'.tr,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Obx(() {
        final showSkeleton =
            _controller.isLoading.value && _controller.expenses.isEmpty;

        return RefreshIndicator(
          onRefresh: () async {
            await _controller.fetchExpenses();
          },
          color: AppColors.primary,
          child: Skeletonizer(
            enabled: showSkeleton,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 80.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header stats cards
                  _buildHeaderStats(context, isDark),
                  const SizedBox(height: 20),

                  // Spending analysis chart card
                  if (_controller.processedExpenses.isNotEmpty) ...[
                    _buildSpendingAnalysisChart(isDark),
                    const SizedBox(height: 20),
                  ],

                  // Filter bar & export button
                  _buildFiltersAndActionsRow(context, isDark),
                  const SizedBox(height: 16),

                  // Expense log list
                  _buildExpensesList(context, isDark),
                ],
              ),
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddExpenseBottomSheet(context, isDark),
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
        icon: SvgPicture.asset('assets/SVG/plus.svg', width: 18, height: 18, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
        label: Text(
          'add_expense'.tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context, bool isDark) {
    final totalFiltered = _controller.totalFilteredSpent;
    final totalAllTime = _controller.totalAllTimeSpent;
    final filterMonth = _controller.filterMonth.value;

    String monthLabel = 'MONTHLY TOTAL';
    if (filterMonth.isNotEmpty) {
      try {
        final parsed = DateTime.parse('$filterMonth-01');
        monthLabel = DateFormat('MMMM yyyy').format(parsed).toUpperCase();
      } catch (_) {
        monthLabel = filterMonth.toUpperCase();
      }
    }

    return Row(
      children: [
        if (filterMonth.isNotEmpty) ...[
          Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon and Month
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SvgPicture.asset('assets/SVG/calendernormal.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.indigo, BlendMode.srcIn)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        monthLabel,
                        style: TextStyle(
                          color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Middle: Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatCurrency.format(totalFiltered),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon and Title
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SvgPicture.asset('assets/SVG/growth.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcIn)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ALL TIME',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Middle: Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatCurrency.format(totalAllTime),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.displayLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- spending chart ---
  Widget _buildSpendingAnalysisChart(bool isDark) {
    final breakdown = _controller.categoryBreakdown;
    final categories = breakdown.keys.toList();
    final values = breakdown.values.toList();
    final double maxVal = values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal * 1.35; // Extra space for top labels

    final chartColorPalette = [
      const Color(0xFF3B82F6), // blue
      const Color(0xFFEF4444), // red
      const Color(0xFF10B981), // emerald
      const Color(0xFFF59E0B), // amber
      const Color(0xFF8B5CF6), // purple
      const Color(0xFFEC4899), // pink
      const Color(0xFF0EA5E9), // sky blue
      const Color(0xFFF97316), // orange
    ];

    return DefaultTabController(
      length: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SvgPicture.asset('assets/SVG/chart.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.indigo, BlendMode.srcIn)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Spending Analysis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(By Category)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.moreHorizontal, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
              ],
            ),
            const SizedBox(height: 16),

            Builder(
              builder: (context) {
                final total = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b);
                if (total == 0) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: Text("No expenses for this period")),
                  );
                }

                // Process breakdown to limit categories and prevent clutter
                final entries = breakdown.entries.toList();
                entries.sort((a, b) => b.value.compareTo(a.value));
                
                final maxCategories = 5;
                final displayCategories = <MapEntry<String, double>>[];
                double othersValue = 0.0;
                
                for (int i = 0; i < entries.length; i++) {
                  if (i < maxCategories - 1 || (i == maxCategories - 1 && entries.length == maxCategories)) {
                    displayCategories.add(entries[i]);
                  } else {
                    othersValue += entries[i].value;
                  }
                }
                
                if (othersValue > 0) {
                  displayCategories.add(MapEntry('Others', othersValue));
                }

                final legendWidgets = <Widget>[];
                for (int i = 0; i < displayCategories.length; i++) {
                  legendWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: chartColorPalette[i % chartColorPalette.length],
                              shape: BoxShape.rectangle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayCategories[i].key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).textTheme.displayLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: TabBarView(
                    children: [
                      // Tab 1: Pie Chart
                      Builder(
                        builder: (context) {
                          int touchedIndex = -1;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutQuart,
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                builder: (context, animValue, child) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: PieChart(
                                          PieChartData(
                                            pieTouchData: PieTouchData(
                                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                                setState(() {
                                                  if (!event.isInterestedForInteractions ||
                                                      pieTouchResponse == null ||
                                                      pieTouchResponse.touchedSection == null ||
                                                      pieTouchResponse.touchedSection!.touchedSectionIndex == -1) {
                                                    touchedIndex = -1;
                                                    return;
                                                  }
                                                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                                });
                                              },
                                            ),
                                            sectionsSpace: 2,
                                            centerSpaceRadius: 35 * animValue,
                                            sections: List.generate(displayCategories.length, (index) {
                                              final value = displayCategories[index].value;
                                              final percentage = (value / total) * 100;
                                              final isTouched = index == touchedIndex;
                                              
                                              final title = isTouched 
                                                  ? '₹${NumberFormat.compact().format(value)}'
                                                  : (percentage > 4 ? '${percentage.toStringAsFixed(0)}%' : '');
                                              
                                              return PieChartSectionData(
                                                color: chartColorPalette[index % chartColorPalette.length],
                                                value: value,
                                                title: title,
                                                radius: (isTouched ? 55.0 : 45.0) * animValue,
                                                titleStyle: TextStyle(
                                                  fontSize: isTouched ? 14 : 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              );
                                            }),
                                          ),
                                          swapAnimationDuration: const Duration(milliseconds: 150),
                                          swapAnimationCurve: Curves.linear,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: legendWidgets,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      // Tab 2: Bar Chart
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutQuart,
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, animValue, child) {
                            return BarChart(
                              swapAnimationDuration: const Duration(milliseconds: 150),
                              swapAnimationCurve: Curves.linear,
                              BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY < 600000 ? 600000 : maxY,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchExtraThreshold: const EdgeInsets.symmetric(vertical: 300),
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => isDark ? Colors.white : Colors.black87,
                                tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                tooltipMargin: 8,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final category = displayCategories[group.x.toInt()].key;
                                  return BarTooltipItem(
                                    '$category\n',
                                    TextStyle(
                                      color: isDark ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: NumberFormat.compactCurrency(symbol: '₹').format(displayCategories[group.x.toInt()].value),
                                        style: TextStyle(
                                          color: isDark ? Colors.black87 : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value >= 0 && value < displayCategories.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: SizedBox(
                                          width: 50,
                                          child: Text(
                                            displayCategories[value.toInt()].key,
                                            style: TextStyle(
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  reservedSize: 28,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  interval: 100000,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value == 100000 || value == 200000 || value == 300000 || value == 400000 || value == 500000 || value == 600000) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 4.0),
                                        child: Text(
                                          '₹${NumberFormat.compact().format(value)}',
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 100000,
                              checkToShowHorizontalLine: (value) {
                                return value == 100000 || value == 200000 || value == 300000 || value == 400000 || value == 500000 || value == 600000;
                              },
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(displayCategories.length, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: displayCategories[index].value * animValue,
                                    color: chartColorPalette[index % chartColorPalette.length],
                                    width: 22,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TabPageSelector(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  selectedColor: Colors.indigo,
                  indicatorSize: 8,
                ),
              ],
            );
              }
            ),
          ],
        ),
      ),
    );
  }

  // --- FILTERS & EXPORT ---
  Widget _buildFiltersAndActionsRow(BuildContext context, bool isDark) {
    final List<String> defaultCategories = [
      'Maintenance',
      'Fuel',
      'Salary',
      'Equipment',
      'Insurance',
      'Travel',
      'Office',
      'Utilities',
      'Marketing',
      'Other'
    ];
    final Set<String> existingCategories = _controller.allUniqueCategories;
    final List<String> allCategories = {...defaultCategories, ...existingCategories}.toList()..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Row 1: Month and Category
          Row(
            children: [
              // Period selector
              Expanded(
                child: InkWell(
                  onTap: () => _showMonthPicker(context, isDark),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/SVG/calendernormal.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Colors.indigo, BlendMode.srcIn)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() {
                            final val = _controller.filterMonth.value;
                            if (val.isEmpty) {
                              return Text('All Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.displayLarge?.color));
                            }
                            try {
                              final parsed = DateTime.parse('$val-01');
                              return Text(DateFormat('MMM yyyy').format(parsed), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.displayLarge?.color));
                            } catch (_) {
                              return Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.displayLarge?.color));
                            }
                          }),
                        ),
                        const Icon(LucideIcons.chevronDown, size: 14, color: Colors.indigo),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Category selector
              Expanded(
                child: InkWell(
                  onTap: () => showCategoryPickerBottomSheet(context, isDark, allCategories),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Obx(
                            () => Text(
                              _controller.filterCategory.value.isEmpty ? 'All Categories' : _controller.filterCategory.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.displayLarge?.color,
                              ),
                            ),
                          ),
                        ),
                        const Icon(LucideIcons.chevronDown, size: 14, color: Colors.indigo),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Sort, Export, Reset
          Row(
            children: [
              // Sort selector
              // Sort selector
              Expanded(
                child: InkWell(
                  onTap: () => _showSortPickerBottomSheet(context, isDark),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Obx(() {
                            final val = _controller.sortBy.value;
                            String text = 'Newest First';
                            if (val == 'date-asc') text = 'Oldest First';
                            if (val == 'amount-desc') text = 'High Amount';
                            if (val == 'amount-asc') text = 'Low Amount';
                            return Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.displayLarge?.color,
                              ),
                            );
                          }),
                        ),
                        const Icon(LucideIcons.chevronDown, size: 14, color: Colors.indigo),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Export Button
              InkWell(
                onTap: _exportCSV,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset('assets/SVG/download.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                      const SizedBox(width: 6),
                      const Text(
                        'Export',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Reset Button
              InkWell(
                onTap: () {
                  _controller.filterMonth.value = '';
                  _controller.filterCategory.value = '';
                  _controller.sortBy.value = 'date-desc';
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/SVG/reload.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(Theme.of(context).textTheme.displayLarge?.color ?? Colors.black, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SORT SELECTION BOTTOM SHEET ---
  void _showSortPickerBottomSheet(BuildContext context, bool isDark) {
    String tempSelectedSort = _controller.sortBy.value;

    final List<Map<String, String>> sortOptions = [
      {'value': 'date-desc', 'label': 'Newest First'},
      {'value': 'date-asc', 'label': 'Oldest First'},
      {'value': 'amount-desc', 'label': 'High Amount'},
      {'value': 'amount-asc', 'label': 'Low Amount'},
    ];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).dialogTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort Expenses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.displayLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose how to order the list',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.x, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sort Options List
                Column(
                  children: sortOptions.map((option) {
                    final isSelected = tempSelectedSort == option['value'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setSheetState(() {
                            tempSelectedSort = option['value']!;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.blue : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                option['label']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.blue.shade700 : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              if (isSelected)
                                Icon(LucideIcons.check, size: 18, color: Colors.blue.shade700)
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      _controller.sortBy.value = tempSelectedSort;
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Sort',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // --- PERIOD SELECTION BOTTOM SHEET ---
  void _showMonthPicker(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final monthsList = List.generate(12, (index) {
      return DateTime(now.year, now.month - index);
    });

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).dialogTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'select_outflow_period'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _controller.filterMonth.value = '';
                    Get.back();
                  },
                  child: Text(
                    'clear_filter'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: monthsList.length,
              itemBuilder: (context, index) {
                final dt = monthsList[index];
                final valStr = DateFormat('yyyy-MM').format(dt);
                final labelStr = DateFormat('MMM yyyy').format(dt);

                return Obx(() {
                  final isSelected = _controller.filterMonth.value == valStr;
                  return InkWell(
                    onTap: () {
                      _controller.filterMonth.value = valStr;
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (Theme.of(context).colorScheme.outline),
                        ),
                      ),
                      child: Text(
                        labelStr,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // --- CSV EXPORT METHOD ---
  Future<void> _exportCSV() async {
    final list = _controller.processedExpenses;
    if (list.isEmpty) {
      Get.snackbar(
        'Error',
        'no_data_export'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Date,Category,Amount,Description');
    for (var item in list) {
      final formattedDate = item.date;
      final category = '"${item.category.replaceAll('"', '""')}"';
      final description = '"${item.description.replaceAll('"', '""')}"';
      buffer.writeln('$formattedDate,$category,${item.amount},$description');
    }

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/expenses_export.csv');
      await file.writeAsString(buffer.toString());
      
      await Share.shareXFiles([XFile(file.path)], text: 'Expenses Export');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to export file',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // --- EXPENSE LIST BUILDER ---
  Widget _buildExpensesList(BuildContext context, bool isDark) {
    final expenses = _controller.processedExpenses;

    if (expenses.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/SVG/dollar.svg',
              width: 32,
              height: 32,
              colorFilter: ColorFilter.mode(Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3) ?? Colors.grey, BlendMode.srcIn),
            ),
            const SizedBox(height: 12),
            Text(
              'no_expense_logs'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: () => Get.to(
                  () => const AllExpensesScreen(),
                  transition: Transition.fadeIn,
                ),
                child: Row(
                  children: [
                    const Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight, size: 14, color: Colors.indigo),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Dismissible(
                key: Key(expense.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await confirmDelete(context, isDark, _controller, expense);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade500,
                  child: SvgPicture.asset('assets/SVG/delete.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                ),
                child: ExpenseListItem(
                  expense: expense,
                  isDark: isDark,
                  onTap: () => showExpenseDetailsBottomSheet(context, isDark, expense),
                  onDelete: () => confirmDelete(context, isDark, _controller, expense),
                  currencyFormat: formatCurrency,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---

  // --- EXPENSE DETAILS BOTTOM SHEET ---

  // --- ADD EXPENSE BOTTOM SHEET ---
}

  void _showAddExpenseCategoryPicker(BuildContext context, bool isDark, List<String> allCategories, TextEditingController categoryCtrl) {
    String tempSelectedCategory = categoryCtrl.text.isEmpty ? (allCategories.isNotEmpty ? allCategories[0] : 'Other') : categoryCtrl.text;
    String searchQuery = '';

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final filteredCategories = allCategories
              .where((cat) => cat.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).dialogTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.displayLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose an expense category',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.x, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setSheetState(() {
                        searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search category...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: SvgPicture.asset('assets/SVG/search.svg', width: 16, height: 16, colorFilter: ColorFilter.mode(Colors.grey.shade500, BlendMode.srcIn)),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.displayLarge?.color,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Categories Grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      final isSelected = tempSelectedCategory == cat;
                      return InkWell(
                        onTap: () {
                          setSheetState(() {
                            tempSelectedCategory = cat;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.blue : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.blue.shade700 : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      categoryCtrl.text = tempSelectedCategory;
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void showAddExpenseBottomSheet(BuildContext context, bool isDark) {
    final _controller = Get.find<ExpensesController>();
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    DateTime selectedDate = DateTime.now();
    final dateCtrl = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(selectedDate),
    );

    // Categories list
    final List<String> defaultCategories = [
      'Software',
      'Office',
      'Hosting',
      'Rent',
      'Marketing',
      'Utilities',
      'Travel',
      'Salary',
      'Other',
    ];
    final Set<String> existingCategories = _controller.allUniqueCategories;
    final List<String> allCategories = {...defaultCategories, ...existingCategories}.toList()..sort();
    
    final categoryCtrl = TextEditingController(
      text: allCategories.isNotEmpty ? allCategories[0] : 'Other',
    );

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final inputBgColor = isDark ? Colors.grey.shade900 : const Color(0xFFF9FAFB);
          final inputBorderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

          // Helper for labels
          Widget _buildLabel(String text, {bool isRequired = false}) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            );
          }

          // Helper for input decoration
          InputDecoration _inputDeco(String hint, {Widget? prefixIcon, BoxConstraints? prefixIconConstraints, double? hintSize}) {
            return InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: hintSize ?? 12),
              filled: true,
              fillColor: inputBgColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: prefixIcon,
              prefixIconConstraints: prefixIconConstraints,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: inputBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: inputBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade400),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).dialogTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20, 
                right: 20, 
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Expense',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.displayLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Record a new business expense',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Get.back(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.x, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Field
                    _buildLabel('Category', isRequired: true),
                    Container(
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: inputBorderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: categoryCtrl,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 13,
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          InkWell(
                            onTap: () => _showAddExpenseCategoryPicker(context, isDark, allCategories, categoryCtrl),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                LucideIcons.chevronDown,
                                size: 16,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount and Date Fields
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Amount (₹)', isRequired: true),
                              TextFormField(
                                controller: amountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 13),
                                decoration: _inputDeco(
                                  '0.00',
                                  hintSize: 15,
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 12.0, right: 8.0),
                                    child: Text(
                                      '₹',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  if (double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Date', isRequired: true),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      selectedDate = picked;
                                      dateCtrl.text = DateFormat('dd MMM yyyy').format(picked);
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: inputBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: inputBorderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/SVG/calendernormal.svg',
                                        width: 14,
                                        height: 14,
                                        colorFilter: ColorFilter.mode(Colors.grey.shade600, BlendMode.srcIn),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dateCtrl.text,
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                          fontSize: 13,
                                        ),
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
                    const SizedBox(height: 12),

                    // Description Field
                    _buildLabel('Description', isRequired: true),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      maxLength: 200,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDeco(
                        'e.g. AWS Servers, Office desks',
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12.0, right: 8.0, bottom: 20.0), // Align to top
                          child: SvgPicture.asset(
                            'assets/SVG/note.svg',
                            width: 14,
                            height: 14,
                            fit: BoxFit.scaleDown,
                            colorFilter: ColorFilter.mode(Colors.grey.shade500, BlendMode.srcIn),
                          ),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Theme.of(context).colorScheme.outline),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.displayLarge?.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() {
                            final isSaving = _controller.isLoading.value;
                            return ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        final amt = double.parse(amountCtrl.text.trim());
                                        String finalDesc = descCtrl.text.trim();

                                        // We need to parse back date to yyyy-MM-dd format for the backend/controller
                                        final formattedForBackend = DateFormat('yyyy-MM-dd').format(selectedDate);

                                        final success = await _controller.addExpense(
                                          categoryCtrl.text.trim(),
                                          amt,
                                          formattedForBackend,
                                          finalDesc,
                                        );

                                        if (success) {
                                          Get.back();
                                          Get.snackbar(
                                            'Success',
                                            'Expense added successfully!',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: AppColors.success,
                                            colorText: Colors.white,
                                          );
                                        } else {
                                          Get.snackbar(
                                            'Error',
                                            'Failed to add expense. Please try again.',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB), // solid blue color
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/SVG/save.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

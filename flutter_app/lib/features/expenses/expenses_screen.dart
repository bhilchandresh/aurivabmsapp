import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import 'expenses_controller.dart';
import 'all_expenses_screen.dart';
import 'widgets/expense_list_item.dart';

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
        subtitle: 'track_manage_outflows'.tr,
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
        onPressed: () => _showAddExpenseBottomSheet(context, isDark),
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
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
                      child: const Center(
                        child: Icon(LucideIcons.calendar, color: Colors.indigo, size: 16),
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
                      child: const Center(
                        child: Icon(LucideIcons.trendingUp, color: Colors.blue, size: 16),
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
                  child: const Icon(LucideIcons.barChart3, size: 16, color: Colors.indigo),
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
    final Set<String> existingCategories = _controller.expenses.map((e) {
      final cat = e.category.trim();
      return cat.isEmpty ? 'Other' : '${cat[0].toUpperCase()}${cat.substring(1)}';
    }).toSet();
    final List<String> allCategories = ['All Categories', ...{...defaultCategories, ...existingCategories}.toList()..sort()];

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
                        const Icon(LucideIcons.calendar, size: 14, color: Colors.indigo),
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
                  child: Obx(
                    () => DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _controller.filterCategory.value.isEmpty ? 'All Categories' : _controller.filterCategory.value,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.indigo),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                        ),
                        dropdownColor: Theme.of(context).cardTheme.color,
                        items: allCategories.map((String cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            if (val == 'All Categories') {
                              _controller.filterCategory.value = '';
                            } else {
                              _controller.filterCategory.value = val;
                            }
                          }
                        },
                      ),
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
              Expanded(
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
                  child: Obx(
                    () => DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _controller.sortBy.value,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.indigo),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                        ),
                        dropdownColor: Theme.of(context).cardTheme.color,
                        items: const [
                          DropdownMenuItem(value: 'date-desc', child: Text('Newest First')),
                          DropdownMenuItem(value: 'date-asc', child: Text('Oldest First')),
                          DropdownMenuItem(value: 'amount-desc', child: Text('High Amount')),
                          DropdownMenuItem(value: 'amount-asc', child: Text('Low Amount')),
                        ],
                        onChanged: (val) {
                          if (val != null) _controller.sortBy.value = val;
                        },
                      ),
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
                    children: const [
                      Icon(LucideIcons.download, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
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
                  child: Icon(
                    LucideIcons.refreshCcw,
                    size: 16,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
  void _exportCSV() {
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

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    Get.snackbar(
      'export_success'.tr,
      'csv_copied'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(LucideIcons.checkCircle, color: Colors.white),
    );
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
            Icon(
              LucideIcons.receipt,
              size: 32,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
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
      padding: const EdgeInsets.all(16),
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
                  return await _confirmDelete(context, isDark, expense);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade500,
                  child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                ),
                child: ExpenseListItem(
                  expense: expense,
                  isDark: isDark,
                  onTap: () => _showExpenseDetailsBottomSheet(context, isDark, expense),
                  onDelete: () => _confirmDelete(context, isDark, expense),
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
  Future<bool> _confirmDelete(
    BuildContext context,
    bool isDark,
    Expense expense,
  ) async {
    bool confirm = false;
    await Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        content: Text('delete_expense_confirm'.tr),
        actions: [
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
            );
          }),
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final success = await _controller.deleteExpense(
                        expense.id,
                      );
                      if (success) {
                        confirm = true;
                        Get.back();
                        Get.snackbar(
                          'Deleted',
                          'Expense record deleted successfully',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'Failed to delete expense record. Please try again.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('delete'.tr, style: const TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
    );
    return confirm;
  }

  // --- EXPENSE DETAILS BOTTOM SHEET ---
  void _showExpenseDetailsBottomSheet(
    BuildContext context,
    bool isDark,
    Expense expense,
  ) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).dialogTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    expense.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              expense.description,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat(
                    'dd MMMM yyyy',
                  ).format(DateTime.parse(expense.date)),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AMOUNT PAID',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  formatCurrency.format(expense.amount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _confirmDelete(context, isDark, expense);
                    },
                    icon: const Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: Text(
                      'delete_log'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ADD EXPENSE BOTTOM SHEET ---
  void _showAddExpenseBottomSheet(BuildContext context, bool isDark) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    DateTime selectedDate = DateTime.now();
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedDate),
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
    final Set<String> existingCategories = _controller.categoryBreakdown.keys.toSet();
    final List<String> allCategories = {...defaultCategories, ...existingCategories}.toList()..sort();
    
    final categoryCtrl = TextEditingController(
      text: allCategories.isNotEmpty ? allCategories[0] : 'Other',
    );

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).dialogTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'log_expense'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.displayLarge?.color,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Category dropdown select
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            'category_star'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: categoryCtrl,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    hintText: 'Enter or select category',
                                    hintStyle: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  LucideIcons.chevronDown,
                                  size: 20,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                color: Theme.of(context).cardTheme.color,
                                onSelected: (String value) {
                                  categoryCtrl.text = value;
                                },
                                itemBuilder: (BuildContext context) {
                                  return allCategories.map((String choice) {
                                    return PopupMenuItem<String>(
                                      value: choice,
                                      child: Text(choice),
                                    );
                                  }).toList();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description Field
                    AppInputField(
                      label: 'expense_desc'.tr,
                      hintText: 'e_g_aws_servers_office_desks'.tr,
                      controller: descCtrl,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Amount & Date side by side
                    Row(
                      children: [
                        Expanded(
                          child: AppInputField(
                            label: 'amount_rupees'.tr,
                            hintText: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            controller: amountCtrl,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(top: 14.0, left: 4.0),
                              child: Text(
                                '₹',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(val.trim()) == null ||
                                  double.parse(val.trim()) <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 4,
                                ),
                                child: Text(
                                  'select_date'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                    builder: (context, child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(
                                          textScaler: TextScaler.noScaling,
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      selectedDate = picked;
                                      dateCtrl.text = DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateCtrl.text,
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Icon(
                                        LucideIcons.calendar,
                                        size: 16,
                                        color: Theme.of(context).iconTheme.color,
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
                    const SizedBox(height: 20),

                    // Submit button
                    Obx(() {
                      final isSaving = _controller.isLoading.value;
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    final amt = double.parse(
                                      amountCtrl.text.trim(),
                                    );
                                    final desc = descCtrl.text.trim();

                                    final success = await _controller
                                        .addExpense(
                                          categoryCtrl.text.trim(),
                                          amt,
                                          dateCtrl.text,
                                          desc,
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
                          icon: isSaving
                              ? const SizedBox.shrink()
                              : const Icon(
                                  LucideIcons.plus,
                                  size: 16,
                                  color: Colors.white,
                                ),
                          label: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'save_expense'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}

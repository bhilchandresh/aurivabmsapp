import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_loader.dart';
import '../../shared/widgets/app_input_field.dart';
import 'expenses_controller.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpensesController _controller = Get.put(ExpensesController());
  final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Controller list limit state
  final RxBool _showAll = false.obs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
      appBar: AppTopBar(
        title: 'expenses'.tr,
        subtitle: 'track_manage_outflows'.tr,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Obx(() {
        final showSkeleton = _controller.isLoading.value && _controller.expenses.isEmpty;
        return Skeletonizer(
          enabled: showSkeleton,
          child: RefreshIndicator(
            onRefresh: () => _controller.fetchExpenses(),
            color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header stats cards
                _buildHeaderStats(isDark),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text(
          'add_expense'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  // --- STAT CARDS ---
  Widget _buildHeaderStats(bool isDark) {
    final totalFiltered = _controller.totalFilteredSpent;
    final totalAllTime = _controller.totalAllTimeSpent;
    final filterMonth = _controller.filterMonth.value;

    String monthLabel = 'filtered_period'.tr;
    if (filterMonth.isNotEmpty) {
      try {
        final parsed = DateTime.parse('$filterMonth-01');
        monthLabel = DateFormat('MMMM yyyy').format(parsed);
      } catch (_) {
        monthLabel = filterMonth;
      }
      monthLabel = 'all_time_outflow'.tr;
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel.toUpperCase(),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatCurrency.format(totalFiltered),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filterMonth.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'all_time_total'.tr,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency.format(totalAllTime),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- spending chart ---
  Widget _buildSpendingAnalysisChart(bool isDark) {
    final breakdown = _controller.categoryBreakdown;
    final categories = breakdown.keys.toList();
    final values = breakdown.values.toList();
    final double maxY = values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b) * 1.15;

    final chartColorPalette = [
      Colors.blue.shade500,
      Colors.red.shade500,
      Colors.teal.shade500,
      Colors.amber.shade500,
      Colors.purple.shade500,
      Colors.pink.shade500,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.barChart3, size: 18, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'spending_analysis'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'by_category'.tr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF334155) : Colors.blueGrey.shade800,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cat = categories[groupIndex];
                      return BarTooltipItem(
                        '$cat\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: formatCurrency.format(rod.toY),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
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
                        final idx = value.toInt();
                        if (idx >= 0 && idx < categories.length) {
                          final cat = categories[idx];
                          final label = cat.length > 5 ? '${cat.substring(0, 4)}..' : cat;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 26,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == 0) return const SizedBox.shrink();
                        String label = '';
                        if (value >= 1000) {
                          label = '₹${(value / 1000).toStringAsFixed(0)}k';
                        } else {
                          label = '₹${value.toStringAsFixed(0)}';
                        }
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 3 : 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? const Color(0xFF334155).withOpacity(0.5) : Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(categories.length, (index) {
                  final catVal = breakdown[categories[index]] ?? 0.0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: catVal,
                        color: chartColorPalette[index % chartColorPalette.length],
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.grey.shade50,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTERS & EXPORT ---
  Widget _buildFiltersAndActionsRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Period selector
          Expanded(
            child: InkWell(
              onTap: () => _showMonthPicker(context, isDark),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Obx(() {
                        final val = _controller.filterMonth.value;
                        if (val.isEmpty) return Text('all_time'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                        try {
                          final parsed = DateTime.parse('$val-01');
                          return Text(
                            DateFormat('MMM yyyy').format(parsed),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          );
                        } catch (_) {
                          return Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
                        }
                      }),
                    ),
                    Icon(LucideIcons.chevronDown, size: 12, color: isDark ? const Color(0xFF64748B) : Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sort selector
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
              child: Obx(() => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _controller.sortBy.value,
                  icon: Icon(LucideIcons.chevronDown, size: 12, color: isDark ? const Color(0xFF64748B) : Colors.grey),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  items: [
                    DropdownMenuItem(value: 'date-desc', child: Text('newest_first'.tr)),
                    DropdownMenuItem(value: 'date-asc', child: Text('oldest_first'.tr)),
                    DropdownMenuItem(value: 'amount-desc', child: Text('high_amount'.tr)),
                    DropdownMenuItem(value: 'amount-asc', child: Text('low_amount'.tr)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _controller.sortBy.value = val;
                    }
                  },
                ),
              )),
            ),
          ),
          const SizedBox(width: 8),

          // Export Button
          InkWell(
            onTap: _exportCSV,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(LucideIcons.download, size: 16, color: Colors.white),
            ),
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
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
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
                    color: isDark ? Colors.white : AppColors.textPrimary,
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
                        color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                        ),
                      ),
                      child: Text(
                        labelStr,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : AppColors.textPrimary),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      Get.snackbar('Error', 'no_data_export'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
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
    final showSkeleton = _controller.isLoading.value && _controller.expenses.isEmpty;
    final list = showSkeleton
        ? List.generate(5, (index) => Expense(
            id: 'loading_$index',
            category: 'Loading',
            amount: 500.0,
            description: 'Loading description...',
            date: '2026-06-10',
          ))
        : _controller.processedExpenses;

    if (list.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.wallet, size: 28, color: isDark ? const Color(0xFF475569) : Colors.grey.shade400),
            ),
            const SizedBox(height: 12),
            Text(
              'no_expense_logs'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Limit elements to 10 if _showAll is false
    final bool showMoreBtnNeeded = list.length > 10;
    final visibleList = _showAll.value ? list : list.take(10).toList();

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final expense = visibleList[index];

            return Dismissible(
              key: Key(expense.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await _confirmDelete(context, isDark, expense);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.trash2, color: Colors.white),
              ),
              child: InkWell(
                onTap: () => _showExpenseDetailsBottomSheet(context, isDark, expense),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.trendingDown,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                expense.category.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expense.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy').format(DateTime.parse(expense.date)),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency.format(expense.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          IconButton(
                            onPressed: () => _confirmDelete(context, isDark, expense),
                            icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.red),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.08),
                              padding: const EdgeInsets.all(4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
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
        if (showMoreBtnNeeded) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _showAll.value = !_showAll.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showAll.value ? 'show_less'.tr : 'view_all'.tr + ' ${list.length} ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(_showAll.value ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 14),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  Future<bool> _confirmDelete(BuildContext context, bool isDark, Expense expense) async {
    bool confirm = false;
    await Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        content: Text('delete_expense_confirm'.tr),
        actions: [
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            );
          }),
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving ? null : () async {
                final success = await _controller.deleteExpense(expense.id);
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Delete', style: TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
    );
    return confirm;
  }

  // --- EXPENSE DETAILS BOTTOM SHEET ---
  void _showExpenseDetailsBottomSheet(BuildContext context, bool isDark, Expense expense) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
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
                  icon: Icon(LucideIcons.x, size: 18, color: isDark ? Colors.grey : Colors.black),
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
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 12, color: isDark ? const Color(0xFF64748B) : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.parse(expense.date)),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
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
                    color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
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
                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                    label: const Text('Delete Log', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate));
    
    // Categories list
    final List<String> categories = [
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
    String selectedCategory = categories[0];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
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
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, size: 18, color: isDark ? Colors.grey : Colors.black),
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
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              items: categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() {
                                    selectedCategory = val;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description Field
                    AppInputField(
                      label: 'expense_desc'.tr,
                      hintText: 'e.g. AWS Servers, Office desks',
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: amountCtrl,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(top: 14.0, left: 4.0),
                              child: Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) {
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
                                padding: const EdgeInsets.only(left: 4, bottom: 4),
                                child: Text(
                                  'select_date'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
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
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      selectedDate = picked;
                                      dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateCtrl.text,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Icon(LucideIcons.calendar, size: 16, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
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
                          onPressed: isSaving ? null : () async {
                            if (formKey.currentState!.validate()) {
                              final amt = double.parse(amountCtrl.text.trim());
                              final desc = descCtrl.text.trim();

                              final success = await _controller.addExpense(
                                selectedCategory,
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
                              : const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                          label: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('save_expense'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

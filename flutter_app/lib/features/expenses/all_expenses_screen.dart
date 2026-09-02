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
import 'widgets/expense_list_item.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  final ExpensesController _controller = Get.put(ExpensesController());
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  final RxInt _displayLimit = 10.obs;
  final RxBool _isLoadingMore = false.obs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore.value) return;
    if (_displayLimit.value >= _controller.processedExpenses.length) return;

    _isLoadingMore.value = true;
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate loading delay
    _displayLimit.value += 10;
    
    // Wait for the UI to rebuild so maxScrollExtent increases, 
    // preventing rapid consecutive triggers.
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoadingMore.value = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'All Expenses',
        subtitle: 'View and filter all transactions',
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Obx(() {
        final showSkeleton =
            _controller.isLoading.value && _controller.expenses.isEmpty;
        return Skeletonizer(
          enabled: showSkeleton,
          child: RefreshIndicator(
            onRefresh: () => _controller.fetchExpenses(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              controller: _scrollController,
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
                  // Spending analysis chart removed

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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // --- spending chart ---
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
          // Search Field
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: TextField(
              onChanged: (val) => _controller.searchQuery.value = val,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.displayLarge?.color,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
    final showSkeleton =
        _controller.isLoading.value && _controller.expenses.isEmpty;
    final list = showSkeleton
        ? List.generate(
            5,
            (index) => Expense(
              id: 'loading_$index',
              category: 'Loading',
              amount: 500.0,
              description: 'Loading description...',
              date: '2026-06-10',
            ),
          )
        : _controller.processedExpenses;

    if (list.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.wallet,
                size: 28,
                color: isDark ? const Color(0xFF475569) : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'no_expense_logs'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    // Use pagination limit
    final visibleList = list.take(_displayLimit.value).toList();

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
        if (_isLoadingMore.value) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
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
              expense.description.trim().isEmpty ? 'No Description' : expense.description,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              dropdownColor: Theme.of(context).cardTheme.color,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
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

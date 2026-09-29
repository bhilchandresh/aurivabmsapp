import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import '../../core/theme/app_extensions.dart';
import 'expenses_controller.dart';
import 'widgets/expense_list_item.dart';
import 'expenses_screen.dart'; // import to access showAddExpenseBottomSheet
import 'widgets/category_picker_bottom_sheet.dart';
import 'widgets/expense_details_bottom_sheet.dart';
import 'expense_components.dart';

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
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.fetchExpenses(),
        color: AppColors.primary,
        child: Obx(() {
          final isLoading = _controller.isLoading.value;
          final isFirstLoad = _controller.expenses.isEmpty;
          final showSkeleton = isLoading && isFirstLoad;
          
          final listItems = showSkeleton
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
              
          final visibleList = listItems.take(_displayLimit.value).toList();

          return Skeletonizer(
            enabled: showSkeleton,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 225,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _exportCSV,
                                  icon: SvgPicture.asset('assets/SVG/download.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                  label: const Text('Export'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    elevation: 1,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => showAddExpenseBottomSheet(context, isDark),
                                  icon: SvgPicture.asset('assets/SVG/plus.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                  label: Text('add_expense'.tr),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 1,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Search and Filter Panel
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.01),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        onChanged: (val) {
                                          _controller.searchQuery.value = val;
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Search expenses...',
                                          hintStyle: context.typography.searchHint.copyWith(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: SvgPicture.asset(
                                              'assets/SVG/search.svg',
                                              width: 18,
                                              height: 18,
                                              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: AppColors.primary.withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        // TODO: Show advanced filters
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          LucideIcons.slidersHorizontal,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          final existingCategories = _controller.allUniqueCategories;
                                          final defaultCategories = ['Software', 'Office', 'Travel', 'Marketing', 'Utilities', 'Maintenance', 'Salaries'];
                                          final allCategories = {...defaultCategories, ...existingCategories}.toList()..sort();
                                          showCategoryPickerBottomSheet(context, isDark, allCategories);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              SvgPicture.asset('assets/SVG/allcube.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Obx(
                                                  () => Text(
                                                    _controller.filterCategory.value.isEmpty ? 'All Categories' : _controller.filterCategory.value,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: context.typography.inputText.copyWith(
                                                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showMonthPicker(context, isDark),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              SvgPicture.asset('assets/SVG/calendernormal.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Obx(() {
                                                  final val = _controller.filterMonth.value;
                                                  final text = val.isEmpty ? 'All Months' : (
                                                    (DateTime.tryParse('$val-01') != null) 
                                                      ? DateFormat('MMM yyyy').format(DateTime.parse('$val-01')) 
                                                      : val
                                                  );
                                                  return Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          text,
                                                          style: context.typography.inputText.copyWith(
                                                            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
                                                    ],
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Expense Register', // Matching Invoice Register naming
                              style: context.typography.cardTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6), // slightly less rounded to match image
                                  ),
                                  child: Text(
                                    'Total: ${listItems.length}',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // View toggle (static for now to match UI exactly)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const Icon(LucideIcons.list, size: 14, color: Colors.white),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: const BoxDecoration(
                                          color: Colors.transparent,
                                        ),
                                        child: SvgPicture.asset('assets/SVG/allcube.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (listItems.isEmpty)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.fileSearch,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'no_expense_logs'.tr,
                                  style: context.typography.emptyStateDescription.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (visibleList.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == visibleList.length) {
                            return _isLoadingMore.value 
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }
                          
                          final expense = visibleList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: Key(expense.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await confirmDelete(context, isDark, _controller, expense);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(16), // Match list item border radius
                                ),
                                child: const Icon(LucideIcons.trash2, color: Colors.white),
                              ),
                              child: ExpenseListItem(
                                expense: expense,
                                isDark: isDark,
                                onTap: () => showExpenseDetailsBottomSheet(context, isDark, expense),
                                onDelete: () => confirmDelete(context, isDark, _controller, expense),
                                currencyFormat: formatCurrency,
                              ),
                            ),
                          );
                        },
                        childCount: visibleList.length + (_isLoadingMore.value ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
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
      final file = File('${directory.path}/expenses.csv');
      await file.writeAsString(buffer.toString());
      
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Exported Expenses',
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to export file.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // --- EXPENSE LIST BUILDER ---


  // --- DELETE CONFIRMATION DIALOG ---

  // --- EXPENSE DETAILS BOTTOM SHEET ---

}

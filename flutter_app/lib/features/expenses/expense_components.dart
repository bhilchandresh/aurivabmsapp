import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import 'expenses_controller.dart';\nimport 'all_expenses_screen.dart';
import '../../models/expense_model.dart'; 

final formatCurrency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class ExpenseFiltersRow extends StatelessWidget {
  final bool isDark;
  const ExpenseFiltersRow({super.key, required this.isDark});

  @override
Widget build(BuildContext context, bool isDark) {
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
    final Set<String> existingCategories = controller.expenses.map((e) {
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
                  onTap: () => showMonthPicker(context, isDark, controller),
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
                            final val = controller.filterMonth.value;
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
                        value: controller.filterCategory.value.isEmpty ? 'All Categories' : controller.filterCategory.value,
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
                              controller.filterCategory.value = '';
                            } else {
                              controller.filterCategory.value = val;
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
                        value: controller.sortBy.value,
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
                          if (val != null) controller.sortBy.value = val;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Export Button
              InkWell(
                onTap: () => exportCSV(controller),
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
                  controller.filterMonth.value = '';
                  controller.filterCategory.value = '';
                  controller.sortBy.value = 'date-desc';
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
}

class ExpenseListView extends StatelessWidget {
  final bool isDark;
  final bool showAll;
  const ExpenseListView({super.key, required this.isDark, this.showAll = false});

  @override
Widget build(BuildContext context) {\n    final controller = Get.find<ExpensesController>();
    final expenses = controller.processedExpenses;

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
              Row(
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
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: !showAll && expenses.length > 6 ? 7 : expenses.length,
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
            itemBuilder: (context, index) {
              if (!showAll && expenses.length > 6 && index == 6) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  ),
                );
              }
              final expense = expenses[index];
              return Dismissible(
                key: Key(expense.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await confirmDelete(context, isDark, controller, expense);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade500,
                  child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                ),
                child: Material(
                  color: Theme.of(context).cardTheme.color,
                  child: InkWell(
                    onTap: () => showExpenseDetailsBottomSheet(context, isDark, controller, expense),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.receipt, color: Colors.red, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  expense.category.isNotEmpty 
                                      ? '${expense.category[0].toUpperCase()}${expense.category.substring(1)}' 
                                      : 'General',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                expense.description.isNotEmpty ? expense.description : 'No Description',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.displayLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(LucideIcons.calendar, size: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(DateTime.parse(expense.date)),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.user, size: 10, color: isDark ? Colors.white : Colors.black),
                                  const SizedBox(width: 4),
                                  Text(
                                    expense.user.isNotEmpty ? expense.user : 'user',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () => confirmDelete(context, isDark, controller, expense),
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(LucideIcons.trash2, size: 16, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          ),
        ],
      ),
    );
  }
}

void showMonthPicker(BuildContext context, bool isDark, ExpensesController controller) {
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
                    controller.filterMonth.value = '';
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
                  final isSelected = controller.filterMonth.value == valStr;
                  return InkWell(
                    onTap: () {
                      controller.filterMonth.value = valStr;
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

void exportCSV(ExpensesController controller) {
    final list = controller.processedExpenses;
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

Future<bool> confirmDelete(
    BuildContext context,
    bool isDark,
    ExpensesController controller,\n    Expense expense,
  ) async {
    bool confirm = false;
    await Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        content: Text('delete_expense_confirm'.tr),
        actions: [
          Obx(() {
            final isSaving = controller.isLoading.value;
            return TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
            );
          }),
          Obx(() {
            final isSaving = controller.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final success = await controller.deleteExpense(
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

void showExpenseDetailsBottomSheet(
    BuildContext context,
    bool isDark,
    ExpensesController controller,\n    Expense expense,
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
                      confirmDelete(context, isDark, controller, expense);
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

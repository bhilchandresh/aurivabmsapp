import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../expenses_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../expense_components.dart';

  void showExpenseDetailsBottomSheet(
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
            const SizedBox(height: 16),
            
            // Top Row: Category chip & Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    expense.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
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
            const SizedBox(height: 24),
            
            // Large Initial & Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    expense.category.substring(0, min(2, expense.category.length)).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description.trim().isEmpty ? 'No Description' : expense.description,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/SVG/calendernormal.svg',
                            width: 14,
                            height: 14,
                            colorFilter: ColorFilter.mode(Colors.grey.shade500, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMMM yyyy').format(DateTime.parse(expense.date)),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Amount and Category Box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount Paid', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency.format(expense.amount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.indigo,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                expense.category.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
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
            const SizedBox(height: 12),
            
            // Description Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    ),
                    child: Icon(LucideIcons.fileText, size: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          expense.description.trim().isEmpty ? 'No Description' : expense.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.displayLarge?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Additional Details Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                    ),
                    child: Icon(LucideIcons.fileText, size: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Additional Details', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          '-',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.displayLarge?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Delete Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  confirmDelete(context, isDark, Get.find<ExpensesController>(), expense);
                },
                icon: SvgPicture.asset(
                  'assets/SVG/delete.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                ),
                label: const Text(
                  'Delete Log',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red.withValues(alpha: 0.04),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

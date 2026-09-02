import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../expenses_controller.dart';
import '../../../core/constants/app_colors.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final NumberFormat currencyFormat;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    // Determine title (category) and description
    final title = expense.category.isNotEmpty
        ? '${expense.category[0].toUpperCase()}${expense.category.substring(1)}'
        : 'General';
    final descStr = expense.description.trim();
    final description = descStr.isNotEmpty
        ? '${descStr[0].toUpperCase()}${descStr.substring(1)}'
        : 'No Description';
        
    final userStr = expense.user.trim();
    final userText = userStr.isNotEmpty 
        ? '${userStr[0].toUpperCase()}${userStr.substring(1)}' 
        : 'User';
    final dateText = DateFormat('dd MMM yyyy').format(DateTime.parse(expense.date));

    return Material(
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Optional left accent line
              Container(
                width: 3,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 14),
              
              // Information Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Metadata Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendar, size: 11, color: Theme.of(context).textTheme.bodyMedium?.color),
                        const SizedBox(width: 4),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Amount and Delete Column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(expense.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.user, size: 9, color: isDark ? Colors.white70 : Colors.black87),
                        const SizedBox(width: 4),
                        Text(
                          userText,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

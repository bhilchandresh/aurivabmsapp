import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../expenses_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_extensions.dart';

class ExpenseListItem extends StatefulWidget {
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
  State<ExpenseListItem> createState() => _ExpenseListItemState();
}

class _ExpenseListItemState extends State<ExpenseListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.expense.category.isNotEmpty
        ? '${widget.expense.category[0].toUpperCase()}${widget.expense.category.substring(1)}'
        : 'General';
        
    final descStr = widget.expense.description.trim();
    final description = descStr.isNotEmpty
        ? '${descStr[0].toUpperCase()}${descStr.substring(1)}'
        : 'No Description';
        
    String formattedDate = widget.expense.date;
    try {
      if (widget.expense.date.isNotEmpty) {
        final parsed = DateTime.parse(widget.expense.date);
        formattedDate = DateFormat('dd MMM yyyy').format(parsed);
      }
    } catch (_) {}
    
    Color getCategoryColor(String cat) {
      final c = cat.toLowerCase();
      if (c.contains('salary')) return Colors.blue;
      if (c.contains('rent') || c.contains('maintenance')) return Colors.orange;
      if (c.contains('util')) return Colors.cyan;
      if (c.contains('travel') || c.contains('fuel')) return Colors.purple;
      if (c.contains('equip')) return Colors.teal;
      return AppColors.success; // Default to green to match image's PAID status
    }
    
    final categoryColor = getCategoryColor(category);
    
    String displayId = widget.expense.id;
    if (displayId.length > 8) {
      displayId = displayId.substring(0, 4).toUpperCase();
    }
    displayId = 'EXP-$displayId';

    return InkWell(
      onTap: widget.onTap,
      onHover: (hovering) {
        setState(() {
          _isHovered = hovering;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? categoryColor.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? categoryColor.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.01),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/SVG/dollar.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(categoryColor, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.toUpperCase(),
                            style: context.typography.invoiceNumber.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),

                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          widget.currencyFormat.format(widget.expense.amount),
                          style: context.typography.invoiceAmount.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.7,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      description,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/SVG/calendernormal.svg',
                            width: 13,
                            height: 13,
                            colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: context.typography.dueDate.copyWith(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionIcon('assets/SVG/delete.svg', 'Delete', onTap: widget.onDelete, iconColor: Colors.red),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(String iconPath, String tooltip, {VoidCallback? onTap, Color? iconColor}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: SvgPicture.asset(
            iconPath,
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(iconColor ?? Colors.grey.shade700, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

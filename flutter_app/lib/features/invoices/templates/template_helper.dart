import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'invoice_template_params.dart';

Widget buildTableCell(
  String text,
  TextStyle style, {
  bool isHeader = false,
  TextAlign align = TextAlign.left,
  bool useSerif = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: 10.0,
      vertical: isHeader ? 8.0 : 10.0,
    ),
    child: Text(
      text,
      style: style.copyWith(fontFamily: useSerif ? 'serif' : null),
      textAlign: align,
    ),
  );
}

Widget buildItemTable({
  required InvoiceTemplateParams params,
  required Color headerBgColor,
  required TextStyle textStyle,
  bool isSerif = false,
  List<Map<String, dynamic>>? items,
}) {
  final list = items ?? params.items;
  final isTransparent = headerBgColor == Colors.transparent;

  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: isTransparent ? Colors.transparent : Colors.black12,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(4),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2.5),
        },
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(color: headerBgColor),
            children: [
              buildTableCell(
                'Description',
                textStyle,
                isHeader: true,
                useSerif: isSerif,
              ),
              buildTableCell(
                'Qty',
                textStyle,
                isHeader: true,
                align: TextAlign.center,
                useSerif: isSerif,
              ),
              buildTableCell(
                'Rate',
                textStyle,
                isHeader: true,
                align: TextAlign.right,
                useSerif: isSerif,
              ),
              buildTableCell(
                'Amount',
                textStyle,
                isHeader: true,
                align: TextAlign.right,
                useSerif: isSerif,
              ),
            ],
          ),
          // Data Rows
          ...list.map((item) {
            final double qty = ((item['quantity'] ?? 1) as num).toDouble();
            final double rate = ((item['rate'] ?? 0.0) as num).toDouble();
            final double amount = qty * rate;
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isTransparent
                        ? Colors.black.withOpacity(0.05)
                        : Colors.black12,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['description'] as String? ?? 'Item',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: isSerif ? 'serif' : null,
                        ),
                      ),
                      if (item['additionalDetails'] != null &&
                          (item['additionalDetails'] as String)
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item['additionalDetails'] as String,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.black54,
                            height: 1.2,
                            fontFamily: isSerif ? 'serif' : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                buildTableCell(
                  qty % 1 == 0
                      ? qty.toStringAsFixed(0)
                      : qty.toStringAsFixed(2),
                  TextStyle(fontSize: 10, fontFamily: isSerif ? 'serif' : null),
                  align: TextAlign.center,
                ),
                buildTableCell(
                  params.formatCurrency.format(rate),
                  TextStyle(fontSize: 10, fontFamily: isSerif ? 'serif' : null),
                  align: TextAlign.right,
                ),
                buildTableCell(
                  params.formatCurrency.format(amount),
                  TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: isSerif ? 'serif' : null,
                  ),
                  align: TextAlign.right,
                ),
              ],
            );
          }),
        ],
      ),
    ),
  );
}

Widget buildDynamicScreenSummarySection({
  required InvoiceTemplateParams params,
  Color? primaryColor,
  bool useSerif = false,
  bool isVibrant = false,
  bool isMinimalist = false,
}) {
  String place = params.placeOfSupply.toLowerCase();
  bool isOutstate =
      place.isNotEmpty &&
      (params.tenant['state'] != null
          ? (!place.contains(params.tenant['state']!.toString().toLowerCase()))
          : (!place.contains("telangana") && !place.contains("36")));
  final activeColor = primaryColor ?? AppColors.primary;

  Widget buildRow(String label, String amount, {bool isGrandTotal = false}) {
    if (isVibrant) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isGrandTotal ? 12 : 11,
                fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
                color: Colors.white70,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: isGrandTotal ? 14 : 11,
                fontWeight: isGrandTotal ? FontWeight.w900 : FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Builder(builder: (context) {
      final labelStyle = TextStyle(
        fontSize: isGrandTotal ? 12 : 11,
        fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
        color: isGrandTotal ? (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black) : Colors.grey,
        fontFamily: useSerif ? 'serif' : null,
      );
      final valueStyle = TextStyle(
        fontSize: isGrandTotal ? 14 : 11,
        fontWeight: isGrandTotal ? FontWeight.w900 : FontWeight.bold,
        color: isGrandTotal
            ? (isMinimalist ? Colors.black : activeColor)
            : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
        fontFamily: useSerif ? 'serif' : null,
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: labelStyle),
            Text(amount, style: valueStyle),
          ],
        ),
      );
    });
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      buildRow('Subtotal', params.formatCurrency.format(params.subtotal)),
      if (params.discountAmount > 0)
        buildRow(
          'Discount (${params.discountPercentage.toStringAsFixed(0)}%)',
          '- ${params.formatCurrency.format(params.discountAmount)}',
        ),
      if (params.gstEnabled && params.taxAmount > 0) ...[
        if (isOutstate)
          buildRow('IGST', params.formatCurrency.format(params.taxAmount))
        else ...[
          buildRow('CGST', params.formatCurrency.format(params.taxAmount / 2)),
          buildRow('SGST', params.formatCurrency.format(params.taxAmount / 2)),
        ],
      ],
      if (!isVibrant)
        Divider(
          thickness: isMinimalist ? 1.5 : 1,
          color: isMinimalist
              ? Colors.black87
              : (useSerif ? Colors.amber : Colors.black12),
        ),
      buildRow(
        useSerif ? 'GRAND TOTAL' : 'Grand Total',
        params.formatCurrency.format(params.total),
        isGrandTotal: true,
      ),
    ],
  );
}

Widget buildFooterSection(InvoiceTemplateParams params) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Divider(),
      const SizedBox(height: 6),
      Text(
        'TERMS & CONDITIONS',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        params.tenant['defaultTerms'] ?? '',
        style: TextStyle(fontSize: 8, color: Colors.grey, height: 1.3),
      ),
    ],
  );
}

String convertNumberToWords(double amount) {
  if (amount <= 0) return "Rupees Zero Only";

  final List<String> words = [
    "Zero",
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "Nine",
    "Ten",
    "Eleven",
    "Twelve",
    "Thirteen",
    "Fourteen",
    "Fifteen",
    "Sixteen",
    "Seventeen",
    "Eighteen",
    "Nineteen",
  ];
  final List<String> tens = [
    "",
    "",
    "Twenty",
    "Thirty",
    "Forty",
    "Fifty",
    "Sixty",
    "Seventy",
    "Eighty",
    "Ninety",
  ];

  String numToWords(int n) {
    if (n == 0) return "";
    if (n < 20) return words[n];
    if (n < 100) {
      return tens[n ~/ 10] + (n % 10 != 0 ? " ${words[n % 10]}" : "");
    }
    if (n < 1000) {
      return "${words[n ~/ 100]} Hundred${n % 100 != 0 ? " and ${numToWords(n % 100)}" : ""}";
    }
    if (n < 100000) {
      return "${numToWords(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${numToWords(n % 1000)}" : ""}";
    }
    if (n < 10000000) {
      return "${numToWords(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${numToWords(n % 100000)}" : ""}";
    }
    return "${numToWords(n ~/ 10000000)} Crore${n % 10000000 != 0 ? " ${numToWords(n % 10000000)}" : ""}";
  }

  final int rupees = amount.floor();
  final int paise = ((amount - rupees) * 100).round();

  String res = "Rupees ${rupees == 0 ? "Zero" : numToWords(rupees)}";
  if (paise > 0) {
    res += " and ${numToWords(paise)} Paise";
  }
  return "$res Only";
}

Widget buildBottomFooter(int currentPage, int totalPages) {
  return Column(
    children: [
      Divider(height: 1, color: Colors.black12),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Thank you for your business! Generated via Auriva BMS.',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            'Page $currentPage of $totalPages',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}

String formatCleanDate(String dateStr) {
  if (dateStr.isEmpty) return dateStr;

  DateTime? parsed = DateTime.tryParse(dateStr);

  if (parsed == null) {
    String cleaned = dateStr
        .replaceAll(',', ' ')
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .trim();

    List<String> parts = cleaned.split(' ').where((s) => s.isNotEmpty).toList();

    const Map<String, int> monthMap = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };

    int? month;
    int? day;
    int? year;

    for (var part in parts) {
      String low = part.toLowerCase();
      if (monthMap.containsKey(low)) {
        month = monthMap[low];
      } else {
        int? val = int.tryParse(part);
        if (val != null) {
          if (val >= 1000) {
            year = val;
          } else {
            if (day == null) {
              day = val;
            } else if (month == null) {
              month = day;
              day = val;
            }
          }
        }
      }
    }

    if (year != null && month != null && day != null) {
      parsed = DateTime(year, month, day);
    } else if (parts.length == 3) {
      int? p1 = int.tryParse(parts[0]);
      int? p2 = int.tryParse(parts[1]);
      int? p3 = int.tryParse(parts[2]);
      if (p1 != null && p2 != null && p3 != null) {
        if (p1 > 1000) {
          parsed = DateTime(p1, p2, p3);
        } else if (p3 > 1000) {
          if (p1 <= 12 && p2 <= 12) {
            parsed = DateTime(p3, p1, p2);
          } else if (p1 > 12) {
            parsed = DateTime(p3, p2, p1);
          } else {
            parsed = DateTime(p3, p1, p2);
          }
        }
      }
    }
  }

  if (parsed != null) {
    return "${parsed.day}/${parsed.month}/${parsed.year}";
  }

  return dateStr;
}

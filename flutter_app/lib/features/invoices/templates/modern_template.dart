// ignore_for_file: unused_element, unused_local_variable
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import '../../auth/auth_controller.dart';
import '../../team/team_controller.dart';
import 'invoice_template_params.dart';
import 'template_helper.dart';

class ModernTemplate extends StatelessWidget {
  final InvoiceTemplateParams params;
  final List<Map<String, dynamic>>? pageItems;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageIndex;
  final int totalPages;
  final bool isOffline;

  const ModernTemplate({
    super.key,
    required this.params,
    this.pageItems,
    this.isFirstPage = true,
    this.isLastPage = true,
    this.pageIndex = 0,
    this.totalPages = 1,
    this.isOffline = false,
  });

  Widget? _buildLogoWidget(
    String? logoImage, {
    double height = 50,
    bool invert = false,
  }) {
    if (logoImage == null || logoImage.isEmpty) {
      return null;
    }

    final imageColor = invert ? Colors.white : null;
    final blendMode = invert ? BlendMode.srcIn : null;

    if (logoImage.startsWith('data:image') || !logoImage.startsWith('http')) {
      try {
        final base64Str = logoImage.contains(',')
            ? logoImage.split(',')[1]
            : logoImage;
        return Image.memory(
          base64Decode(base64Str),
          height: height,
          fit: BoxFit.contain,
          color: imageColor,
          colorBlendMode: blendMode,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      } catch (e) {
        return null;
      }
    } else {
      return Image.network(
        logoImage,
        height: height,
        fit: BoxFit.contain,
        color: imageColor,
        colorBlendMode: blendMode,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }
  }

  Widget _buildPaymentRow(String label, String value, {bool isMono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsCard() {
    final bank = params.bankDetails;
    final hasBank =
        bank['accountNumber'] != null &&
        bank['accountNumber']!.toString().isNotEmpty;

    Widget buildCardRow(String label, String value, {bool isMono = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
                fontFamily: isMono ? 'monospace' : null,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            padding: const EdgeInsets.only(bottom: 6),
            margin: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.creditCard,
                  color: Colors.grey,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'PAYMENT DETAILS',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (hasBank) ...[
            if (bank['accountName'] != null &&
                bank['accountName']!.toString().isNotEmpty)
              buildCardRow('Name:', bank['accountName']!.toString()),
            buildCardRow('Bank:', bank['bankName']?.toString() ?? ''),
            buildCardRow(
              'Acc No:',
              bank['accountNumber']?.toString() ?? '',
              isMono: true,
            ),
            buildCardRow(
              'IFSC:',
              bank['ifscCode']?.toString() ?? '',
              isMono: true,
            ),
          ] else
            const Text(
              'No payment details available.',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsList = pageItems ?? params.items;
    final showHsn = itemsList.any(
      (item) =>
          item['hsnCode'] != null &&
          item['hsnCode'].toString().trim().isNotEmpty,
    );

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Solid Dark Slate)
          if (isFirstPage) ...[
            Container(
              decoration: const BoxDecoration(color: Color(0xFF0F172A)),
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Logo & Company Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (params.tenant['logoImage'] != null &&
                            params.tenant['logoImage']!.isNotEmpty) ...[
                          // Render logo in original colors (invert: false) or white? Web uses brightness-0 invert
                          _buildLogoWidget(
                                params.tenant['logoImage'],
                                height: 40,
                                invert: false,
                              ) ??
                              const SizedBox.shrink(),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          (params.tenant['name'] ?? '').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if ((params.tenant['address'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  color: Colors.white70,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    params.tenant['address']!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((params.tenant['email'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.mail,
                                      color: Colors.white70,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      params.tenant['email']!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if ((params.tenant['phone'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.phone,
                                      color: Colors.white70,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      params.tenant['phone']!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if ((params.tenant['website'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.globe,
                                      color: Colors.white70,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      params.tenant['website']!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (params.gstEnabled &&
                            (params.tenant['gstNumber'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'GSTIN: ${params.tenant['gstNumber']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right: Invoice Metadata
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          params.numberLabel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        params.invoiceId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          text: 'Date: ',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                              text: formatCleanDate(params.date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          text:
                              '${params.numberLabel.contains('Quote') ? 'Valid' : 'Due'}: ',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                              text: formatCleanDate(params.dueDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
          ] else ...[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF334155)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${params.numberLabel}: #${params.invoiceId}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Date: ${formatCleanDate(params.date)}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],

          // Main body elements (Inner Padding wrapper)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirstPage) ...[
                  // Client & Payment Info Blocks
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Client Details (Left)
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.user,
                                  color: Colors.grey,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  params.numberLabel.contains('Quote')
                                      ? 'QUOTE TO'
                                      : 'BILLED TO',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              params.clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (params.clientAddress.isNotEmpty)
                              Text(
                                params.clientAddress,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                            if (params.clientEmail.isNotEmpty)
                              Text(
                                params.clientEmail,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            if (params.clientPhone.isNotEmpty)
                              Text(
                                params.clientPhone,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            if (params.gstEnabled &&
                                params.clientGst.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'GSTIN: ${params.clientGst}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Payment Details Card (Right)
                      Expanded(flex: 5, child: _buildPaymentDetailsCard()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Custom Items Table matching web styling (encased in a border box)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: _buildItemTable(itemsList, showHsn),
                  ),
                ),

                if (isLastPage) ...[
                  const SizedBox(height: 24),
                  // Totals section (Amount in Words left, Financial summary right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount in words
                      Expanded(
                        flex: 6,
                        child: DashedBorderContainer(
                          backgroundColor: const Color(0xFFF8FAFC),
                          color: const Color(0xFFE2E8F0),
                          borderRadius: 8.0,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL AMOUNT (IN WORDS)',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                convertNumberToWords(params.total),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Summary box
                      Expanded(flex: 5, child: _buildSummaryBox()),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Spacer pushes footer elements to bottom of the template
          const Spacer(),

          if (isLastPage) ...[
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: _buildTermsAndConditionsBox(),
            ),
          ],
          // Bottom Address Bar (Full-width dark bar)
          Container(
            color: const Color(0xFF0F172A),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: const Text(
              'THANK YOU FOR YOUR BUSINESS!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Page Numbering for offline PDF downloads
          if (isOffline) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thank you for your business! Generated via Auriva BMS.',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    'Page ${pageIndex + 1} of $totalPages',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox.shrink(),
          ],
        ],
      ),
    );
  }

  Widget _buildItemTable(List<Map<String, dynamic>> itemsList, bool showHsn) {
    final columnWidths = showHsn
        ? const {
            0: FlexColumnWidth(0.6), // #
            1: FlexColumnWidth(3.4), // Description
            2: FlexColumnWidth(1.5), // HSN/SAC
            3: FlexColumnWidth(1.0), // Qty
            4: FlexColumnWidth(1.5), // Rate
            5: FlexColumnWidth(2.0), // Total
          }
        : const {
            0: FlexColumnWidth(0.6), // #
            1: FlexColumnWidth(4.9), // Description
            2: FlexColumnWidth(1.0), // Qty
            3: FlexColumnWidth(1.5), // Rate
            4: FlexColumnWidth(2.0), // Total
          };

    final headerStyle = const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: Color(0xFF0F172A),
      letterSpacing: 0.5,
    );

    return Table(
      columnWidths: columnWidths,
      children: [
        // Header Row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
          children: [
            _buildHeaderCell(
              '#',
              headerStyle,
              align: TextAlign.center,
              hasBorder: true,
            ),
            _buildHeaderCell('DESCRIPTION', headerStyle, hasBorder: true),
            if (showHsn)
              _buildHeaderCell(
                'HSN/SAC',
                headerStyle,
                align: TextAlign.center,
                hasBorder: true,
              ),
            _buildHeaderCell(
              'QTY',
              headerStyle,
              align: TextAlign.center,
              hasBorder: true,
            ),
            _buildHeaderCell(
              'RATE',
              headerStyle,
              align: TextAlign.right,
              hasBorder: true,
            ),
            _buildHeaderCell(
              'TOTAL',
              headerStyle,
              align: TextAlign.right,
              hasBorder: true,
            ),
          ],
        ),
        // Data Rows
        ...List.generate(itemsList.length, (index) {
          final item = itemsList[index];
          final double qty = ((item['quantity'] ?? 1) as num).toDouble();
          final double rate = ((item['rate'] ?? 0.0) as num).toDouble();
          final double amount = qty * rate;
          final isLastRow = index == itemsList.length - 1;

          return TableRow(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isLastRow
                      ? Colors.transparent
                      : const Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
            ),
            children: [
              // #
              _buildDataCell(
                (index + 1).toString(),
                const TextStyle(fontSize: 10, color: Colors.grey),
                align: TextAlign.center,
              ),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['description'] as String? ?? 'Item',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (item['additionalDetails'] != null &&
                        (item['additionalDetails'] as String)
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item['additionalDetails'] as String,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // HSN/SAC
              if (showHsn)
                _buildDataCell(
                  item['hsnCode']?.toString() ?? '-',
                  const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                  align: TextAlign.center,
                ),
              // Qty
              _buildDataCell(
                qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2),
                const TextStyle(fontSize: 10, color: Colors.black87),
                align: TextAlign.center,
              ),
              // Rate
              _buildDataCell(
                params.formatCurrency.format(rate),
                const TextStyle(fontSize: 10, color: Colors.black87),
                align: TextAlign.right,
              ),
              // Total
              _buildDataCell(
                params.formatCurrency.format(amount),
                const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                align: TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(
    String text,
    TextStyle style, {
    TextAlign align = TextAlign.left,
    bool hasBorder = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: hasBorder
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      child: Text(text, style: style, textAlign: align),
    );
  }

  Widget _buildDataCell(
    String text,
    TextStyle style, {
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      child: Text(text, style: style, textAlign: align),
    );
  }

  Widget _buildSummaryBox() {
    final String place = params.placeOfSupply.toLowerCase();
    final bool isOutstate =
        place.isNotEmpty &&
        !place.contains("telangana") &&
        !place.contains("36");

    final double taxableAmount =
        (params.taxType == 'inclusive' && params.gstEnabled)
        ? (params.subtotal - params.discountAmount - params.taxAmount)
        : (params.subtotal - params.discountAmount);

    Widget buildRow(
      String label,
      String value, {
      bool isTotal = false,
      Color labelColor = const Color(0xFF64748B),
      Color valueColor = const Color(0xFF0F172A),
      FontWeight labelWeight = FontWeight.normal,
      FontWeight valueWeight = FontWeight.w600,
      double fontSize = 10,
      double valueFontSize = 10,
    }) {
      if (isTotal) {
        labelWeight = FontWeight.w900;
        valueWeight = FontWeight.w900;
        labelColor = const Color(0xFF0F172A);
        valueColor = const Color(0xFF0F172A);
        fontSize = 12;
        valueFontSize = 14;
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: labelWeight,
                color: labelColor,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: valueWeight,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildRow(
                'Subtotal',
                params.formatCurrency.format(params.subtotal),
              ),
              if (params.discountAmount > 0)
                buildRow(
                  'Discount (${params.discountPercentage.toStringAsFixed(0)}%)',
                  '- ${params.formatCurrency.format(params.discountAmount)}',
                  labelColor: const Color(0xFFEF4444),
                  valueColor: const Color(0xFFEF4444),
                ),

              if (params.discountAmount > 0) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 1,
                  child: CustomPaint(
                    painter: _DashedLinePainter(color: const Color(0xFFCBD5E1)),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              if (params.gstEnabled && params.taxAmount > 0) ...[
                buildRow(
                  'Taxable Amount',
                  params.formatCurrency.format(taxableAmount),
                  labelWeight: FontWeight.bold,
                  labelColor: const Color(0xFF0F172A),
                  valueWeight: FontWeight.bold,
                ),
                buildRow(
                  'CGST',
                  '+ ${params.formatCurrency.format(params.taxAmount / 2)}',
                  labelColor: const Color(0xFF64748B),
                  valueColor: const Color(0xFF64748B),
                  valueWeight: FontWeight.normal,
                ),
                buildRow(
                  'SGST',
                  '+ ${params.formatCurrency.format(params.taxAmount / 2)}',
                  labelColor: const Color(0xFF64748B),
                  valueColor: const Color(0xFF64748B),
                  valueWeight: FontWeight.normal,
                ),
              ],

              const SizedBox(height: 6),
              Container(height: 1, color: const Color(0xFFE2E8F0)),
              const SizedBox(height: 6),

              buildRow(
                'TOTAL',
                params.formatCurrency.format(params.total),
                isTotal: true,
              ),

              if (params.advancePayment > 0) ...[
                buildRow(
                  'Advance Paid',
                  '- ${params.formatCurrency.format(params.advancePayment)}',
                  labelColor: const Color(0xFF10B981),
                  valueColor: const Color(0xFF10B981),
                  labelWeight: FontWeight.bold,
                  valueWeight: FontWeight.bold,
                ),
              ],

              const SizedBox(height: 6),
              Container(height: 1.5, color: const Color(0xFF0F172A)),
              const SizedBox(height: 6),

              buildRow(
                'Balance Due',
                params.formatCurrency.format(
                  params.total - params.advancePayment,
                ),
                labelWeight: FontWeight.bold,
                labelColor: const Color(0xFF0F172A),
                valueWeight: FontWeight.bold,
                fontSize: 11,
                valueFontSize: 12,
              ),
            ],
          ),
        ),
        _buildSignatureBlock(),
      ],
    );
  }

  Widget _buildSignatureBlock() {
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    final TeamController teamController = Get.isRegistered<TeamController>()
        ? Get.find<TeamController>()
        : Get.put(TeamController());

    return Obx(() {
      final currentUserMember = teamController.teamMembers.firstWhereOrNull(
        (m) =>
            m.email.trim().toLowerCase() ==
            authController.userEmail.value.trim().toLowerCase(),
      );
      final userSignature =
          (currentUserMember?.signatureImage != null &&
              currentUserMember!.signatureImage!.isNotEmpty)
          ? currentUserMember.signatureImage
          : (authController.userSignature.value.isNotEmpty
                ? authController.userSignature.value
                : null);

      final signatureWidget = _buildLogoWidget(
        (userSignature != null && userSignature.isNotEmpty)
            ? userSignature
            : params.tenant['signatureImage'],
        height: 35,
      );

      return Container(
        margin: const EdgeInsets.only(top: 12),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (signatureWidget != null) ...[
              signatureWidget,
              const SizedBox(height: 4),
            ] else ...[
              Container(
                height: 35,
                width: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[200]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Text(
                  'Sign Here',
                  style: TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Container(width: 130, height: 1, color: Colors.grey[300]!),
            const SizedBox(height: 4),
            Text(
              params.tenant['authorizedSignatoryName'] ??
                  params.tenant['name'] ??
                  '',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'AUTHORIZED SIGNATORY',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTermsAndConditionsBox() {
    final terms = params.tenant['defaultTerms'] ?? '';
    if (terms.trim().isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              LucideIcons.fileText,
              color: Color(0xFF64748B),
              size: 12,
            ),
            SizedBox(width: 4),
            Text(
              'TERMS & CONDITIONS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          terms,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.black54,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (params.placeOfSupply.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Place of Supply: ${params.placeOfSupply}${params.tenant["state"] != null && params.tenant["state"]!.isNotEmpty ? " | Dispatch State: ${params.tenant["state"]}" : ""}',
            style: const TextStyle(
              fontSize: 8,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const DashedBorderContainer({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(12.0),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: color,
        borderRadius: borderRadius,
        strokeWidth: 1.0,
        gap: 3.0,
        dashLength: 4.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
    this.dashLength = 4.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashedPath = Path();
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashWidth = 4.0;
    final dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

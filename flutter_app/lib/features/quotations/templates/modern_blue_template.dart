import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import '../../auth/auth_controller.dart';
import '../../team/team_controller.dart';
import 'quotation_template_params.dart';
import 'template_helper.dart';

class ModernBlueTemplate extends StatelessWidget {
  final QuotationTemplateParams params;
  final List<Map<String, dynamic>>? pageItems;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageIndex;
  final int totalPages;
  final bool isOffline;

  const ModernBlueTemplate({
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
            style: TextStyle(
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
              color: Color(0xFF0F172A),
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ),
      ],
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
          // Header (Dark Slate to Royal Blue Gradient)
          if (isFirstPage) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
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
                          style: TextStyle(
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
                                Icon(
                                  LucideIcons.mapPin,
                                  color: Colors.white70,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    params.tenant['address']!,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if ((params.tenant['email'] ?? '').isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.mail,
                                    color: Colors.white70,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    params.tenant['email']!,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            if ((params.tenant['phone'] ?? '').isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.phone,
                                    color: Colors.white70,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    params.tenant['phone']!,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            if ((params.tenant['website'] ?? '').isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.globe,
                                    color: Colors.white70,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    params.tenant['website']!,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
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
                                style: TextStyle(
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
                  // Right: Quotation Metadata
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          params.numberLabel.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        params.quotationId,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          text: 'Issued: ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                              text: formatCleanDate(params.date),
                              style: TextStyle(
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
                              '${params.documentTitle == 'QUOTATION' ? 'Valid Until' : 'Due Date'}: ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                              text: formatCleanDate(params.dueDate),
                              style: TextStyle(
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${params.numberLabel}: #${params.quotationId}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Date: ${formatCleanDate(params.date)}',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
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
                            Container(
                              padding: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFDBEAFE),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.user,
                                    color: Color(0xFF1E40AF),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    params.numberLabel.contains('Quote')
                                        ? 'QUOTE TO'
                                        : 'BILLED TO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E40AF),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              params.clientName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (params.clientAddress.isNotEmpty)
                              Text(
                                params.clientAddress,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                            if (params.clientEmail.isNotEmpty)
                              Text(
                                params.clientEmail,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            if (params.clientPhone.isNotEmpty)
                              Text(
                                params.clientPhone,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            if (params.gstEnabled &&
                                params.clientGst.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'GSTIN: ${params.clientGst}',
                                style: TextStyle(
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
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFD1FAE5),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.creditCard,
                                    color: Color(0xFF047857),
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'PAYMENT INFO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF047857),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (params.bankDetails['accountNumber'] != null &&
                                params.bankDetails['accountNumber']
                                    .toString()
                                    .isNotEmpty) ...[
                              if (params.bankDetails['accountName'] != null &&
                                  params.bankDetails['accountName']
                                      .toString()
                                      .isNotEmpty) ...[
                                _buildPaymentRow(
                                  'Name:',
                                  params.bankDetails['accountName'].toString(),
                                ),
                                const SizedBox(height: 4),
                              ],
                              _buildPaymentRow(
                                'Bank:',
                                params.bankDetails['bankName'].toString(),
                              ),
                              const SizedBox(height: 4),
                              _buildPaymentRow(
                                'Acc No:',
                                params.bankDetails['accountNumber'].toString(),
                                isMono: true,
                              ),
                              const SizedBox(height: 4),
                              if (params.bankDetails['ifscCode'] != null &&
                                  params.bankDetails['ifscCode']
                                      .toString()
                                      .isNotEmpty)
                                _buildPaymentRow(
                                  'IFSC:',
                                  params.bankDetails['ifscCode'].toString(),
                                  isMono: true,
                                ),
                            ] else ...[
                              Text(
                                'No payment details available.',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            if (params.gstEnabled &&
                                (params.tenant['gstNumber'] ?? '')
                                    .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Co. GSTIN: ${params.tenant['gstNumber']}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Custom Items Table matching web styling (encased in a border box)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFE2E8F0)),
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            border: Border.all(color: Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                                style: TextStyle(
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

          // Footer container with white background and horizontal padding
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLastPage) _buildTermsAndConditionsBox(),
                const SizedBox(height: 8),
                // Brand bar at bottom (Gradient line with rounded corners)
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Bottom Address Bar
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    ((params.tenant['address'] != null &&
                                params.tenant['address']!.trim().isNotEmpty)
                            ? params.tenant['address']!
                            : 'Thank you for your business!')
                        .replaceAll('\n', ', ')
                        .toUpperCase(),
                    style: TextStyle(
                      color: Color(0xFF64748B), // A nice greyish-blue color
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Page Numbering for offline PDF downloads
          if (isOffline) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
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
                    'Page ${pageIndex + 1} of $totalPages',
                    style: TextStyle(
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

    final headerStyle = TextStyle(
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
          decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
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
              'AMOUNT',
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
                      : Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
            ),
            children: [
              // #
              _buildDataCell(
                (index + 1).toString(),
                TextStyle(fontSize: 10, color: Colors.grey),
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
                      style: TextStyle(
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
                        style: TextStyle(
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
                  TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                  align: TextAlign.center,
                ),
              // Qty
              _buildDataCell(
                qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2),
                TextStyle(fontSize: 10, color: Colors.black87),
                align: TextAlign.center,
              ),
              // Rate
              _buildDataCell(
                params.formatCurrency.format(rate),
                TextStyle(fontSize: 10, color: Colors.black87),
                align: TextAlign.right,
              ),
              // Total
              _buildDataCell(
                params.formatCurrency.format(amount),
                TextStyle(
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
            ? Border(
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
    final double taxableAmount =
        (params.taxType == 'inclusive' && params.gstEnabled)
        ? (params.subtotal - params.discountAmount - params.taxAmount)
        : (params.subtotal - params.discountAmount);

    Widget buildRow(
      String label,
      String value, {
      bool isTotal = false,
      Color? labelColor,
      Color? valueColor,
      FontWeight? labelWeight,
      FontWeight? valueWeight,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 11 : 10,
                fontWeight:
                    labelWeight ??
                    (isTotal ? FontWeight.bold : FontWeight.normal),
                color:
                    labelColor ??
                    (isTotal
                        ? Color(0xFF0F172A)
                        : Color(0xFF475569)),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 12 : 10,
                fontWeight:
                    valueWeight ??
                    (isTotal ? FontWeight.w900 : FontWeight.w500),
                color:
                    valueColor ??
                    (isTotal
                        ? Color(0xFF1D4ED8)
                        : Color(0xFF0F172A)),
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
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE2E8F0)),
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
                  labelColor: Colors.red[600],
                  valueColor: Colors.red[600],
                  labelWeight: FontWeight.w500,
                  valueWeight: FontWeight.w500,
                ),
              if (params.gstEnabled && params.taxAmount > 0) ...[
                buildRow(
                  'Taxable',
                  params.formatCurrency.format(taxableAmount),
                ),
                buildRow(
                  'CGST',
                  params.formatCurrency.format(params.taxAmount / 2),
                  labelColor: Color(0xFF64748B),
                  valueColor: Color(0xFF64748B),
                ),
                buildRow(
                  'SGST',
                  params.formatCurrency.format(params.taxAmount / 2),
                  labelColor: Color(0xFF64748B),
                  valueColor: Color(0xFF64748B),
                ),
              ],
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: buildRow(
                  'TOTAL',
                  params.formatCurrency.format(params.total),
                  isTotal: true,
                ),
              ),
              if (params.advancePayment > 0) ...[
                buildRow(
                  'Advance Paid',
                  '- ${params.formatCurrency.format(params.advancePayment)}',
                  labelColor: Colors.green[800],
                  valueColor: Colors.green[800],
                  labelWeight: FontWeight.bold,
                  valueWeight: FontWeight.bold,
                ),
                const SizedBox(height: 2),
                buildRow(
                  'Balance Due',
                  params.formatCurrency.format(
                    params.total - params.advancePayment,
                  ),
                  labelColor: Color(0xFF0F172A),
                  valueColor: Color(0xFF0F172A),
                  labelWeight: FontWeight.w900,
                  valueWeight: FontWeight.w900,
                ),
              ],
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
                child: Text(
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
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.fileText,
                color: Color(0xFF64748B),
                size: 12,
              ),
              const SizedBox(width: 4),
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
            style: TextStyle(
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
              'Place of Supply: ${params.placeOfSupply}${params.tenant['state'] != null && params.tenant['state']!.isNotEmpty ? ' | Dispatch State: ${params.tenant['state']}' : ''}',
              style: TextStyle(
                fontSize: 8,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

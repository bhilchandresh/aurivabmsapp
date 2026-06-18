import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/auth_controller.dart';
import 'quotation_template_params.dart';
import 'template_helper.dart';

class VibrantTemplate extends StatelessWidget {
  final QuotationTemplateParams params;
  final List<Map<String, dynamic>>? pageItems;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageIndex;
  final int totalPages;
  final bool isOffline;

  const VibrantTemplate({
    super.key,
    required this.params,
    this.pageItems,
    this.isFirstPage = true,
    this.isLastPage = true,
    this.pageIndex = 0,
    this.totalPages = 1,
    this.isOffline = false,
  });

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return dateStr;
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        return "${parsed.month}/${parsed.day}/${parsed.year}"; 
      }
    } catch (_) {}
    return dateStr.replaceAll('-', '/');
  }

  @override
  Widget build(BuildContext context) {
    final paddingValue = isOffline ? 40.0 : 38.0;
    final itemsList = pageItems ?? params.items;
    final bool hasLastItem = itemsList.isNotEmpty && params.items.isNotEmpty && itemsList.last == params.items.last;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstPage) _buildHeader(),
          if (!isFirstPage) _buildCompactHeader(),
          
          if (isFirstPage) ...[
            const SizedBox(height: 24),
            _buildClientAndPaymentInfo(),
            const SizedBox(height: 24),
          ],
          
          if (itemsList.isNotEmpty)
            _buildItemsTable(itemsList),
          
          if (hasLastItem) ...[
            const SizedBox(height: 24),
            _buildTotalsSection(),
          ],
          
          if (isLastPage) ...[
            if (!hasLastItem) const SizedBox(height: 24),
            const SizedBox(height: 16),
            _buildSignatorySection(),
          ],
          
          const Spacer(),
          if (isLastPage) _buildTermsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final tenant = params.tenant;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFC026D3)], // violet-600 to fuchsia-600
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side
          Expanded(
            flex: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((tenant['logoImage'] ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildLogoWidget(tenant['logoImage'], height: 40, fit: BoxFit.contain),
                  ),
                Text(
                  (tenant['name'] ?? ''),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                if ((tenant['address'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tenant['address'] ?? '',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 6), // GAP REDUCED
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((tenant['email'] ?? '').isNotEmpty) _buildHeaderPill(Icons.email, tenant['email']!),
                    if ((tenant['phone'] ?? '').isNotEmpty) _buildHeaderPill(Icons.phone, tenant['phone']!),
                  ],
                ),
                if (params.gstEnabled && (tenant['gstNumber'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'GSTIN: ${tenant['gstNumber']}',
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Right Side
          Expanded(
            flex: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    params.documentTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6D28D9), // violet-700
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '#${params.quotationId}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Date: ', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.9))),
                          Text(_formatDate(params.date), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${params.documentTitle == "QUOTATION" ? "Valid Until" : "Due Date"}: ', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.9))),
                          Text(_formatDate(params.dueDate), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${params.numberLabel} Ref: ${params.quotationId}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
            ),
            Text(
              'Date: ${_formatDate(params.date)}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 2, color: const Color(0xFF7C3AED)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLogoWidget(String? logoImage, {double height = 50, double? width, BoxFit fit = BoxFit.contain}) {
    if (logoImage == null || logoImage.isEmpty) return const SizedBox.shrink();
    if (logoImage.startsWith('data:image') || !logoImage.startsWith('http')) {
      try {
        final base64Str = logoImage.contains(',') ? logoImage.split(',')[1] : logoImage;
        return Image.memory(
          base64Decode(base64Str),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => SizedBox(height: height, width: width),
        );
      } catch (e) {
        return SizedBox(height: height, width: width);
      }
    } else {
      return Image.network(
        logoImage,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => SizedBox(height: height, width: width),
      );
    }
  }

  Widget _buildClientAndPaymentInfo() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // BILLED TO CARD
          Expanded(
            flex: 50,
            child: _buildInfoCard(
              title: params.documentTitle == 'QUOTATION' ? 'QUOTE TO' : 'BILLED TO',
              icon: Icons.person_outline,
              borderColor: const Color(0xFFEDE9FE), // violet-100
              stripeColor: const Color(0xFF8B5CF6), // violet-500
              textColor: const Color(0xFF7C3AED), // violet-600
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    params.clientName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(params.clientEmail, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  if (params.clientPhone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(params.clientPhone, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 2),
                  Text(params.clientAddress, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, height: 1.4)),
                  if (params.gstEnabled && params.clientGst.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text('GSTIN: ${params.clientGst}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // PAYMENT DETAILS CARD
          Expanded(
            flex: 50,
            child: _buildInfoCard(
              title: 'PAYMENT DETAILS',
              icon: Icons.credit_card,
              borderColor: const Color(0xFFFAE8FF), // fuchsia-100
              stripeColor: const Color(0xFFD946EF), // fuchsia-500
              textColor: const Color(0xFFC026D3), // fuchsia-600
              child: (params.bankDetails.isNotEmpty && params.bankDetails['accountNumber'] != null)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((params.bankDetails['accountName'] ?? '').isNotEmpty)
                          _buildPaymentRow('Name', params.bankDetails['accountName']),
                        _buildPaymentRow('Bank', params.bankDetails['bankName']),
                        _buildPaymentRow('Account', params.bankDetails['accountNumber'], isMono: true),
                        _buildPaymentRow('IFSC', params.bankDetails['ifscCode'], isMono: true, isLast: true),
                      ],
                    )
                  : Text('No payment details added.', style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.grey.shade400)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color borderColor,
    required Color stripeColor,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, decoration: BoxDecoration(color: stripeColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 10, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String? value, {bool isMono = false, bool isLast = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label:', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
              Text(value, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade900, fontFamily: isMono ? 'Courier' : null)),
            ],
          ),
        ),
        if (!isLast)
          const _DashedLine(color: Colors.black12),
      ],
    );
  }

  Widget _buildItemsTable(List<Map<String, dynamic>> items) {
    final bool showHsn = items.any((item) => (item['hsnCode']?.toString() ?? '').trim().isNotEmpty);

    Map<int, TableColumnWidth> colWidths = showHsn
        ? const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(4.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(2),
            5: FlexColumnWidth(2.5),
          }
        : const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(6.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2.5),
          };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: colWidths,
          children: [
            // HEADER
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF3F4F6)), // gray-100
              children: [
                _buildTableHeaderCell('#', TextAlign.left, leftPadding: 16),
                _buildTableHeaderCell('DESCRIPTION', TextAlign.left),
                if (showHsn) _buildTableHeaderCell('HSN/SAC', TextAlign.center),
                _buildTableHeaderCell('QTY', TextAlign.center),
                _buildTableHeaderCell('RATE', TextAlign.right),
                _buildTableHeaderCell('AMOUNT', TextAlign.right, rightPadding: 16),
              ],
            ),
            // ITEMS
            ...items.asMap().entries.map((entry) {
              final int index = entry.key;
              final Map<String, dynamic> item = entry.value;
              final double qty = ((item['quantity'] ?? 1) as num).toDouble();
              final double rate = ((item['rate'] ?? 0.0) as num).toDouble();
              final double amount = qty * rate;
              final isOdd = index % 2 != 0;

              return TableRow(
                decoration: BoxDecoration(
                  color: isOdd ? Colors.grey.shade50.withOpacity(0.5) : Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                children: [
                  _buildTableCell('${index + 1}', TextAlign.left, color: Colors.grey.shade500, leftPadding: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['description']?.toString() ?? '',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                        ),
                        if ((item['additionalDetails']?.toString() ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item['additionalDetails'].toString(),
                            style: TextStyle(fontSize: 8, color: Colors.grey.shade500, height: 1.3),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showHsn) _buildTableCell(item['hsnCode']?.toString() ?? '-', TextAlign.center, color: Colors.grey.shade500),
                  _buildTableCell(qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2), TextAlign.center, color: Colors.grey.shade600),
                  _buildTableCell(params.formatCurrency.format(rate), TextAlign.right, color: Colors.grey.shade600),
                  _buildTableCell(params.formatCurrency.format(amount), TextAlign.right, isBold: true, color: Colors.grey.shade900, rightPadding: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, TextAlign align, {double leftPadding = 8, double rightPadding = 8}) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12, left: leftPadding, right: rightPadding),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildTableCell(String text, TextAlign align, {bool isBold = false, Color? color, double leftPadding = 8, double rightPadding = 8}) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 16, left: leftPadding, right: rightPadding),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(fontSize: 9, fontWeight: isBold ? FontWeight.w900 : FontWeight.w500, color: color ?? Colors.black87),
      ),
    );
  }

  Widget _buildTotalsSection() {
    final double balanceDue = params.total - params.advancePayment;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AMOUNT IN WORDS
        Expanded(
          flex: 55,
          child: CustomPaint(
            painter: _DashedRectPainter(color: const Color(0xFFF5D0FE)), // fuchsia-200
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF4FF), // fuchsia-50
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL AMOUNT (IN WORDS)',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFE879F9), letterSpacing: 1.5), // fuchsia-400
                  ),
                  const SizedBox(height: 6),
                  Text(
                    convertNumberToWords(params.total),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF701A75), height: 1.3), // fuchsia-900
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // TOTALS BOX
        Expanded(
          flex: 40,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', params.subtotal, isBold: true, color: Colors.grey.shade900),
                    if (params.discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      _buildTotalRow('Discount', params.discountAmount, isBold: true, isMinus: true, color: const Color(0xFFC026D3)), // fuchsia-600
                    ],
                    if (params.gstEnabled || params.discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                        child: _buildTotalRow('Taxable Amount', params.subtotal - params.discountAmount, color: Colors.grey.shade600),
                      ),
                    ],
                    if (params.gstEnabled && params.taxAmount > 0) ...[
                      const SizedBox(height: 8),
                      ..._buildGstRows(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
                        Text(params.formatCurrency.format(params.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                    if (params.advancePayment > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2)))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Advance', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.9))),
                            Text('- ${params.formatCurrency.format(params.advancePayment)}', style: const TextStyle(fontSize: 9, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('BALANCE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                          Text(params.formatCurrency.format(balanceDue), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGstRows() {
    String place = params.placeOfSupply.toLowerCase();
    String tenantState = (params.tenant['state'] ?? '').toString().toLowerCase();
    bool isOutstate = false;
    if (place.isNotEmpty && tenantState.isNotEmpty) {
      isOutstate = !place.contains(tenantState) && !tenantState.contains(place);
    } else if (place.isNotEmpty) {
      isOutstate = !place.contains("telangana") && !place.contains("36");
    }

    if (isOutstate) {
      return [
        _buildTotalRow('IGST', params.taxAmount, color: Colors.grey.shade500),
      ];
    } else {
      return [
        _buildTotalRow('CGST', params.taxAmount / 2, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        _buildTotalRow('SGST', params.taxAmount / 2, color: Colors.grey.shade500),
      ];
    }
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, bool isMinus = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: color ?? Colors.black87)),
        Text(
          '${isMinus ? "- " : ""}${params.formatCurrency.format(amount)}',
          style: TextStyle(fontSize: 9, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSignatorySection() {
    return GetBuilder<AuthController>(builder: (authController) {
      final String authSignature = authController.userSignature.value;
      final String displayName = authController.userName.value.isNotEmpty ? authController.userName.value : (params.tenant['name'] ?? '');

      return Row(
        children: [
          const Expanded(flex: 55, child: SizedBox.shrink()),
          const SizedBox(width: 24),
          Expanded(
            flex: 40,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (authSignature.isNotEmpty)
                      _buildLogoWidget(authSignature, height: 40, width: 120, fit: BoxFit.contain)
                    else if ((params.tenant['signatureImage']?.toString() ?? '').isNotEmpty)
                      _buildLogoWidget(params.tenant['signatureImage'], height: 40, width: 120, fit: BoxFit.contain)
                    else
                      Container(
                        height: 40,
                        width: 120,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey, style: BorderStyle.solid)),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('Sign Here', style: TextStyle(fontSize: 7, color: Colors.grey.shade400)),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AUTHORIZED SIGNATORY',
                            style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTermsSection() {
    final terms = params.tenant['defaultTerms'] ?? 'Payment is due within 15 days.';
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 10, color: Color(0xFF7C3AED)), // violet-600
              const SizedBox(width: 4),
              const Text(
                'TERMS & CONDITIONS',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED), // violet-600
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              terms,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          if (params.placeOfSupply.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Place of Supply: ${params.placeOfSupply}  |  Dispatch State: ${params.tenant['state'] ?? 'Not set'}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
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

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);

    canvas.drawPath(_dashPath(path, dashArray: 3, dashSpace: 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color),
      ),
    );
  }
}

Path _dashPath(Path source, {required double dashArray, required double dashSpace}) {
  final Path dest = Path();
  for (final PathMetric metric in source.computeMetrics()) {
    double distance = 0.0;
    bool draw = true;
    while (distance < metric.length) {
      final double len = draw ? dashArray : dashSpace;
      if (draw) {
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
      }
      distance += len;
      draw = !draw;
    }
  }
  return dest;
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final Path path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));
    canvas.drawPath(_dashPath(path, dashArray: 4, dashSpace: 4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

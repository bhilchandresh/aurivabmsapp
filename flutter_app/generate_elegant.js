const fs = require('fs');

const generate = (isQuotation) => {
  const paramsClass = isQuotation ? 'QuotationTemplateParams' : 'InvoiceTemplateParams';
  const idField = isQuotation ? 'quotationId' : 'invoiceId';
  const importFile = isQuotation ? 'quotation_template_params.dart' : 'invoice_template_params.dart';

  return `import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/auth_controller.dart';
import '${importFile}';
import 'template_helper.dart';

class ElegantTemplate extends StatelessWidget {
  final ${paramsClass} params;
  final List<Map<String, dynamic>>? pageItems;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageIndex;
  final int totalPages;
  final bool isOffline;

  const ElegantTemplate({
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
        return "\${parsed.month}/\${parsed.day}/\${parsed.year}"; // matching web format
      }
    } catch (_) {}
    return dateStr.replaceAll('-', '/');
  }

  @override
  Widget build(BuildContext context) {
    final paddingValue = isOffline ? 40.0 : 38.0;
    final itemsList = pageItems ?? params.items;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(paddingValue),
      child: DefaultTextStyle(
        style: const TextStyle(fontFamily: 'Times New Roman', color: Colors.black87),
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
            
            _buildItemsTable(itemsList),
            
            if (isLastPage) ...[
              const SizedBox(height: 24),
              _buildTotalsSection(),
              const SizedBox(height: 16),
              _buildSignatorySection(),
            ],
            
            const Spacer(),
            if (isLastPage) _buildTermsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tenant = params.tenant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Center Company Info
        if ((tenant['logoImage'] ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildLogoWidget(tenant['logoImage'], height: 56, fit: BoxFit.contain),
          ),
        Text(
          (tenant['name'] ?? '').toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontFamily: 'Times New Roman',
          ),
          textAlign: TextAlign.center,
        ),
        if ((tenant['address'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            tenant['address'] ?? '',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
              fontFamily: 'Times New Roman',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if ((tenant['email'] ?? '').isNotEmpty)
              Text((tenant['email'] ?? '').toUpperCase(), style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'Times New Roman', letterSpacing: 0.5, fontWeight: FontWeight.w500)),
            if ((tenant['email'] ?? '').isNotEmpty && (tenant['phone'] ?? '').isNotEmpty)
              Text(' • ', style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
            if ((tenant['phone'] ?? '').isNotEmpty)
              Text((tenant['phone'] ?? '').toUpperCase(), style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'Times New Roman', letterSpacing: 0.5, fontWeight: FontWeight.w500)),
          ],
        ),
        if (params.gstEnabled && (tenant['gstNumber'] ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'GSTIN: \${tenant['gstNumber']}',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman'),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        Container(height: 2, color: Colors.grey.shade800),
        const SizedBox(height: 16),
        
        // Invoice Meta
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              params.documentTitle.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.grey.shade300,
                letterSpacing: -0.5,
                fontFamily: 'Times New Roman',
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '#\${params.${idField}}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Times New Roman',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Date: ', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'Times New Roman')),
                    Text(_formatDate(params.date), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('\${params.documentTitle == "QUOTATION" ? "Valid Until" : "Due Date"}: ', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'Times New Roman')),
                    Text(_formatDate(params.dueDate), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
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
              '\${params.numberLabel} Ref: \${params.${idField}}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman'),
            ),
            Text(
              'Date: \${_formatDate(params.date)}',
              style: const TextStyle(fontSize: 10, fontFamily: 'Times New Roman'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 2, color: Colors.grey.shade800),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TO
        Expanded(
          flex: 55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  params.documentTitle == 'QUOTATION' ? 'QUOTE TO' : 'TO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 2.0,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                params.clientName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Times New Roman',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                params.clientAddress,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                  height: 1.4,
                  fontFamily: 'Times New Roman',
                ),
              ),
              if (params.clientEmail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  params.clientEmail,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ],
              if (params.clientPhone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  params.clientPhone,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ],
              if (params.gstEnabled && params.clientGst.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  child: Text(
                    'GSTIN: \${params.clientGst}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        // PAY TO
        Expanded(
          flex: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'PAY TO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 2.0,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (params.bankDetails.isNotEmpty && params.bankDetails['accountNumber'] != null) ...[
                if ((params.bankDetails['accountName'] ?? '').isNotEmpty)
                  _buildPaymentRow('Name', params.bankDetails['accountName']),
                _buildPaymentRow('Bank', params.bankDetails['bankName']),
                _buildPaymentRow('A/C', params.bankDetails['accountNumber'], isMono: true),
                _buildPaymentRow('IFSC', params.bankDetails['ifscCode'], isMono: true),
              ] else ...[
                Text(
                  'Payment details not provided.',
                  style: TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade400,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String? value, {bool isMono = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade400,
              fontFamily: 'Times New Roman',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: isMono ? 'Courier' : 'Times New Roman',
            ),
          ),
        ],
      ),
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
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 2),
          bottom: BorderSide(color: Colors.grey.shade800, width: 2),
        ),
      ),
      child: Table(
        columnWidths: colWidths,
        children: [
          // HEADER
          TableRow(
            children: [
              _buildTableHeaderCell('NO.', TextAlign.left),
              _buildTableHeaderCell('DESCRIPTION', TextAlign.left),
              if (showHsn) _buildTableHeaderCell('HSN/SAC', TextAlign.center),
              _buildTableHeaderCell('QTY', TextAlign.center),
              _buildTableHeaderCell('PRICE', TextAlign.right),
              _buildTableHeaderCell('AMOUNT', TextAlign.right),
            ],
          ),
          // ITEMS
          ...items.asMap().entries.map((entry) {
            final int index = entry.key;
            final Map<String, dynamic> item = entry.value;
            final double qty = ((item['quantity'] ?? 1) as num).toDouble();
            final double rate = ((item['rate'] ?? 0.0) as num).toDouble();
            final double amount = qty * rate;

            return TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
              ),
              children: [
                _buildTableCell('0\${index + 1}', TextAlign.left, color: Colors.grey.shade400),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['description']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontFamily: 'Times New Roman',
                        ),
                      ),
                      if ((item['additionalDetails']?.toString() ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item['additionalDetails'].toString(),
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                            fontFamily: 'Times New Roman',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showHsn) _buildTableCell(item['hsnCode']?.toString() ?? '-', TextAlign.center, color: Colors.grey.shade600),
                _buildTableCell(qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2), TextAlign.center, color: Colors.grey.shade600),
                _buildTableCell(params.formatCurrency.format(rate), TextAlign.right, color: Colors.grey.shade600),
                _buildTableCell(params.formatCurrency.format(amount), TextAlign.right, isBold: true, color: Colors.grey.shade900),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, TextAlign align) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1))),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 8,
          color: Colors.grey.shade500,
          letterSpacing: 1.5,
          fontFamily: 'Times New Roman',
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, TextAlign align, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black87,
          fontFamily: 'Times New Roman',
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'AMOUNT IN WORDS',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 1.5,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                convertNumberToWords(params.total),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade800,
                  height: 1.3,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // TOTALS BOX
        Expanded(
          flex: 40,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', params.subtotal, isBold: false),
                    if (params.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      _buildTotalRow(
                        'Discount (\${params.discountPercentage}%)',
                        params.discountAmount,
                        isBold: false,
                        isMinus: true,
                        color: Colors.red.shade500,
                      ),
                    ],
                    if (params.gstEnabled || params.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.shade200, style: BorderStyle.solid)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TAXABLE VALUE',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.0,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                            Text(
                              params.formatCurrency.format(params.subtotal - params.discountAmount),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade400,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (params.gstEnabled && params.taxAmount > 0) ...[
                      const SizedBox(height: 6),
                      ..._buildGstRows(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildTotalRow('TOTAL', params.total, isBold: true, fontSize: 13, isUppercase: true),
              if (params.advancePayment > 0) ...[
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Less: Advance',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green.shade600,
                          fontFamily: 'Times New Roman',
                        ),
                      ),
                      Text(
                        '- \${params.formatCurrency.format(params.advancePayment)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Times New Roman',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                color: Colors.grey.shade900,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Balance Due',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    Text(
                      params.formatCurrency.format(balanceDue),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
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
        _buildTotalRow('IGST', params.taxAmount, isBold: false, color: Colors.grey.shade600),
      ];
    } else {
      return [
        _buildTotalRow('CGST', params.taxAmount / 2, isBold: false, color: Colors.grey.shade600),
        const SizedBox(height: 6),
        _buildTotalRow('SGST', params.taxAmount / 2, isBold: false, color: Colors.grey.shade600),
      ];
    }
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, bool isMinus = false, double fontSize = 9, Color? color, bool isUppercase = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isUppercase ? label.toUpperCase() : label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
            letterSpacing: isUppercase ? 2.0 : 0.0,
            fontFamily: 'Times New Roman',
          ),
        ),
        Text(
          '\${isMinus ? "- " : ""}\${params.formatCurrency.format(amount)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
            fontFamily: 'Times New Roman',
          ),
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
              alignment: Alignment.center,
              child: SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (authSignature.isNotEmpty)
                      _buildLogoWidget(authSignature, height: 40, width: 140, fit: BoxFit.contain)
                    else if ((params.tenant['signatureImage']?.toString() ?? '').isNotEmpty)
                      _buildLogoWidget(params.tenant['signatureImage'], height: 40, width: 140, fit: BoxFit.contain)
                    else
                      Container(
                        height: 40,
                        width: 140,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('Sign Here', style: TextStyle(fontSize: 7, color: Colors.grey.shade400, fontStyle: FontStyle.italic, fontFamily: 'Times New Roman')),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      displayName.toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AUTHORIZED SIGNATORY',
                      style: TextStyle(fontSize: 7, color: Colors.grey.shade500, fontFamily: 'Times New Roman', letterSpacing: 1.0),
                      textAlign: TextAlign.center,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          height: 4, // creates a double line effect if we pad it, but a single thick line is okay
        ),
        Text(
          'TERMS & CONDITIONS',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 2.0,
            fontFamily: 'Times New Roman',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          terms,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade700,
            height: 1.6,
            fontFamily: 'Times New Roman',
          ),
        ),
        if (params.placeOfSupply.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Place of Supply: \${params.placeOfSupply}  |  Dispatch State: \${params.tenant['state'] ?? 'Not set'}',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              fontFamily: 'Times New Roman',
            ),
          ),
        ],
      ],
    );
  }
}
`;
};

fs.writeFileSync('lib/features/invoices/templates/elegant_template.dart', generate(false));
fs.writeFileSync('lib/features/quotations/templates/elegant_template.dart', generate(true));

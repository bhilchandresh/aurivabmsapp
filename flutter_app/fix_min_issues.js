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

class MinimalistTemplate extends StatelessWidget {
  final ${paramsClass} params;
  final List<Map<String, dynamic>>? pageItems;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageIndex;
  final int totalPages;
  final bool isOffline;

  const MinimalistTemplate({
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
        return "\${parsed.day}/\${parsed.month}/\${parsed.year}";
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
    );
  }

  Widget _buildHeader() {
    final tenant = params.tenant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Logo and Tenant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((tenant['logoImage'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildLogoWidget(tenant['logoImage'], height: 48, fit: BoxFit.contain),
                    ),
                  Text(
                    (tenant['name'] ?? '').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  if ((tenant['address'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      tenant['address'] ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if ((tenant['email'] ?? '').isNotEmpty || (tenant['phone'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if ((tenant['email'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Row(
                              children: [
                                const Icon(Icons.email, size: 8, color: Colors.black87),
                                const SizedBox(width: 4),
                                Text(tenant['email'] ?? '', style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        if ((tenant['phone'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, size: 8, color: Colors.black87),
                                const SizedBox(width: 4),
                                Text(tenant['phone'] ?? '', style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (params.gstEnabled && (tenant['gstNumber'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'GSTIN: \${tenant['gstNumber']}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            // Right: Invoice Meta
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  params.documentTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey.shade200,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '#\${params.${idField}}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('ISSUED:  ', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    Text(_formatDate(params.date), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('\${params.documentTitle == "QUOTATION" ? "VALID UNTIL" : "DUE DATE"}:  ', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    Text(_formatDate(params.dueDate), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(thickness: 1.5, color: Colors.black),
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Text(
              'Date: \${_formatDate(params.date)}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 1.5, color: Colors.black),
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
        // BILLED TO
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                params.documentTitle == 'QUOTATION' ? 'QUOTE TO' : 'BILLED TO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                params.clientName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                params.clientAddress,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              if (params.clientEmail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  params.clientEmail,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (params.gstEnabled && params.clientGst.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'GSTIN: \${params.clientGst}',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        // PAYMENT INFO
        Expanded(
          child: Column(
            // Changed from CrossAxisAlignment.end to start
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAYMENT INFO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              if (params.bankDetails.isNotEmpty && params.bankDetails['accountNumber'] != null) ...[
                if ((params.bankDetails['accountName'] ?? '').isNotEmpty)
                  _buildPaymentRow('NAME', params.bankDetails['accountName']),
                _buildPaymentRow('BANK', params.bankDetails['bankName']),
                _buildPaymentRow('A/C', params.bankDetails['accountNumber']),
                _buildPaymentRow('IFSC', params.bankDetails['ifscCode']),
              ] else ...[
                Text(
                  'No details available',
                  style: TextStyle(
                    fontSize: 8,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade400,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
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
            0: FlexColumnWidth(4),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2.5),
          }
        : const {
            0: FlexColumnWidth(5.5),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2.5),
          };

    return Table(
      columnWidths: colWidths,
      children: [
        // HEADER
        TableRow(
          decoration: const BoxDecoration(color: Colors.black),
          children: [
            _buildTableHeaderCell('ITEM DESCRIPTION', TextAlign.left),
            if (showHsn) _buildTableHeaderCell('HSN/SAC', TextAlign.center),
            _buildTableHeaderCell('QTY', TextAlign.center),
            _buildTableHeaderCell('RATE', TextAlign.right),
            _buildTableHeaderCell('AMOUNT', TextAlign.right),
          ],
        ),
        // ITEMS
        ...items.map((item) {
          final double qty = ((item['quantity'] ?? 1) as num).toDouble();
          final double rate = ((item['rate'] ?? 0.0) as num).toDouble();
          final double amount = qty * rate;

          return TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['description']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((item['additionalDetails']?.toString() ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item['additionalDetails'].toString(),
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade500,
                            height: 1.3,
                          ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showHsn) _buildTableCell(item['hsnCode']?.toString() ?? '-', TextAlign.center, color: Colors.grey.shade600),
              _buildTableCell(qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2), TextAlign.center),
              _buildTableCell(params.formatCurrency.format(rate), TextAlign.right),
              _buildTableCell(params.formatCurrency.format(amount), TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, TextAlign align, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black87,
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
              Text(
                'TOTAL AMOUNT (IN WORDS)',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                convertNumberToWords(params.total),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
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
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
                ),
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', params.subtotal, isBold: false),
                    if (params.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      _buildTotalRow(
                        'Discount',
                        params.discountAmount,
                        isBold: false,
                        isMinus: true,
                        color: Colors.grey.shade500,
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
              _buildTotalRow('Total', params.total, isBold: true, fontSize: 13),
              if (params.advancePayment > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Advance Paid',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '- \${params.formatCurrency.format(params.advancePayment)}',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Balance Due',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      params.formatCurrency.format(balanceDue),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
        _buildTotalRow('IGST', params.taxAmount, isBold: false, color: Colors.grey.shade500),
      ];
    } else {
      return [
        _buildTotalRow('CGST', params.taxAmount / 2, isBold: false, color: Colors.grey.shade500),
        const SizedBox(height: 6),
        _buildTotalRow('SGST', params.taxAmount / 2, isBold: false, color: Colors.grey.shade500),
      ];
    }
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, bool isMinus = false, double fontSize = 9, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          '\${isMinus ? "- " : ""}\${params.formatCurrency.format(amount)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatorySection() {
    return GetBuilder<AuthController>(builder: (authController) {
      final String? authSignature = authController.userProfile.value?.signatureImage;
      final String displayName = authController.userProfile.value?.name ?? params.tenant['name'] ?? '';

      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 140,
          child: Column(
            children: [
              if (authSignature != null && authSignature.isNotEmpty)
                _buildLogoWidget(authSignature, height: 40, width: 140, fit: BoxFit.contain)
              else
                Container(
                  height: 40,
                  width: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  alignment: Alignment.center,
                  child: Text('Sign Here', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
                ),
              const SizedBox(height: 4),
              Text(
                displayName.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'AUTHORIZED SIGNATORY',
                style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTermsSection() {
    final terms = params.tenant['defaultTerms'] ?? 'Payment is due upon receipt.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Divider(color: Colors.black12, thickness: 1),
        const SizedBox(height: 12),
        const Text(
          'TERMS & CONDITIONS',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          terms,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (params.placeOfSupply.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Place of Supply: \${params.placeOfSupply}  |  Dispatch State: \${params.tenant['state'] ?? 'Not set'}',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
`;
};

fs.writeFileSync('lib/features/invoices/templates/minimalist_template.dart', generate(false));
fs.writeFileSync('lib/features/quotations/templates/minimalist_template.dart', generate(true));

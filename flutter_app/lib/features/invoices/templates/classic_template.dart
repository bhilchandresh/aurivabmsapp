import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/auth_controller.dart';
import '../../team/team_controller.dart';
import 'invoice_template_params.dart';
import 'template_helper.dart';

class ClassicTemplate extends StatelessWidget {
  final InvoiceTemplateParams params;
  final List<Map<String, dynamic>>? pageItems;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageIndex;
  final int totalPages;
  final bool isOffline;

  const ClassicTemplate({
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
    return formatCleanDate(dateStr).replaceAll('-', '/');
  }

  @override
  Widget build(BuildContext context) {
    final paddingValue = isOffline ? 40.0 : 32.0;
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
            const SizedBox(height: 32),
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
                      child: ClipOval(
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                          child: _buildLogoWidget(
                            tenant['logoImage'],
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                  Text(
                    (tenant['name'] ?? '').toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if ((tenant['address'] ?? '').isNotEmpty)
                    Text(
                      tenant['address']!,
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _buildContactString(),
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                  if (params.gstEnabled &&
                      (tenant['gstNumber'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'GSTIN: ${tenant['gstNumber']}',
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right: Invoice Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  params.documentTitle.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey.shade300,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  params.invoiceId,
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDateRow('Date', params.date),
                _buildDateRow(
                  params.documentTitle == 'QUOTATION'
                      ? 'Valid Until'
                      : 'Due Date',
                  params.dueDate,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(thickness: 1, color: Colors.black),
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
              '${params.numberLabel} Ref: ${params.invoiceId}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Times New Roman',
              ),
            ),
            Text(
              'Date: ${_formatDate(params.date)}',
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'Times New Roman',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 1, color: Colors.black),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLogoWidget(
    String? logoImage, {
    double height = 50,
    double? width,
    BoxFit fit = BoxFit.contain,
  }) {
    if (logoImage == null || logoImage.isEmpty) return const SizedBox.shrink();
    if (logoImage.startsWith('data:image') || !logoImage.startsWith('http')) {
      try {
        final base64Str = logoImage.contains(',')
            ? logoImage.split(',')[1]
            : logoImage;
        return Image.memory(
          base64Decode(base64Str),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              SizedBox(height: height, width: width),
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
        errorBuilder: (context, error, stackTrace) =>
            SizedBox(height: height, width: width),
      );
    }
  }

  String _buildContactString() {
    final t = params.tenant;
    final List<String> parts = [];
    if ((t['email'] ?? '').isNotEmpty) parts.add(t['email']!);
    if ((t['phone'] ?? '').isNotEmpty) parts.add(t['phone']!);
    if ((t['website'] ?? '').isNotEmpty) {
      parts.add(t['website']!.replaceAll(RegExp(r'^https?://'), ''));
    }
    return parts.join(' | ');
  }

  Widget _buildDateRow(String label, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientAndPaymentInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BILL TO
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  params.documentTitle == 'QUOTATION' ? 'QUOTE TO' : 'BILL TO',
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                params.clientName,
                style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                params.clientAddress,
                style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              if (params.gstEnabled && params.clientGst.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'GSTIN: ${params.clientGst}',
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 32),
        // PAYMENT DETAILS
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 2),
                child: const Text(
                  'PAYMENT DETAILS',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if ((params.bankDetails['accountNumber'] ?? '').isNotEmpty) ...[
                if ((params.bankDetails['accountName'] ?? '').isNotEmpty)
                  _buildBankRow('Name: ', params.bankDetails['accountName']!),
                _buildBankRow('Bank: ', params.bankDetails['bankName'] ?? ''),
                _buildBankRow(
                  'Account: ',
                  params.bankDetails['accountNumber']!,
                ),
                _buildBankRow('IFSC: ', params.bankDetails['ifscCode'] ?? ''),
              ] else
                const Text(
                  'No bank details available.',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<Map<String, dynamic>> items) {
    final bool showHsn = items.any(
      (item) => (item['hsnCode']?.toString() ?? '').trim().isNotEmpty,
    );

    final Map<int, TableColumnWidth> colWidths = showHsn
        ? const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(4),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(2),
            5: FlexColumnWidth(2.5),
          }
        : const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2.5),
          };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Table(
        columnWidths: colWidths,
        border: const TableBorder(
          verticalInside: BorderSide(color: Colors.black, width: 1),
        ),
        children: [
          // HEADER
          TableRow(
            children: [
              _buildTableHeaderCell('#', TextAlign.center),
              _buildTableHeaderCell('DESCRIPTION', TextAlign.left),
              if (showHsn) _buildTableHeaderCell('HSN/SAC', TextAlign.center),
              _buildTableHeaderCell('QTY', TextAlign.center),
              _buildTableHeaderCell('RATE', TextAlign.right),
              _buildTableHeaderCell('AMOUNT', TextAlign.right),
            ],
          ),
          // ITEMS
          ...items.asMap().entries.map((entry) {
            final int index = entry.key;
            final item = entry.value;
            final double qty = ((item['quantity'] ?? 1) as num).toDouble();
            final double rate = ((item['rate'] ?? 0.0) as num).toDouble();
            final double amount = qty * rate;

            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              children: [
                _buildTableCell(
                  (index + 1).toString(),
                  TextAlign.center,
                  isBold: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['description']?.toString() ?? '',
                        style: const TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if ((item['additionalDetails']?.toString() ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item['additionalDetails'].toString(),
                          style: TextStyle(
                            fontFamily: 'Times New Roman',
                            fontSize: 10,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showHsn)
                  _buildTableCell(
                    item['hsnCode']?.toString() ?? '-',
                    TextAlign.center,
                    isBold: false,
                  ),
                _buildTableCell(
                  qty % 1 == 0
                      ? qty.toStringAsFixed(0)
                      : qty.toStringAsFixed(2),
                  TextAlign.center,
                  isBold: false,
                ),
                _buildTableCell(
                  params.formatCurrency.format(rate),
                  TextAlign.right,
                  isBold: false,
                ),
                _buildTableCell(
                  params.formatCurrency.format(amount),
                  TextAlign.right,
                  isBold: true,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, TextAlign align) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        border: Border(bottom: BorderSide(color: Colors.black, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontFamily: 'Times New Roman',
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, TextAlign align, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontFamily: 'Times New Roman',
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 2),
                  child: const Text(
                    'TOTAL AMOUNT (IN WORDS)',
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  convertNumberToWords(params.total),
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', params.subtotal, isBold: false),
                    if (params.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      _buildTotalRow(
                        'Discount (${params.discountPercentage.toStringAsFixed(0)}%)',
                        params.discountAmount,
                        isBold: false,
                        isMinus: true,
                        color: Colors.black54,
                      ),
                    ],
                    if (params.gstEnabled && params.taxAmount > 0) ...[
                      const SizedBox(height: 6),
                      ..._buildGstRows(),
                    ],
                    const SizedBox(height: 8),
                    const Divider(thickness: 1.5, color: Colors.black),
                    const SizedBox(height: 8),
                    _buildTotalRow(
                      'Total',
                      params.total,
                      isBold: true,
                      fontSize: 13,
                    ),
                    if (params.advancePayment > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Advance Paid',
                            style: TextStyle(
                              fontFamily: 'Times New Roman',
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '- ${params.formatCurrency.format(params.advancePayment)}',
                            style: const TextStyle(
                              fontFamily: 'Times New Roman',
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Balance Due',
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      params.formatCurrency.format(balanceDue),
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
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
    final String place = params.placeOfSupply.toLowerCase();
    final String tenantState = (params.tenant['state'] ?? '')
        .toString()
        .toLowerCase();
    bool isOutstate = false;
    if (place.isNotEmpty && tenantState.isNotEmpty) {
      isOutstate = !place.contains(tenantState) && !tenantState.contains(place);
    } else if (place.isNotEmpty) {
      isOutstate = !place.contains("telangana") && !place.contains("36");
    }

    if (isOutstate) {
      return [
        _buildTotalRow(
          'IGST',
          params.taxAmount,
          isBold: false,
          color: Colors.black54,
        ),
      ];
    } else {
      return [
        _buildTotalRow(
          'CGST',
          params.taxAmount / 2,
          isBold: false,
          color: Colors.black54,
        ),
        const SizedBox(height: 6),
        _buildTotalRow(
          'SGST',
          params.taxAmount / 2,
          isBold: false,
          color: Colors.black54,
        ),
      ];
    }
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isMinus = false,
    Color color = Colors.black,
    double fontSize = 11,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          '${isMinus ? '- ' : ''}${params.formatCurrency.format(amount)}',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatorySection() {
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

      final String displayName;
      if (userSignature != null &&
          userSignature.isNotEmpty &&
          currentUserMember != null) {
        displayName = currentUserMember.name;
      } else {
        displayName =
            params.tenant['authorizedSignatoryName'] ??
            params.tenant['name'] ??
            '';
      }

      final signatureWidget = _buildLogoWidget(
        (userSignature != null && userSignature.isNotEmpty)
            ? userSignature
            : params.tenant['signatureImage'],
        height: 40,
      );

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (signatureWidget is! SizedBox) ...[
                signatureWidget,
                const SizedBox(height: 8),
              ] else ...[
                Container(
                  height: 50,
                  width: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Text(
                    'Sign Here',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                displayName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'AUTHORIZED SIGNATORY',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildTermsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
            ),
            padding: const EdgeInsets.only(bottom: 2),
            child: const Text(
              'TERMS & CONDITIONS',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            params.tenant['defaultTerms'] ?? 'Payment is due upon receipt.',
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 9,
              height: 1.4,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (params.placeOfSupply.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Place of Supply: ${params.placeOfSupply}  |  Dispatch State: ${params.tenant['state'] ?? 'Not set'}',
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

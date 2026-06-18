import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/auth_controller.dart';
import '../../team/team_controller.dart';
import 'quotation_template_params.dart';
import 'template_helper.dart';

class StandardTemplate extends StatelessWidget {
  final QuotationTemplateParams params;
  final List<Map<String, dynamic>>? pageItems;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageIndex;
  final int totalPages;
  final bool isOffline;

  const StandardTemplate({
    super.key,
    required this.params,
    this.pageItems,
    this.isFirstPage = true,
    this.isLastPage = true,
    this.pageIndex = 0,
    this.totalPages = 1,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final paddingValue = isOffline ? 40.0 : 24.0;
    final itemsList = pageItems ?? params.items;
    final bankName = params.bankDetails['bankName']?.toString() ?? '';
    final accountName = params.bankDetails['accountName']?.toString() ?? '';
    final accountNumber = params.bankDetails['accountNumber']?.toString() ?? '';
    final ifscCode = params.bankDetails['ifscCode']?.toString() ?? '';
    final hasBankDetails = bankName.isNotEmpty || accountName.isNotEmpty || accountNumber.isNotEmpty || ifscCode.isNotEmpty;
    final logoWidget = _buildLogoWidget(params.tenant['logoImage'], height: 56);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstPage) ...[
            // Elegant Centered Company Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (logoWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: logoWidget,
                  ),
                Center(
                  child: Text(
                    (params.tenant['name'] ?? '').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    (params.tenant['address'] ?? '').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    '${(params.tenant['email'] ?? '').toUpperCase()}  •  ${(params.tenant['phone'] ?? '').toUpperCase()}'
                    '${params.tenant['website'] != null && params.tenant['website']!.isNotEmpty ? '  •  ${params.tenant['website']!.toUpperCase()}' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (params.gstEnabled && params.tenant['gstNumber'] != null && params.tenant['gstNumber']!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      'GSTIN: ${(params.tenant['gstNumber'] ?? '').toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  height: 1.5,
                  color: Colors.black87,
                ),
                const SizedBox(height: 16),
              ],
            ),

            // Document Title & Meta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  params.documentTitle.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 26,
                    fontWeight: FontWeight.w100, // thin
                    color: Colors.black26, // text-gray-300 equivalent
                    letterSpacing: 0.5,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#${params.quotationId}',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Date:',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatCleanDate(params.date),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Valid Until:',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatCleanDate(params.dueDate),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Client & Bank Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Billed To
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black12, width: 1),
                          ),
                        ),
                        padding: const EdgeInsets.only(bottom: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        child: const Text(
                          'TO',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Text(
                        params.clientName,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (params.clientAddress.isNotEmpty) ...[
                        Text(
                          params.clientAddress,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (params.clientEmail.isNotEmpty) ...[
                        Text(
                          params.clientEmail,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (params.clientPhone.isNotEmpty) ...[
                        Text(
                          params.clientPhone,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      if (params.gstEnabled && params.clientGst.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            color: Colors.black.withOpacity(0.02),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'GSTIN: ${params.clientGst}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                // Bank Details
                Expanded(
                  child: hasBankDetails
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.black12, width: 1),
                                ),
                              ),
                              padding: const EdgeInsets.only(bottom: 2),
                              margin: const EdgeInsets.only(bottom: 6),
                              child: const Text(
                                'PAY TO',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            RichText(
                              textAlign: TextAlign.right,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.5),
                                children: [
                                  if (accountName.isNotEmpty) ...[
                                    const TextSpan(text: 'Name: '),
                                    TextSpan(
                                      text: '$accountName\n',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ],
                                  if (bankName.isNotEmpty) ...[
                                    const TextSpan(text: 'Bank: '),
                                    TextSpan(
                                      text: '$bankName\n',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ],
                                  if (accountNumber.isNotEmpty) ...[
                                    const TextSpan(text: 'A/C: '),
                                    TextSpan(
                                      text: '$accountNumber\n',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ],
                                  if (ifscCode.isNotEmpty) ...[
                                    const TextSpan(text: 'IFSC: '),
                                    TextSpan(
                                      text: ifscCode,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${params.documentTitle} Ref: #${params.quotationId}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    fontFamily: 'serif',
                  ),
                ),
                Text(
                  'Date: ${formatCleanDate(params.date)}',
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 1,
              color: Colors.black12,
            ),
            const SizedBox(height: 12),
          ],

          // Elegant double-line table header
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black12, width: 1.0),
                bottom: BorderSide(color: Colors.black12, width: 1.0),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  child: Text(
                    'NO.',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),
                  ),
                ),
                if (params.gstEnabled)
                  const SizedBox(
                    width: 60,
                    child: Text(
                      'HSN/SAC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 40,
                  child: Text(
                    'QTY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'PRICE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 90,
                  child: Text(
                    'AMOUNT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...List.generate(itemsList.length, (index) {
            final item = itemsList[index];
            final double qty = ((item['quantity'] ?? 1) as num).toDouble();
            final double rate = ((item['rate'] ?? 0.0) as num).toDouble();
            final double amount = qty * rate;
            final itemNo = (pageIndex * 10 + index + 1).toString().padLeft(2, '0');

            return Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      itemNo,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 9,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['description'] as String? ?? '',
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (item['additionalDetails'] != null &&
                            (item['additionalDetails'] as String).trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item['additionalDetails'] as String,
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (params.gstEnabled)
                    SizedBox(
                      width: 60,
                      child: Text(
                        (item['hsn'] ?? '').toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      params.formatCurrency.format(rate),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      params.formatCurrency.format(amount),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Table Bottom Solid Line
          Container(
            height: 1.5,
            color: Colors.black87,
          ),

          if (isLastPage) ...[
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount in Words
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AMOUNT IN WORDS',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        convertNumberToWords(params.total),
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Totals summary block
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(fontSize: 10, color: Colors.black54)),
                          Text(params.formatCurrency.format(params.subtotal), style: const TextStyle(fontSize: 10, color: Colors.black87)),
                        ],
                      ),
                      if (params.discountAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Discount (${params.discountPercentage.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                            Text('- ${params.formatCurrency.format(params.discountAmount)}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                          ],
                        ),
                      ],
                      if (params.gstEnabled && params.taxAmount > 0) ...[
                        const SizedBox(height: 4),
                        if (params.placeOfSupply.toLowerCase().contains((params.tenant['state'] ?? 'telangana').toString().toLowerCase()) || params.placeOfSupply.contains('36')) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CGST', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              Text(params.formatCurrency.format(params.taxAmount / 2), style: const TextStyle(fontSize: 10, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('SGST', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              Text(params.formatCurrency.format(params.taxAmount / 2), style: const TextStyle(fontSize: 10, color: Colors.black87)),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('IGST', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              Text(params.formatCurrency.format(params.taxAmount), style: const TextStyle(fontSize: 10, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ],
                      const Divider(height: 12, color: Colors.black12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            params.formatCurrency.format(params.total),
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Balance Due',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              params.formatCurrency.format(params.total),
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 140,
                          child: _buildSignatureBlock(params),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              height: 2,
              color: Colors.black87,
            ),
            const SizedBox(height: 8),
            const Text(
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
              style: const TextStyle(fontSize: 8, color: Colors.grey, height: 1.3),
            ),
            if (params.placeOfSupply.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Place of Supply: ${params.placeOfSupply}${params.tenant['state'] != null && params.tenant['state']!.isNotEmpty ? ' | Dispatch State: ${params.tenant['state']}' : ''}',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget? _buildLogoWidget(String? logoImage, {double height = 50}) {
    if (logoImage == null || logoImage.isEmpty) {
      return null;
    }
    if (logoImage.startsWith('data:image') || !logoImage.startsWith('http')) {
      try {
        final base64Str = logoImage.contains(',') ? logoImage.split(',')[1] : logoImage;
        return Image.memory(
          base64Decode(base64Str),
          height: height,
          fit: BoxFit.contain,
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
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }
  }

  Widget _buildSignatureBlock(QuotationTemplateParams params) {
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
        
    final TeamController teamController = Get.isRegistered<TeamController>()
        ? Get.find<TeamController>()
        : Get.put(TeamController());

    return Obx(() {
      final currentUserMember = teamController.teamMembers.firstWhereOrNull(
        (m) => m.email.trim().toLowerCase() == authController.userEmail.value.trim().toLowerCase()
      );
      final userSignature = (currentUserMember?.signatureImage != null && currentUserMember!.signatureImage!.isNotEmpty)
          ? currentUserMember.signatureImage
          : (authController.userSignature.value.isNotEmpty ? authController.userSignature.value : null);
      
      final String displayName;
      if (userSignature != null && userSignature.isNotEmpty && currentUserMember != null) {
        displayName = currentUserMember.name;
      } else {
        displayName = params.tenant['authorizedSignatoryName'] ?? params.tenant['name'] ?? '';
      }

      final signatureWidget = _buildLogoWidget(
        (userSignature != null && userSignature.isNotEmpty)
            ? userSignature
            : params.tenant['signatureImage'],
        height: 40,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (signatureWidget != null) ...[
            signatureWidget,
            const SizedBox(height: 4),
          ] else ...[
            const Text(
              'Authorized Sign',
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Container(
            width: 120,
            height: 1,
            color: Colors.black26,
          ),
          const SizedBox(height: 4),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const Text(
            'AUTHORIZED SIGNATORY',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }
}

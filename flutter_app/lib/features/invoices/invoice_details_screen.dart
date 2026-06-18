import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_controller.dart';
import '../clients/clients_controller.dart';
import 'templates/invoice_template_params.dart';
import 'templates/standard_template.dart';
import 'templates/modern_template.dart';
import 'templates/modern_blue_template.dart';
import 'templates/classic_template.dart';
import 'templates/minimalist_template.dart';
import 'templates/elegant_template.dart';
import 'templates/vibrant_template.dart';
import '../../shared/widgets/animated_document_loader.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class InvoiceDetailsController extends GetxController {
  final RxString selectedTemplate = 'standard'.obs;
  final RxBool isLoading = false.obs;

  void changeTemplate(String templateId) {
    selectedTemplate.value = templateId;
  }

  void triggerActionStart() {
    isLoading.value = true;
  }

  void triggerActionEnd() {
    isLoading.value = false;
  }
}

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;
  final String dbId; // Added dbId for public link generation
  final String clientName;
  final double amount;
  final String date;
  final String status;
  final List<Map<String, dynamic>>? items;
  final String? dueDate;
  final String? placeOfSupply;
  final double? discountPercentage;
  final bool? gstEnabled;
  final String? taxType;
  final String? clientEmail;
  final String? clientPhone;
  final String? clientAddress;
  final String? clientGst;
  final double? advancePayment;

  const InvoiceDetailsScreen({
    super.key,
    required this.invoiceId,
    required this.dbId,
    required this.clientName,
    required this.amount,
    required this.date,
    required this.status,
    this.items,
    this.dueDate,
    this.placeOfSupply,
    this.discountPercentage,
    this.gstEnabled,
    this.taxType,
    this.clientEmail,
    this.clientPhone,
    this.clientAddress,
    this.clientGst,
    this.advancePayment,
  });

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final InvoiceDetailsController controller = Get.put(
    InvoiceDetailsController(),
  );
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  final ScreenshotController screenshotController = ScreenshotController();

  Map<String, String> _mockTenant = {};
  Map<String, dynamic> _mockBankDetails = {};
  bool _isLoadingSettings = true;

  void _updateTenantInfo() {
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    final tenant = authController.tenantInfo.value;
    if (tenant == null) {
      _mockTenant = {
        'name': 'Auriva Tech Solutions Pvt Ltd',
        'address': 'Plot 42, Cyber Gateway, Hitech City, Hyderabad, TS - 500081',
        'email': 'billing@aurivatech.com',
        'phone': '+91 98765 43210',
        'website': 'www.aurivatech.com',
        'gstNumber': '36AAAAA1111A1Z1',
        'state': 'Telangana',
        'defaultTerms':
            '1. Payment must be made within 15 days of invoice date.\n2. Interest of 18% per annum will be charged on overdue invoices.\n3. All disputes are subject to Hyderabad jurisdiction.',
      };
      _mockBankDetails = {
        'accountName': 'Auriva Tech Solutions Pvt Ltd',
        'bankName': 'HDFC Bank Ltd',
        'accountNumber': '50200045612378',
        'ifscCode': 'HDFC0000123',
      };
    } else {
      _mockTenant = {
        'name': tenant['name']?.toString() ?? '',
        'address': tenant['address']?.toString() ?? '',
        'email': tenant['email']?.toString() ?? '',
        'phone': tenant['phone']?.toString() ?? '',
        'website': tenant['website']?.toString() ?? '',
        'gstNumber': tenant['gstNumber']?.toString() ?? '',
        'state': tenant['state']?.toString() ?? '',
        'defaultTerms': tenant['defaultTerms']?.toString() ?? '',
        'logoImage': tenant['logoImage']?.toString() ?? '',
        'signatureImage': tenant['signatureImage']?.toString() ?? '',
        'authorizedSignatoryName': authController.userName.value.isNotEmpty
            ? authController.userName.value
            : (tenant['name']?.toString() ?? ''),
      };
      final bank = tenant['bankDetails'];
      if (bank is Map) {
        _mockBankDetails = {
          'accountName': bank['accountName']?.toString() ?? bank['accountHolderName']?.toString() ?? '',
          'bankName': bank['bankName']?.toString() ?? '',
          'accountNumber': bank['accountNumber']?.toString() ?? '',
          'ifscCode': bank['ifscCode']?.toString() ?? bank['ifsc']?.toString() ?? '',
        };
      } else {
        _mockBankDetails = {
          'accountName': '',
          'bankName': '',
          'accountNumber': '',
          'ifscCode': '',
        };
      }
    }
  }

  // Mock Invoice Full Data matching original screen references
  late final List<Map<String, dynamic>> _mockItems;
  late final String _dueDate;
  late final String _placeOfSupply;
  late final double _discountPercentage;
  late final bool _gstEnabled;
  late final String _taxType;
  late final String _clientEmail;
  late final String _clientPhone;
  late final String _clientAddress;
  late final String _clientGst;

  @override
  void initState() {
    super.initState();
    _placeOfSupply = widget.placeOfSupply ?? 'Maharashtra (27)';
    _dueDate = widget.dueDate ?? '01 Jun 2026';
    _discountPercentage = widget.discountPercentage ?? 0.0;
    _gstEnabled = widget.gstEnabled ?? true;
    _taxType = widget.taxType ?? 'exclusive';
    _clientEmail = widget.clientEmail ?? 'billing@client.com';
    _clientPhone = widget.clientPhone ?? '';
    _clientAddress = widget.clientAddress ?? 'Cyber Towers, Madhapur, Hyderabad';
    _clientGst = widget.clientGst ?? '36BBBBB2222B2Z2';

    // Custom mock items based on the invoice clicked
    if (widget.items != null) {
      _mockItems = widget.items!;
    } else {
      if (widget.amount > 30000) {
        _mockItems = [
          {
            'description': 'Enterprise Web Application Development',
            'quantity': 1,
            'rate': 35000.0,
            'hsn': '998311',
            'gst': 18,
          },
          {
            'description': 'Cloud Setup & CI/CD Pipeline Automation',
            'quantity': 1,
            'rate': 8200.0,
            'hsn': '998313',
            'gst': 18,
          },
        ];
      } else {
        _mockItems = [
          {
            'description': 'Mobile App UI/UX Design & Prototyping',
            'quantity': 1,
            'rate': 12000.0,
            'hsn': '998312',
            'gst': 18,
          },
          {
            'description': 'API Integration & Backend Wiring',
            'quantity': 1,
            'rate': 5500.0,
            'hsn': '998311',
            'gst': 18,
          },
        ];
      }
    }

    _updateTenantInfo();
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    
    final String initialTemplate = authController.tenantInfo.value?['templatePreference'] ?? 
                                   authController.tenantInfo.value?['selectedTemplate'] ?? 'standard';
    controller.selectedTemplate.value = initialTemplate;

    authController.fetchTenantSettings().then((_) {
      if (mounted) {
        setState(() {
          _updateTenantInfo();
          final String updatedTemplate = authController.tenantInfo.value?['templatePreference'] ?? 
                                         authController.tenantInfo.value?['selectedTemplate'] ?? 'standard';
          controller.selectedTemplate.value = updatedTemplate;
        });
      }
    }).whenComplete(() {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    });
  }

  String _sanitizePdfText(String text) {
    return text
        .replaceAll('₹', 'Rs')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('”', '"')
        .replaceAll('“', '"')
        .replaceAll('—', '-');
  }

  pw.Widget _buildPdfMetaText(
    pw.Font fontBold,
    pw.Font fontNormal,
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            _sanitizePdfText(label),
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            _sanitizePdfText(value),
            style: pw.TextStyle(
              font: fontNormal,
              fontSize: 10,
              color: PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummaryLine(
    pw.Font fontBold,
    pw.Font fontNormal,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _sanitizePdfText(label),
            style: pw.TextStyle(
              font: isTotal ? fontBold : fontNormal,
              fontSize: isTotal ? 12 : 11,
              color: isTotal ? PdfColors.grey900 : PdfColors.grey700,
            ),
          ),
          pw.Text(
            _sanitizePdfText(value),
            style: pw.TextStyle(
              font: fontBold,
              fontSize: isTotal ? 14 : 11,
              color: isTotal ? PdfColors.grey900 : PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummarySection(
    pw.Font fontBold,
    pw.Font fontNormal, {
    String? templateId,
    PdfColor? primaryColor,
  }) {
    final sub = _subtotal;
    final disc = _discountAmount;
    final tax = _taxAmount;
    final totalVal = _total;

    final supply = _placeOfSupply.toLowerCase();
    final isOutstate =
        supply.isNotEmpty &&
        !supply.contains('telangana') &&
        !supply.contains('36');

    final activeColor = primaryColor ?? PdfColor.fromHex('#4F46E5');
    final isVibrant = templateId == 'vibrant';
    final isMinimalist = templateId == 'minimalist';
    final useSerif = templateId == 'classic';

    pw.Widget buildPdfLine(
      String label,
      String value, {
      bool isGrandTotal = false,
    }) {
      if (isVibrant) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6.0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _sanitizePdfText(label),
                style: pw.TextStyle(
                  font: isGrandTotal ? fontBold : fontNormal,
                  fontSize: isGrandTotal ? 12 : 11,
                  color: PdfColor(
                    PdfColors.white.red,
                    PdfColors.white.green,
                    PdfColors.white.blue,
                    0.8,
                  ),
                ),
              ),
              pw.Text(
                _sanitizePdfText(value),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: isGrandTotal ? 14 : 11,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        );
      }

      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6.0),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              _sanitizePdfText(label),
              style: pw.TextStyle(
                font: isGrandTotal ? fontBold : fontNormal,
                fontSize: isGrandTotal ? 12 : 11,
                color: isGrandTotal ? PdfColors.grey900 : PdfColors.grey500,
                fontStyle: useSerif ? pw.FontStyle.italic : pw.FontStyle.normal,
              ),
            ),
            pw.Text(
              _sanitizePdfText(value),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: isGrandTotal ? 14 : 11,
                color: isGrandTotal
                    ? (isMinimalist ? PdfColors.black : activeColor)
                    : PdfColors.grey900,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        buildPdfLine('Subtotal', 'Rs ${sub.toStringAsFixed(2)}'),
        if (disc > 0)
          buildPdfLine(
            'Discount (${_discountPercentage.toStringAsFixed(0)}%)',
            '-Rs ${disc.toStringAsFixed(2)}',
          ),

        if (_gstEnabled && tax > 0) ...[
          if (isOutstate)
            buildPdfLine('IGST (18%)', 'Rs ${tax.toStringAsFixed(2)}')
          else ...[
            buildPdfLine('CGST (9%)', 'Rs ${(tax / 2).toStringAsFixed(2)}'),
            buildPdfLine('SGST (9%)', 'Rs ${(tax / 2).toStringAsFixed(2)}'),
          ],
        ],
        if (!isVibrant)
          pw.Divider(
            thickness: isMinimalist ? 1.5 : 1,
            color: isMinimalist
                ? PdfColors.black
                : (useSerif ? PdfColor.fromInt(0xFFD97706) : PdfColors.grey300),
          ),
        buildPdfLine(
          useSerif ? 'GRAND TOTAL' : 'Grand Total',
          'Rs ${totalVal.toStringAsFixed(2)}',
          isGrandTotal: true,
        ),
      ],
    );
  }

  pw.Widget _buildPdfItemTable({
    required pw.Font fontBold,
    required pw.Font fontNormal,
    required PdfColor primaryColor,
    PdfColor? headerBgColor,
    PdfColor? headerTextColor,
    pw.TableBorder? border,
    bool minimalist = false,
    bool classic = false,
  }) {
    final List<Map<String, dynamic>> itemsList = widget.items ?? _mockItems;

    // Choose table border depending on the template style
    final tableBorder =
        border ??
        (minimalist
            ? const pw.TableBorder(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                horizontalInside: pw.BorderSide(
                  color: PdfColors.grey100,
                  width: 0.5,
                ),
              )
            : classic
            ? const pw.TableBorder(
                top: pw.BorderSide(color: PdfColors.black, width: 1.5),
                bottom: pw.BorderSide(color: PdfColors.black, width: 1.5),
                horizontalInside: pw.BorderSide(
                  color: PdfColors.amber,
                  width: 0.5,
                ),
              )
            : const pw.TableBorder(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                horizontalInside: pw.BorderSide(
                  color: PdfColors.grey200,
                  width: 0.5,
                ),
              ));

    return pw.Table(
      border: tableBorder,
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: headerBgColor != null
              ? pw.BoxDecoration(
                  color: headerBgColor,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                )
              : const pw.BoxDecoration(),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: pw.Text(
                'Item Description',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: headerTextColor ?? primaryColor,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: pw.Text(
                'Qty',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: headerTextColor ?? primaryColor,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: pw.Text(
                'Rate',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: headerTextColor ?? primaryColor,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: pw.Text(
                'Total',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: headerTextColor ?? primaryColor,
                ),
              ),
            ),
          ],
        ),
        // Item Rows
        ...itemsList.map((item) {
          final qty = double.tryParse(item['quantity'].toString()) ?? 1.0;
          final rate = double.tryParse(item['rate'].toString()) ?? 0.0;
          final itemTotal = qty * rate;
          final nameText =
              item['name']?.toString() ??
              item['description']?.toString() ??
              'Item';
          final descText = item['additionalDetails']?.toString() ?? '';

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _sanitizePdfText(nameText),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.grey900,
                      ),
                    ),
                    if (descText.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _sanitizePdfText(descText),
                        style: pw.TextStyle(
                          font: fontNormal,
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: pw.Text(
                  qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2),
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 9,
                    color: PdfColors.grey900,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: pw.Text(
                  'Rs ${rate.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 9,
                    color: PdfColors.grey900,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: pw.Text(
                  'Rs ${itemTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: PdfColors.grey900,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildStandardPdfLayout(
    pw.Font fontBold,
    pw.Font fontNormal,
    PdfColor primaryColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(_mockTenant['name']!),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.SizedBox(
                  width: 250,
                  child: pw.Text(
                    _sanitizePdfText(_mockTenant['address']!),
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Email: ${_sanitizePdfText(_mockTenant['email']!)}',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Phone: ${_sanitizePdfText(_mockTenant['phone']!)}',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                if (widget.gstEnabled == true)
                  pw.Text(
                    'GSTIN: ${_sanitizePdfText(_mockTenant['gstNumber']!)}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 24,
                    color: primaryColor,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '#${widget.invoiceId}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    color: PdfColors.grey900,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(thickness: 1.5, color: PdfColors.black),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILLED TO',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: PdfColors.grey500,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _sanitizePdfText(widget.clientName),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 13,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.Text(
                  'billing@client.com',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Cyber Towers, Madhapur, Hyderabad',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildPdfMetaText(
                  fontBold,
                  fontNormal,
                  'Invoice Date:',
                  widget.date,
                ),
                _buildPdfMetaText(fontBold, fontNormal, 'Due Date:', _dueDate),
                _buildPdfMetaText(
                  fontBold,
                  fontNormal,
                  'Place of Supply:',
                  _placeOfSupply,
                ),
                _buildPdfMetaText(
                  fontBold,
                  fontNormal,
                  'GSTIN:',
                  _mockTenant['gstNumber']!,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        _buildPdfItemTable(
          fontBold: fontBold,
          fontNormal: fontNormal,
          primaryColor: primaryColor,
          headerBgColor: PdfColors.grey200,
          headerTextColor: PdfColors.black,
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AMOUNT IN WORDS',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _sanitizePdfText(_convertNumberToWords(_total)),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 11,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'BANK DETAILS',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Bank: ${_sanitizePdfText(_mockBankDetails['bankName'])}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    'A/C: ${_sanitizePdfText(_mockBankDetails['accountNumber'])}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    'IFSC: ${_sanitizePdfText(_mockBankDetails['ifscCode'])}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.SizedBox(
              width: 180,
              child: _buildPdfSummarySection(
                fontBold,
                fontNormal,
                templateId: 'standard',
                primaryColor: primaryColor,
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
            pw.Text(
              'Authorized Signatory',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildModernPdfLayout(
    pw.Font fontBold,
    pw.Font fontNormal,
    PdfColor primaryColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Text(
                    'AURIVA',
                    style: pw.TextStyle(
                      font: fontBold,
                      color: PdfColors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _sanitizePdfText(_mockTenant['name']!),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 15,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.Text(
                  _sanitizePdfText(_mockTenant['email']!),
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 28,
                    color: primaryColor,
                  ),
                ),
                pw.Text(
                  '#${widget.invoiceId}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    color: PdfColors.grey900,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 24),

        // Two columns client details and due details
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLIENT DETAILS',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      _sanitizePdfText(widget.clientName),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      'Issued: ${_sanitizePdfText(widget.date)}',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DUE ON',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      _sanitizePdfText(_dueDate),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.Text(
                      'Place: ${_sanitizePdfText(_placeOfSupply)}',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        _buildPdfItemTable(
          fontBold: fontBold,
          fontNormal: fontNormal,
          primaryColor: primaryColor,
          headerBgColor: primaryColor,
          headerTextColor: PdfColors.white,
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BANK ACCREDITATION',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'A/C Name: ${_sanitizePdfText(_mockBankDetails['accountName'])}',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      'Number: ${_sanitizePdfText(_mockBankDetails['accountNumber'])}',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'IFSC: ${_sanitizePdfText(_mockBankDetails['ifscCode'])}',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              child: _buildPdfSummarySection(
                fontBold,
                fontNormal,
                templateId: 'modern',
                primaryColor: primaryColor,
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
            pw.Text(
              'Authorized Signatory',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildModernBluePdfLayout(
    pw.Font fontBold,
    pw.Font fontNormal,
    PdfColor primaryColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Colored Dark Blue Banner Background Container!
        pw.Container(
          padding: const pw.EdgeInsets.all(24),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF0F172A), // Slate 900
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(_mockTenant['name']!),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.SizedBox(
                    width: 260,
                    child: pw.Text(
                      _sanitizePdfText(_mockTenant['address']!),
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: PdfColors.grey300,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'GSTIN: ${_sanitizePdfText(_mockTenant['gstNumber']!)}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor(
                        PdfColors.white.red,
                        PdfColors.white.green,
                        PdfColors.white.blue,
                        0.15,
                      ),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                      border: pw.Border.all(
                        color: PdfColor(
                          PdfColors.white.red,
                          PdfColors.white.green,
                          PdfColors.white.blue,
                          0.2,
                        ),
                      ),
                    ),
                    child: pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '#${widget.invoiceId}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date: ${_sanitizePdfText(widget.date)}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey300,
                    ),
                  ),
                  pw.Text(
                    'Due: ${_sanitizePdfText(_dueDate)}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BILLED TO',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 9,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _sanitizePdfText(widget.clientName),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 13,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.Text(
                    'Place of Supply: ${_sanitizePdfText(_placeOfSupply)}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PAYMENT DETAILS',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 9,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Bank: ${_sanitizePdfText(_mockBankDetails['bankName'])}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.Text(
                    'A/C: ${_sanitizePdfText(_mockBankDetails['accountNumber'])}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'IFSC: ${_sanitizePdfText(_mockBankDetails['ifscCode'])}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        _buildPdfItemTable(
          fontBold: fontBold,
          fontNormal: fontNormal,
          primaryColor: const PdfColor.fromInt(0xFF1E40AF),
          headerBgColor: const PdfColor.fromInt(0xFF1E40AF),
          headerTextColor: PdfColors.white,
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AMOUNT IN WORDS',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _sanitizePdfText(_convertNumberToWords(_total)),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: _buildPdfSummarySection(
                  fontBold,
                  fontNormal,
                  templateId: 'modern-blue',
                  primaryColor: const PdfColor.fromInt(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
            pw.Text(
              'Authorized Signatory',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildClassicPdfLayout(
    pw.Font fontBold,
    pw.Font fontNormal,
    PdfColor primaryColor,
  ) {
    final amberColor = PdfColor.fromInt(0xFFD97706);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                _sanitizePdfText(_mockTenant['name']!.toUpperCase()),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 18,
                  color: PdfColors.black,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _sanitizePdfText(_mockTenant['address']!),
                style: pw.TextStyle(
                  font: fontNormal,
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'GSTIN: ${_sanitizePdfText(_mockTenant['gstNumber']!)}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 2, color: amberColor),
        pw.SizedBox(height: 12),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TO CLIENT:',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _sanitizePdfText(widget.clientName),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 13,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  'Company Client Ltd',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE #${widget.invoiceId}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  'Date: ${_sanitizePdfText(widget.date)}',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Due Date: ${_sanitizePdfText(_dueDate)}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        _buildPdfItemTable(
          fontBold: fontBold,
          fontNormal: fontNormal,
          primaryColor: PdfColors.black,
          classic: true,
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TERMS & CONDITIONS',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _sanitizePdfText(_mockTenant['defaultTerms']!),
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 8,
                      color: PdfColors.grey700,
                      lineSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 32),
            pw.SizedBox(
              width: 180,
              child: _buildPdfSummarySection(
                fontBold,
                fontNormal,
                templateId: 'classic',
                primaryColor: PdfColors.black,
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
            pw.Text(
              'Authorized Signatory',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfClassicSummaryRow(
    pw.Font fontBold,
    pw.Font fontNormal,
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4.0),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fontNormal,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMinimalistPdfLayout(
    pw.Font fontBold,
    pw.Font fontNormal,
    PdfColor primaryColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              _sanitizePdfText(_mockTenant['name']!.toUpperCase()),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 20,
                letterSpacing: 3,
                color: PdfColors.grey800,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          _sanitizePdfText(_mockTenant['address']!),
          style: pw.TextStyle(
            font: fontNormal,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 24),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENT',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _sanitizePdfText(widget.clientName),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Invoice #: ${_sanitizePdfText(widget.invoiceId)}',
                  style: pw.TextStyle(font: fontBold, fontSize: 11),
                ),
                pw.Text(
                  'Issued: ${_sanitizePdfText(widget.date)}',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Due: ${_sanitizePdfText(_dueDate)}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        _buildPdfItemTable(
          fontBold: fontBold,
          fontNormal: fontNormal,
          primaryColor: PdfColors.black,
          minimalist: true,
        ),
        pw.SizedBox(height: 20),

        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.SizedBox(
            width: 200,
            child: _buildPdfSummarySection(
              fontBold,
              fontNormal,
              templateId: 'minimalist',
              primaryColor: PdfColors.black,
            ),
          ),
        ),
        pw.SizedBox(height: 32),
        _buildPdfStandardFooter(fontBold, fontNormal),
      ],
    );
  }

  pw.Widget _buildPdfStandardFooter(pw.Font fontBold, pw.Font fontNormal) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TERMS & CONDITIONS',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 8,
            color: PdfColors.grey500,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _sanitizePdfText(_mockTenant['defaultTerms']!),
          style: pw.TextStyle(
            font: fontNormal,
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildElegantPdfLayout(
    pw.Font fontBold,
    pw.Font fontNormal,
    PdfColor primaryColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizePdfText(_mockTenant['name']!),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _sanitizePdfText(_mockTenant['address']!),
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Text(
              'ELEGANT INVOICE',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
                letterSpacing: 2,
                color: primaryColor,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          height: 2,
          color: PdfColor.fromInt(0xFFE9D5FF),
        ), // Purple 200
        pw.SizedBox(height: 16),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PREPARED FOR',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 8,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _sanitizePdfText(widget.clientName),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 13,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.Text(
                  'Cyber Tower Complex, Hyd',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Invoice Ref: #${_sanitizePdfText(widget.invoiceId)}',
                  style: pw.TextStyle(font: fontBold, fontSize: 11),
                ),
                pw.Text(
                  'Created On: ${_sanitizePdfText(widget.date)}',
                  style: pw.TextStyle(
                    font: fontNormal,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Due Date: ${_sanitizePdfText(_dueDate)}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        _buildPdfItemTable(
          fontBold: fontBold,
          fontNormal: fontNormal,
          primaryColor: primaryColor,
          headerBgColor: const PdfColor.fromInt(0xFFFAF5FF),
          headerTextColor: primaryColor,
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PAYMENT PROTOCOL',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Beneficiary: ${_sanitizePdfText(_mockBankDetails['accountName'])}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    'Bank: ${_sanitizePdfText(_mockBankDetails['bankName'])}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    'A/C Number: ${_sanitizePdfText(_mockBankDetails['accountNumber'])}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    'IFSC: ${_sanitizePdfText(_mockBankDetails['ifscCode'])}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 32),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFAF5FF), // Light Purple
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE9D5FF)),
                ),
                child: _buildPdfSummarySection(
                  fontBold,
                  fontNormal,
                  templateId: 'elegant',
                  primaryColor: primaryColor,
                ),
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
            pw.Text(
              'Authorized Signatory',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVibrantPdfLayout(
    pw.Font fontBold,
    pw.Font fontNormal,
    PdfColor primaryColor,
  ) {
    final vibrantPink = PdfColor.fromInt(0xFFC026D3);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Colored Gradient-mimicking Vibrant Banner background container
        pw.Container(
          padding: const pw.EdgeInsets.all(24),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF7C3AED), // Purple 600
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitizePdfText(_mockTenant['name']!),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.SizedBox(
                    width: 250,
                    child: pw.Text(
                      _sanitizePdfText(_mockTenant['address']!),
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: PdfColor(
                          PdfColors.white.red,
                          PdfColors.white.green,
                          PdfColors.white.blue,
                          0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
                    ),
                    child: pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '#${widget.invoiceId}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date: ${_sanitizePdfText(widget.date)}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 10,
                      color: PdfColor(
                        PdfColors.white.red,
                        PdfColors.white.green,
                        PdfColors.white.blue,
                        0.8,
                      ),
                    ),
                  ),
                  pw.Text(
                    'Due: ${_sanitizePdfText(_dueDate)}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFFF3E8FF),
                    width: 1.5,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILLED CLIENT',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _sanitizePdfText(widget.clientName),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.Text(
                      _sanitizePdfText(_mockTenant['email']!),
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFFFDF2F8),
                    width: 1.5,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REVENUE CHANNEL',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: vibrantPink,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _sanitizePdfText(_mockBankDetails['bankName']),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.Text(
                      'A/C: ${_sanitizePdfText(_mockBankDetails['accountNumber'])}',
                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 10,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        _buildPdfItemTable(
          fontBold: fontBold,
          fontNormal: fontNormal,
          primaryColor: primaryColor,
          headerBgColor: primaryColor,
          headerTextColor: PdfColors.white,
        ),
        pw.SizedBox(height: 20),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AMOUNT IN WORDS',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _sanitizePdfText(_convertNumberToWords(_total)),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(
                    0xFF7C3AED,
                  ), // Vibrant solid purple matches gradient visual cue
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: _buildPdfSummarySection(
                  fontBold,
                  fontNormal,
                  templateId: 'vibrant',
                  primaryColor: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
        pw.Spacer(),
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 8,
                color: PdfColors.grey500,
              ),
            ),
            pw.Text(
              'Authorized Signatory',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<List<Map<String, dynamic>>> _paginateInvoiceItems({
    required List<Map<String, dynamic>> items,
    required double itemHeight,
    required double usableHeight,
    required double headerHeight,
    required double tableHeaderHeight,
    required double totalsHeight,
    double signatureHeight = 0.0,
  }) {
    List<List<Map<String, dynamic>>> pages = [];
    List<Map<String, dynamic>> currentPageItems = [];
    double currentHeight = 0.0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      double requiredHeight = itemHeight;

      double pageCap;
      if (pages.isEmpty) {
        pageCap = usableHeight - headerHeight - tableHeaderHeight;
      } else {
        pageCap = usableHeight - tableHeaderHeight;
      }

      bool isLastItem = (i == items.length - 1);
      if (isLastItem) {
        if (currentHeight + requiredHeight + totalsHeight > pageCap) {
          if (currentPageItems.isNotEmpty) {
            pages.add(currentPageItems);
            currentPageItems = [];
          }
          currentPageItems.add(item);
          // If even on a new page the signature doesn't fit, we might need a 3rd page, but usually it fits.
          // Let's just check if it fits on this new page:
          double newPageCap = usableHeight - tableHeaderHeight;
          if (requiredHeight + totalsHeight + signatureHeight > newPageCap) {
            pages.add(currentPageItems);
            pages.add([]);
          } else {
            pages.add(currentPageItems);
          }
          currentPageItems = [];
        } else {
          // The item and totals fit on this page!
          // But do signature + terms fit?
          if (currentHeight + requiredHeight + totalsHeight + signatureHeight > pageCap) {
            // No! Push signature to next page!
            currentPageItems.add(item);
            pages.add(currentPageItems);
            currentPageItems = [];
            // Create an empty page for signature!
            pages.add([]);
          } else {
            // Everything fits!
            currentPageItems.add(item);
            pages.add(currentPageItems);
            currentPageItems = [];
          }
        }
      } else {
        if (currentHeight + requiredHeight > pageCap) {
          pages.add(currentPageItems);
          currentPageItems = [item];
          currentHeight = requiredHeight;
        } else {
          currentPageItems.add(item);
          currentHeight += requiredHeight;
        }
      }
    }

    if (currentPageItems.isNotEmpty) {
      pages.add(currentPageItems);
    }

    if (pages.isEmpty) {
      pages.add([]);
    }

    return pages;
  }

  Widget _buildOfflineInvoiceA4Page({
    required List<Map<String, dynamic>> pageItems,
    required int pageIndex,
    required int totalPages,
    required bool isFirstPage,
    required bool isLastPage,
  }) {
    return Container(
      width: 794,
      height: 1123,
      color: Colors.white,
      child: _buildSelectedTemplateRenderer(
        controller.selectedTemplate.value,
        pageItems: pageItems,
        isFirstPage: isFirstPage,
        isLastPage: isLastPage,
        pageIndex: pageIndex,
        totalPages: totalPages,
        isOffline: true,
      ),
    );
  }

  Widget _buildBottomFooter(int currentPage, int totalPages) {
    return Column(
      children: [
        const Divider(height: 1, color: Colors.black12),
        const SizedBox(height: 8),
        Row(
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
              'Page $currentPage of $totalPages',
              style: const TextStyle(
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

  Future<void> _generateAndHandlePdf(String action) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedDocumentLoader(message: 'Compiling premium invoice document...'),
    );

    try {
      const double itemHeight = 70.0;
      const double pageHeight = 1123.0;
      const double margin = 40.0;
      const double usableHeight = pageHeight - (margin * 2);
      double headerHeight = 310.0;
      const double tableHeaderHeight = 45.0;
      double totalsHeight = 220.0;
      double signatureHeight = 0.0;
      
      final currentTemplate = controller.selectedTemplate.value;
      if (currentTemplate == 'vibrant') {
        headerHeight = 360.0;
        totalsHeight = 310.0;
        signatureHeight = 170.0;
      }

      final List<Map<String, dynamic>> itemsList = widget.items ?? _mockItems;

      final pages = _paginateInvoiceItems(
        items: itemsList,
        itemHeight: itemHeight,
        usableHeight: usableHeight,
        headerHeight: headerHeight,
        tableHeaderHeight: tableHeaderHeight,
        totalsHeight: totalsHeight,
        signatureHeight: signatureHeight,
      );

      final pdf = pw.Document();

      for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
        final pageItems = pages[pageIndex];

        final previewWidget = MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(794, 1123),
              devicePixelRatio: 1.0,
              textScaler: TextScaler.linear(1.0),
            ),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: _buildOfflineInvoiceA4Page(
                pageItems: pageItems,
                pageIndex: pageIndex,
                totalPages: pages.length,
                isFirstPage: pageIndex == 0,
                isLastPage: pageIndex == pages.length - 1,
              ),
            ),
          ),
        );

        final Uint8List imageBytes = await screenshotController
            .captureFromWidget(
              previewWidget,
              delay: const Duration(milliseconds: 250),
              pixelRatio: 4.0,
              context: context,
              targetSize: const Size(794, 1123),
            );

        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Positioned.fill(
                    child: pw.Image(image, fit: pw.BoxFit.fill),
                  ),
                ],
              );
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();

      if (action == 'Download PDF' ||
          action == 'Print Invoice' ||
          action == 'PDF Generation') {
        navigator.pop(); // Dismiss compilation dialog
        await Printing.layoutPdf(
          format: PdfPageFormat.a4,
          usePrinterSettings: false,
          dynamicLayout: false,
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Invoice_${widget.invoiceId}.pdf',
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final safeId = widget.invoiceId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final file = File('${tempDir.path}/Invoice_$safeId.pdf');
        await file.writeAsBytes(pdfBytes);
        navigator.pop(); // Dismiss compilation dialog
        await Share.shareXFiles([XFile(file.path)], text: 'Here is your invoice from Auriva.');
      }

    } catch (e) {
      navigator.pop(); // Dismiss compilation dialog
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error generating premium PDF: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _triggerAction(String actionName) {
    if (actionName == 'WhatsApp') {
      String phone = _clientPhone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client phone number is missing.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (phone.startsWith('+')) {
        phone = phone.substring(1);
      } else if (phone.length == 10) {
        phone = '91$phone'; // Default to India if 10 digits
      }
      
      final String link = '${ApiConstants.publicWebUrl}/public/invoice/${widget.dbId}';
      final String message = 'Hello ${widget.clientName},\n\nHere is your invoice *${widget.invoiceId}* for the amount of *Rs ${widget.amount}*.\n\nYou can view and download it here:\n$link\n\nThank you!';
      
      final String url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
      
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      });
      return;
    }

    if (actionName == 'Email') {
      _sendEmailViaApi();
      return;
    }

    controller.triggerActionStart();

    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await _generateAndHandlePdf(actionName);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete $actionName: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        controller.triggerActionEnd();
      }
    });
  }

  Future<void> _sendEmailViaApi() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String email = _clientEmail;
    if (email.isEmpty || email == 'billing@client.com') {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Client email address is missing.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AnimatedDocumentLoader(message: 'Sending invoice via email...'),
    );

    final clientsController = Get.isRegistered<ClientsController>()
        ? Get.find<ClientsController>()
        : Get.put(ClientsController());
    final errorMsg = await clientsController.sendInvoiceEmail(widget.dbId);
    
    if (mounted) {
      Navigator.pop(context); // Dismiss loader
    }

    if (errorMsg == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Invoice sent successfully via email.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send email: $errorMsg'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 48,
        titleSpacing: 4,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A), size: 18),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.invoiceId,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  LucideIcons.hexagon,
                  size: 10,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(width: 4),
                Text(
                  'AURIVA INVOICE',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Center(child: PulsingStatusBadge(status: widget.status)),
          const SizedBox(width: 12),
          Center(
            child: InkWell(
              onTap: () => _triggerAction('Print Invoice'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: const [
                    Icon(LucideIcons.printer, size: 14, color: Color(0xFF0F172A)),
                    SizedBox(width: 6),
                    Text(
                      'Print',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
                children: [
                  // Top Template Selection Bar
                  _buildTemplateSelector(),

                  // Bottom Quick Action Buttons
                  _buildActionBar(),

                  // Live Preview Container
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 800),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.04,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.monitor,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'A4 LIVE PREVIEW CANVAS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Interactive Scaling',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 800),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _buildResponsiveTemplateWrapper(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // --- ACTIONS HEADER PANEL ---
  Widget _buildActionBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: DynamicActionButton(
              onTap: () => _triggerAction('WhatsApp'),
              icon: LucideIcons.messageCircle,
              label: 'WhatsApp',
              iconColor: const Color(0xFF059669),
              textColor: const Color(0xFF059669),
              backgroundColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFD1FAE5),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DynamicActionButton(
              onTap: () => _triggerAction('Email'),
              icon: LucideIcons.mail,
              label: 'Email',
              iconColor: const Color(0xFF2563EB),
              textColor: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFDBEAFE),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)), // Divider
          const SizedBox(width: 8),
          Expanded(
            child: DynamicActionButton(
              onTap: () => _triggerAction('Share'),
              icon: LucideIcons.share2,
              label: 'Share',
              iconColor: const Color(0xFF475569),
              textColor: const Color(0xFF0F172A),
              backgroundColor: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 1,
            child: DynamicActionButton(
              onTap: () => _triggerAction('Download PDF'),
              icon: LucideIcons.download,
              label: 'Download',
              iconColor: Colors.white,
              textColor: Colors.white,
              backgroundColor: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return const SizedBox.shrink();
  }

  // --- MATH CALCULATION HELPER FUNCTIONS ---
  double get _subtotal {
    return _mockItems.fold(0.0, (sum, item) {
      double qty = (item['quantity'] as num).toDouble();
      double rate = (item['rate'] as num).toDouble();
      return sum + (qty * rate);
    });
  }

  double get _discountAmount {
    return _subtotal * (_discountPercentage / 100);
  }

  double get _taxableAmount {
    return _subtotal - _discountAmount;
  }

  double get _taxAmount {
    if (!_gstEnabled) return 0.0;

    double calculatedTax = 0.0;
    for (var item in _mockItems) {
      double qty = (item['quantity'] as num).toDouble();
      double rate = (item['rate'] as num).toDouble();
      double gstRate = ((item['gst'] ?? item['gstRate'] ?? 18.0) as num)
          .toDouble();

      double itemSubtotal = qty * rate;
      double itemDiscount = itemSubtotal * (_discountPercentage / 100);
      double itemTaxable = itemSubtotal - itemDiscount;

      if (_taxType == 'exclusive') {
        calculatedTax += itemTaxable * (gstRate / 100);
      } else {
        double basePrice = itemTaxable / (1 + (gstRate / 100));
        calculatedTax += itemTaxable - basePrice;
      }
    }
    return calculatedTax;
  }

  double get _total {
    if (_taxType == 'exclusive') {
      return _taxableAmount + _taxAmount;
    } else {
      return _taxableAmount;
    }
  }

  String _convertNumberToWords(double amount) {
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

  Widget _buildResponsiveTemplateWrapper() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Standard logical width that mimics the high-fidelity desktop A4 print preview
        const double targetWidth = 794.0;
        final double availableWidth = constraints.maxWidth;

        return Obx(() {
          final currentTemplate = controller.selectedTemplate.value;

          double headerHeight = 310.0;
          double totalsHeight = 220.0;
          double signatureHeight = 0.0;
          if (currentTemplate == 'vibrant') {
            headerHeight = 360.0;
            totalsHeight = 310.0;
            signatureHeight = 170.0;
          }
          
          final pages = _paginateInvoiceItems(
            items: widget.items ?? _mockItems,
            itemHeight: 70.0,
            usableHeight: 1123.0 - (40.0 * 2),
            headerHeight: headerHeight,
            tableHeaderHeight: 45.0,
            totalsHeight: totalsHeight,
            signatureHeight: signatureHeight,
          );

          // Single continuous scrollable page for the live preview!
          Widget templateWidget = Container(
            width: targetWidth,
            constraints: BoxConstraints(minHeight: targetWidth * 1.414), // MINIMUM A4 size, but grows if content is larger!
            child: IntrinsicHeight(
              child: _buildSelectedTemplateRenderer(
                currentTemplate, 
                pageItems: widget.items ?? _mockItems, // Render ALL items at once
                isOffline: false,
                isFirstPage: true,
                isLastPage: true,
                pageIndex: 0,
                totalPages: 1,
              ),
            ),
          );

          Widget childWidget;
          if (availableWidth >= targetWidth) {
            childWidget = Center(child: templateWidget);
          } else {
            // Scales the wide desktop template proportionally down to the mobile screen size WIDTH,
            // while allowing the HEIGHT to stretch downwards without shrinking the aspect ratio!
            childWidget = FittedBox(
              fit: BoxFit.fitWidth, 
              alignment: Alignment.topCenter,
              child: templateWidget,
            );
          }

          return Skeletonizer(
            enabled: _isLoadingSettings,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.97,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<String>(currentTemplate),
                child: childWidget,
              ),
            ),
          );
        });
      },
    );
  }

  // --- TEMPLATE RENDERING ROUTER ---
  Widget _buildSelectedTemplateRenderer(
    String templateId, {
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final params = InvoiceTemplateParams(
      tenant: _mockTenant,
      clientName: widget.clientName,
      clientAddress: _clientAddress,
      clientEmail: _clientEmail,
      clientPhone: _clientPhone,
      clientGst: _clientGst,
      invoiceId: widget.invoiceId,
      date: widget.date,
      dueDate: _dueDate,
      placeOfSupply: _placeOfSupply,
      gstEnabled: _gstEnabled,
      taxType: _taxType,
      items: _mockItems,
      bankDetails: Map<String, String>.from(_mockBankDetails),
      subtotal: _subtotal,
      discountPercentage: _discountPercentage,
      discountAmount: _discountAmount,
      taxAmount: _taxAmount,
      total: _total,
      advancePayment: widget.advancePayment ?? 0.0,
      formatCurrency: formatCurrency,
    );

    switch (templateId) {
      case 'modern':
        return ModernTemplate(
          params: params,
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'modern-blue':
        return ModernBlueTemplate(
          params: params,
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'classic':
        return ClassicTemplate(
          params: params,
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'minimalist':
        return MinimalistTemplate(
          params: params,
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'elegant':
        return ElegantTemplate(
          params: params,
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'vibrant':
        return VibrantTemplate(
          params: params,
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'standard':
      default:
        return StandardTemplate(
          params: params,
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
    }
  }


}

// --- PREMIUM CUSTOM ANIMATION AND UI COMPONENT CLASSES ---

class ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const ScaleOnPress({super.key, required this.child, required this.onTap});

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

class PulsingStatusBadge extends StatefulWidget {
  final String status;
  const PulsingStatusBadge({super.key, required this.status});

  @override
  State<PulsingStatusBadge> createState() => _PulsingStatusBadgeState();
}

class _PulsingStatusBadgeState extends State<PulsingStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUnpaid = widget.status.toUpperCase() == 'UNPAID';
    final baseColor = isUnpaid ? AppColors.warning : AppColors.success;
    final text = widget.status.toUpperCase();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: baseColor.withValues(
                alpha: 0.2 + 0.3 * _pulseAnimation.value,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(
                  alpha: 0.15 * _pulseAnimation.value,
                ),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor,
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1 * _pulseAnimation.value,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: baseColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DynamicActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final VoidCallback onTap;

  const DynamicActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.gradientColors,
    required this.onTap,
  });

  @override
  State<DynamicActionButton> createState() => _DynamicActionButtonState();
}

class _DynamicActionButtonState extends State<DynamicActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: widget.gradientColors == null
                ? (widget.backgroundColor ?? Colors.white)
                : null,
            gradient: widget.gradientColors != null
                ? LinearGradient(colors: widget.gradientColors!)
                : null,
            borderRadius: BorderRadius.circular(10),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            boxShadow: [
              BoxShadow(
                color:
                    (widget.gradientColors != null
                            ? widget.gradientColors![0]
                            : (widget.backgroundColor ?? Colors.black))
                        .withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 14, color: widget.iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.textColor ?? AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

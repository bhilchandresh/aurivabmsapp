import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/animated_document_loader.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import '../auth/auth_controller.dart';
import '../clients/clients_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'templates/quotation_template_params.dart';
import 'templates/standard_template.dart';
import 'templates/modern_template.dart';
import 'templates/modern_blue_template.dart';
import 'templates/classic_template.dart';
import 'templates/minimalist_template.dart';
import 'templates/elegant_template.dart';
import 'templates/vibrant_template.dart';

class QuotationDetailsScreen extends StatefulWidget {
  final String quotationId;
  final String dbId;
  final String clientName;
  final double amount;
  final String date;
  final String status;
  final List<Map<String, dynamic>>? items;
  final String? validUntil;
  final String? placeOfSupply;
  final double? discountPercentage;
  final bool? gstEnabled;
  final String? taxType;
  final String? clientEmail;
  final String? clientPhone;
  final String? clientAddress;
  final double? advancePayment;
  final String? templateId;

  const QuotationDetailsScreen({
    super.key,
    required this.quotationId,
    required this.dbId,
    required this.clientName,
    required this.amount,
    required this.date,
    required this.status,
    this.items,
    this.validUntil,
    this.placeOfSupply,
    this.discountPercentage,
    this.gstEnabled,
    this.taxType,
    this.clientEmail,
    this.clientPhone,
    this.clientAddress,
    this.advancePayment,
    this.templateId,
  });

  @override
  State<QuotationDetailsScreen> createState() => _QuotationDetailsScreenState();
}

class _QuotationDetailsScreenState extends State<QuotationDetailsScreen> {
  late final List<Map<String, dynamic>> _proposalItems;
  late String _currentStatus;
  late final String _validUntil;
  late final String _placeOfSupply;
  late final double _discountPercentage;
  late final bool _gstEnabled;
  late final String _taxType;
  late final String _clientEmail;
  late final String _clientAddress;

  late String _selectedTemplate;
  bool _isLoading = false;
  bool _isTemplateLoading = true;

  final ScreenshotController screenshotController = ScreenshotController();
  final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  Map<String, String> _companyInfo = {};
  Map<String, dynamic> _mockBankDetails = {};

  void _updateTenantInfo() {
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    final tenant = authController.tenantInfo.value;
    if (tenant == null) {
      _companyInfo = {
        'name': 'Auriva Tech Solutions Pvt Ltd',
        'address': 'Plot 42, Hitech City, Hyderabad, TS - 500081',
        'email': 'billing@aurivatech.com',
        'phone': '+91 98765 43210',
        'website': 'www.aurivatech.com',
        'gstNumber': '36AAAAA1111A1Z1',
        'state': 'Telangana',
        'defaultTerms': '1. Standard validity is 30 days from the estimate date.\n2. 50% advance payment required to commence work.\n3. Goods once sold/services rendered cannot be returned.',
      };
      _mockBankDetails = {
        'bankName': 'HDFC Bank Ltd',
        'accountName': 'Auriva Tech Solutions Pvt Ltd',
        'accountNumber': '50200086745321',
        'ifscCode': 'HDFC0000042',
        'branchName': 'Hitech City, Hyderabad',
      };
    } else {
      _companyInfo = {
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

  double get _subtotal {
    return _proposalItems.fold(0.0, (sum, item) {
      double qty = ((item['quantity'] ?? 1) as num).toDouble();
      double rate = ((item['rate'] ?? 0.0) as num).toDouble();
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
    for (var item in _proposalItems) {
      double qty = ((item['quantity'] ?? 1) as num).toDouble();
      double rate = ((item['rate'] ?? 0.0) as num).toDouble();
      double gstRate = ((item['gst'] ?? item['gstRate'] ?? 18.0) as num).toDouble();
      
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

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
    _validUntil = widget.validUntil ?? '17 Jun 2026';
    _placeOfSupply = widget.placeOfSupply ?? 'Maharashtra (27)';
    _discountPercentage = widget.discountPercentage ?? 0.0;
    _gstEnabled = widget.gstEnabled ?? true;
    _taxType = widget.taxType ?? 'exclusive';
    _clientEmail = widget.clientEmail ?? '${widget.clientName.toLowerCase().replaceAll(' ', '')}@acme.com';
    _clientAddress = widget.clientAddress ?? 'Corporate Hub, Sector V, Hitech Avenue, Suite 101';

    if (widget.items != null) {
      _proposalItems = widget.items!;
    } else {
      if (widget.amount > 30000) {
        _proposalItems = [
          {'description': 'Enterprise Web Suite - Modular Engineering', 'quantity': 1.0, 'rate': 28000.0, 'gst': 18.0, 'additionalDetails': 'NextJS Frontend + Node Backend Wiring'},
          {'description': 'Cloud Setup & Devops Configs', 'quantity': 1.0, 'rate': 7000.0, 'gst': 18.0, 'additionalDetails': 'CI/CD Pipelines, AWS deployment setup'},
        ];
      } else {
        _proposalItems = [
          {'description': 'Mobile App UI/UX Mockups & Interactive Prototype', 'quantity': 1.0, 'rate': 10000.0, 'gst': 18.0, 'additionalDetails': 'Figma deliverables and design tokens'},
          {'description': 'Consultation & System Architecture Plan', 'quantity': 1.0, 'rate': 5000.0, 'gst': 18.0, 'additionalDetails': 'Database and schema diagrams'},
        ];
      }
    }

    _updateTenantInfo();
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    
    final String initialTemplate = authController.tenantInfo.value?['quotationTemplate'] ?? 
                                   authController.tenantInfo.value?['templatePreference'] ?? 
                                   authController.tenantInfo.value?['selectedTemplate'] ?? 'standard';
                                   
    _selectedTemplate = widget.templateId?.isNotEmpty == true ? widget.templateId! : initialTemplate;

    authController.fetchTenantSettings().then((_) {
      if (mounted) {
        setState(() {
          _updateTenantInfo();
          final String updatedTemplate = authController.tenantInfo.value?['quotationTemplate'] ?? 
                                         authController.tenantInfo.value?['templatePreference'] ?? 
                                         authController.tenantInfo.value?['selectedTemplate'] ?? 'standard';
          _selectedTemplate = widget.templateId?.isNotEmpty == true ? widget.templateId! : updatedTemplate;
          _isTemplateLoading = false;
        });
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      case 'Rejected':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  void _updateStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proposal status updated to $newStatus'),
        backgroundColor: _getStatusColor(newStatus),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<List<Map<String, dynamic>>> _paginateQuotationItems({
    required List<Map<String, dynamic>> items,
    required double itemHeight,
    required double usableHeight,
    required double headerHeight,
    required double tableHeaderHeight,
    required double totalsHeight,
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
          pages.add(currentPageItems);
          currentPageItems = [];
        } else {
          currentPageItems.add(item);
          pages.add(currentPageItems);
          currentPageItems = [];
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

  Future<void> _exportPdfWithScreenshot(String action) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedDocumentLoader(message: 'Compiling premium proposal document...'),
    );

    try {
      const double itemHeight = 70.0;
      const double pageHeight = 1123.0;
      const double margin = 40.0;
      const double usableHeight = pageHeight - (margin * 2);
      const double headerHeight = 310.0;
      const double tableHeaderHeight = 45.0;
      const double totalsHeight = 220.0;

      final pages = _paginateQuotationItems(
        items: _proposalItems,
        itemHeight: itemHeight,
        usableHeight: usableHeight,
        headerHeight: headerHeight,
        tableHeaderHeight: tableHeaderHeight,
        totalsHeight: totalsHeight,
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
              body: _buildOfflineQuotationA4Page(
                pageItems: pageItems,
                pageIndex: pageIndex,
                totalPages: pages.length,
                isFirstPage: pageIndex == 0,
                isLastPage: pageIndex == pages.length - 1,
              ),
            ),
          ),
        );

        final Uint8List imageBytes = await screenshotController.captureFromWidget(
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
                    child: pw.Image(
                      image,
                      fit: pw.BoxFit.fill,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();

      if (action == 'Print Invoice' || action == 'Download PDF' || action == 'Print Quotation') {
        navigator.pop();
        await Printing.layoutPdf(
          format: PdfPageFormat.a4,
          usePrinterSettings: false,
          dynamicLayout: false,
          onLayout: (PdfPageFormat format) async {
            return pdfBytes;
          },
          name: 'Quotation_${widget.quotationId}.pdf',
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final safeId = widget.quotationId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final file = File('${tempDir.path}/Quotation_$safeId.pdf');
        await file.writeAsBytes(pdfBytes);
        navigator.pop();
        await Share.shareXFiles([XFile(file.path)], text: 'Here is your quotation.');
      }
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error generating premium PDF: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildOfflineQuotationA4Page({
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
        _selectedTemplate,
        pageItems: pageItems,
        isFirstPage: isFirstPage,
        isLastPage: isLastPage,
        pageIndex: pageIndex,
        totalPages: totalPages,
        isOffline: true,
      ),
    );
  }

  Widget _buildSelectedTemplateRenderer(
    String templateId, {
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final params = QuotationTemplateParams(
      tenant: _companyInfo,
      clientName: widget.clientName,
      clientAddress: _clientAddress,
      clientEmail: _clientEmail,
      clientGst: '',
      quotationId: widget.quotationId,
      date: widget.date,
      dueDate: _validUntil,
      placeOfSupply: _placeOfSupply,
      gstEnabled: _gstEnabled,
      taxType: _taxType,
      items: _proposalItems,
      bankDetails: Map<String, String>.from(_mockBankDetails),
      subtotal: _subtotal,
      discountPercentage: _discountPercentage,
      discountAmount: _discountAmount,
      taxAmount: _taxAmount,
      total: _total,
      formatCurrency: formatCurrency,
      documentTitle: 'QUOTATION',
      numberLabel: 'Quotation No',
      dateLabel: 'Quotation Date',
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

  void _triggerAction(String actionName) {
    if (actionName == 'WhatsApp') {
      String phone = (widget.clientPhone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
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
      
      final String link = '${ApiConstants.publicWebUrl}/public/quotation/${widget.dbId}';
      final String message = 'Hello ${widget.clientName},\n\nHere is your proposal *${widget.quotationId}* for the amount of *Rs ${widget.amount}*.\n\nYou can view and download it here:\n$link\n\nThank you!';
      
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

    _exportPdfWithScreenshot(actionName);
  }

  Future<void> _sendEmailViaApi() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String email = widget.clientEmail ?? '';
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
      builder: (context) => const AnimatedDocumentLoader(message: 'Sending quotation via email...'),
    );

    final clientsController = Get.isRegistered<ClientsController>()
        ? Get.find<ClientsController>()
        : Get.put(ClientsController());
    final errorMsg = await clientsController.sendQuotationEmail(widget.dbId);
    
    if (mounted) {
      Navigator.pop(context); // Dismiss loader
    }

    if (errorMsg == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Quotation sent successfully via email.'),
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


  // --- HORIZONTAL TEMPLATE SELECTOR WIDGET ---
  Widget _buildTemplateSelector() {
    final templates = [
      {
        'id': 'standard',
        'name': 'Standard',
        'icon': LucideIcons.fileText,
        'color': Colors.grey[700]!,
      },
      {
        'id': 'modern',
        'name': 'Modern',
        'icon': LucideIcons.layoutGrid,
        'color': AppColors.primary,
      },
      {
        'id': 'modern-blue',
        'name': 'Modern Blue',
        'icon': LucideIcons.layoutList,
        'color': Colors.blue[800]!,
      },
      {
        'id': 'classic',
        'name': 'Classic',
        'icon': LucideIcons.bookOpen,
        'color': Colors.amber[900]!,
      },
      {
        'id': 'minimalist',
        'name': 'Minimalist',
        'icon': LucideIcons.minus,
        'color': Colors.black,
      },
      {
        'id': 'elegant',
        'name': 'Elegant',
        'icon': LucideIcons.crown,
        'color': Colors.deepPurple,
      },
      {
        'id': 'vibrant',
        'name': 'Vibrant',
        'icon': LucideIcons.sparkles,
        'color': Colors.pink[600]!,
      },
    ];

    return Container(
      height: 94,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final temp = templates[index];
          final isSelected = _selectedTemplate == temp['id'];
          final activeColor = temp['color'] as Color;

          return FutureBuilder<void>(
            future: Future.delayed(Duration(milliseconds: index * 40)),
            builder: (context, snapshot) {
              final visible = snapshot.connectionState == ConnectionState.done;
              return AnimatedOpacity(
                opacity: visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0.2, 0.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    key: ValueKey(temp['id']),
                    child: ScaleOnPress(
                      onTap: () {
                        setState(() {
                          _selectedTemplate = temp['id'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeColor : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: activeColor.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              temp['icon'] as IconData,
                              size: 20,
                              color: isSelected ? activeColor : Colors.grey,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              temp['name'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                color: isSelected ? activeColor : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildResponsiveTemplateWrapper() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double targetWidth = 794.0;
        final double availableWidth = constraints.maxWidth;

        Widget templateWidget = Container(
          width: targetWidth,
          constraints: BoxConstraints(minHeight: targetWidth * 1.414),
          child: IntrinsicHeight(
            child: _buildSelectedTemplateRenderer(_selectedTemplate),
          ),
        );

        Widget childWidget;
        if (availableWidth >= targetWidth) {
          childWidget = Center(child: templateWidget);
        } else {
          childWidget = FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: templateWidget,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>(_selectedTemplate),
            child: childWidget,
          ),
        );
      },
    );
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
              widget.quotationId,
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
                  'AURIVA PROPOSAL',
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
          Center(child: PulsingStatusBadge(status: _currentStatus)),
          const SizedBox(width: 12),
          Center(
            child: InkWell(
              onTap: () => _triggerAction('Print Quotation'),
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
                _buildActionBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Skeletonizer(
                                enabled: _isTemplateLoading,
                                child: _buildResponsiveTemplateWrapper(),
                              ),
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
}

class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeInUp({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(widget.delay, () => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

class ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const ScaleOnPress({super.key, required this.child, required this.onTap});

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
        child: widget.child,
      ),
    );
  }
}

class PulsingStatusBadge extends StatefulWidget {
  final String status;
  const PulsingStatusBadge({super.key, required this.status});

  @override
  State<PulsingStatusBadge> createState() => _PulsingStatusBadgeState();
}

class _PulsingStatusBadgeState extends State<PulsingStatusBadge> with SingleTickerProviderStateMixin {
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
    final statusUpper = widget.status.toUpperCase();
    final Color baseColor;
    if (statusUpper == 'ACCEPTED') {
      baseColor = AppColors.success;
    } else if (statusUpper == 'REJECTED') {
      baseColor = AppColors.error;
    } else {
      baseColor = AppColors.warning;
    }
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: baseColor.withOpacity(0.2 + 0.3 * _pulseAnimation.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.15 * _pulseAnimation.value),
                blurRadius: 8,
                spreadRadius: 1,
              )
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
                      color: baseColor.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1 * _pulseAnimation.value,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusUpper,
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

class _DynamicActionButtonState extends State<DynamicActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
            color: widget.gradientColors == null ? (widget.backgroundColor ?? Colors.white) : null,
            gradient: widget.gradientColors != null ? LinearGradient(colors: widget.gradientColors!) : null,
            borderRadius: BorderRadius.circular(10),
            border: widget.borderColor != null ? Border.all(color: widget.borderColor!) : null,
            boxShadow: [
              BoxShadow(
                color: (widget.gradientColors != null ? widget.gradientColors![0] : (widget.backgroundColor ?? Colors.black)).withValues(alpha: 0.08),
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

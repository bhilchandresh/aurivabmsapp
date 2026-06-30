import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../clients/clients_controller.dart';
import '../inventory/inventory_controller.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_controller.dart';
import 'quotation_details_screen.dart';
import '../../shared/widgets/app_loader.dart';
import '../../core/constants/app_typography.dart';

class _ItemControllers {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final rateController = TextEditingController(text: '0.00');
  final hsnController = TextEditingController();
  final gstController = TextEditingController(text: '18');

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    hsnController.dispose();
    gstController.dispose();
  }
}

class CreateQuotationScreen extends StatefulWidget {
  final Map<String, dynamic>? quotationToEdit;
  const CreateQuotationScreen({super.key, this.quotationToEdit});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  bool _gstEnabled = false;
  String _taxType = 'exclusive';
  Map<String, String> _companyInfo = {};
  Map<String, String> _mockBankDetails = {};

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
        'defaultTerms':
            '1. Standard validity is 30 days from the estimate date.\n2. 50% advance payment required to commence work.\n3. Goods once sold/services rendered cannot be returned.',
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
      };
      final bank = tenant['bankDetails'];
      if (bank is Map) {
        _mockBankDetails = {
          'bankName': bank['bankName']?.toString() ?? '',
          'accountName': bank['accountName']?.toString() ?? '',
          'accountNumber': bank['accountNumber']?.toString() ?? '',
          'ifscCode': bank['ifscCode']?.toString() ?? '',
          'branchName': bank['branchName']?.toString() ?? '',
        };
      } else {
        _mockBankDetails = {
          'bankName': '',
          'accountName': '',
          'accountNumber': '',
          'ifscCode': '',
          'branchName': '',
        };
      }
    }
    final terms = _companyInfo['defaultTerms'] ?? '';
    if (terms.isNotEmpty) {
      if (_termsController.text == 'default_terms_notes'.tr ||
          _termsController.text.isEmpty) {
        _termsController.text = terms;
      }
    }
  }

  // State controllers
  final ClientsController _clientsController =
      Get.isRegistered<ClientsController>()
      ? Get.find<ClientsController>()
      : Get.put(ClientsController());

  final InventoryController _inventoryController =
      Get.isRegistered<InventoryController>()
      ? Get.find<InventoryController>()
      : Get.put(InventoryController());

  final _clientSearchController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientGstController = TextEditingController();
  final _quoteNumberController = TextEditingController();
  final _quoteDateController = TextEditingController();
  final _validUntilController = TextEditingController();
  final _placeOfSupplyController = TextEditingController();
  final _discountPercentageController = TextEditingController(text: '0');
  final _advanceReceivedController = TextEditingController(text: '0');
  final _termsController = TextEditingController(
    text: 'default_terms_notes'.tr,
  );

  List<Client> _filteredClients = [];
  bool _showSuggestions = false;
  String? _selectedClientId;

  final List<_ItemControllers> _itemsControllers = [];
  final ScreenshotController screenshotController = ScreenshotController();

  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // Calculated totals
  double _subtotal = 0.0;
  double _discountAmount = 0.0;
  double _taxAmount = 0.0;
  double _total = 0.0;
  String _selectedTemplate = 'standard';

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _clientsController.fetchClients();
    _inventoryController.fetchItems();
    _updateTenantInfo();
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);
    _selectedTemplate =
        authController.tenantInfo.value?['quotationTemplate'] ?? 'standard';

    authController.fetchTenantSettings().then((_) {
      if (mounted) {
        setState(() {
          _updateTenantInfo();
          _selectedTemplate =
              authController.tenantInfo.value?['quotationTemplate'] ??
              'standard';
        });
      }
    });

    if (widget.quotationToEdit != null) {
      final qt = widget.quotationToEdit!;
      _quoteNumberController.text =
          qt['quoteNumber'] ?? qt['quotationNumber'] ?? '';

      if (qt['date'] != null && qt['date'].toString().isNotEmpty) {
        try {
          _quoteDateController.text = qt['date'].toString().split('T')[0];
        } catch (_) {
          _quoteDateController.text = qt['date'].toString();
        }
      } else {
        _quoteDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());
      }

      if (qt['validUntil'] != null && qt['validUntil'].toString().isNotEmpty) {
        try {
          _validUntilController.text = qt['validUntil'].toString().split(
            'T',
          )[0];
        } catch (_) {
          _validUntilController.text = qt['validUntil'].toString();
        }
      } else {
        _validUntilController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().add(const Duration(days: 30)));
      }

      final clientObj = qt['client'] ?? {};
      _clientNameController.text = clientObj['name'] ?? '';
      _clientEmailController.text = clientObj['email'] ?? '';
      _clientAddressController.text = clientObj['address'] ?? '';
      _clientPhoneController.text = clientObj['phone'] ?? '';
      _clientGstController.text =
          clientObj['gstin'] ?? clientObj['gstNumber'] ?? '';

      String pos =
          qt['placeOfSupply'] ?? clientObj['state'] ?? 'Maharashtra (27)';
      _placeOfSupplyController.text = pos;
      _selectedClientId =
          clientObj['clientId'] ?? clientObj['_id'] ?? clientObj['id'];

      _gstEnabled = qt['gstEnabled'] ?? false;
      _taxType = qt['taxType'] ?? 'exclusive';
      _discountPercentageController.text = (qt['discountPercentage'] ?? 0)
          .toString();
      _advanceReceivedController.text =
          (qt['advancePayment'] ?? qt['advanceReceived'] ?? 0.0).toString();
      _termsController.text = qt['terms'] ?? 'default_terms_notes'.tr;

      final List<dynamic> itemsList = qt['items'] ?? [];
      for (var item in itemsList) {
        final controller = _ItemControllers();
        controller.nameController.text = item['description'] ?? '';
        controller.descriptionController.text = item['additionalDetails'] ?? '';
        controller.qtyController.text = (item['quantity'] ?? 1).toString();
        controller.rateController.text = (item['rate'] ?? 0.0).toString();
        controller.hsnController.text = item['hsnCode'] ?? item['hsn'] ?? '';
        controller.gstController.text = (item['gstRate'] ?? item['gst'] ?? 18)
            .toString();

        controller.nameController.addListener(_onFieldChanged);
        controller.rateController.addListener(_onFieldChanged);
        _itemsControllers.add(controller);
      }
      if (_itemsControllers.isEmpty) {
        _itemsControllers.add(_ItemControllers());
        _itemsControllers[0].nameController.addListener(_onFieldChanged);
        _itemsControllers[0].rateController.addListener(_onFieldChanged);
      }
    } else {
      _quoteNumberController.text =
          'QT-2026-${(100 + DateTime.now().millisecond % 900).toString()}';
      _quoteDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      _validUntilController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 30)));
      _placeOfSupplyController.text = 'Maharashtra (27)';

      _itemsControllers.add(_ItemControllers());
      _itemsControllers[0].nameController.addListener(_onFieldChanged);
      _itemsControllers[0].rateController.addListener(_onFieldChanged);
    }

    _clientNameController.addListener(_onFieldChanged);
    _quoteNumberController.addListener(_onFieldChanged);
    _clientSearchController.addListener(_onClientSearchChanged);

    _calculateTotals();
  }

  void _onClientSearchChanged() {
    final query = _clientSearchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      final matches = _clientsController.clients
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
      setState(() {
        _filteredClients = matches;
        _showSuggestions = matches.isNotEmpty;
      });
    } else {
      setState(() {
        _filteredClients = [];
        _showSuggestions = false;
      });
    }
  }

  @override
  void dispose() {
    _clientNameController.removeListener(_onFieldChanged);
    _quoteNumberController.removeListener(_onFieldChanged);
    _clientSearchController.removeListener(_onClientSearchChanged);
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _clientSearchController.dispose();
    _clientPhoneController.dispose();
    _clientGstController.dispose();
    _quoteNumberController.dispose();
    _quoteDateController.dispose();
    _validUntilController.dispose();
    _placeOfSupplyController.dispose();
    _discountPercentageController.dispose();
    _advanceReceivedController.dispose();
    _termsController.dispose();
    for (var controller in _itemsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      final newControllers = _ItemControllers();
      newControllers.nameController.addListener(_onFieldChanged);
      newControllers.rateController.addListener(_onFieldChanged);
      _itemsControllers.add(newControllers);
    });
    _calculateTotals();
  }

  void _removeItem(int index) {
    if (_itemsControllers.length > 1) {
      setState(() {
        _itemsControllers[index].nameController.removeListener(_onFieldChanged);
        _itemsControllers[index].rateController.removeListener(_onFieldChanged);
        _itemsControllers[index].dispose();
        _itemsControllers.removeAt(index);
      });
      _calculateTotals();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_req_item'.tr)));
    }
  }

  void _calculateTotals() {
    double sub = 0.0;
    double tax = 0.0;
    double disc = double.tryParse(_discountPercentageController.text) ?? 0.0;

    for (var item in _itemsControllers) {
      double qty = double.tryParse(item.qtyController.text) ?? 1.0;
      double rate = double.tryParse(item.rateController.text) ?? 0.0;
      double gstRate = double.tryParse(item.gstController.text) ?? 18.0;

      double itemTotal = qty * rate;
      sub += itemTotal;

      if (_gstEnabled) {
        if (_taxType == 'exclusive') {
          tax += itemTotal * (gstRate / 100);
        } else {
          double singleTax = itemTotal - (itemTotal / (1 + (gstRate / 100)));
          tax += singleTax;
        }
      }
    }

    _subtotal = sub;
    _discountAmount = sub * (disc / 100);

    if (_gstEnabled && _taxType == 'exclusive') {
      _taxAmount = tax;
      _total = (_subtotal - _discountAmount) + _taxAmount;
    } else if (_gstEnabled && _taxType == 'inclusive') {
      _taxAmount = tax;
      _total = _subtotal - _discountAmount;
    } else {
      _taxAmount = 0.0;
      _total = _subtotal - _discountAmount;
    }
  }

  // Pure mathematical dynamic paginator
  List<List<Map<String, dynamic>>> _paginateQuotationItems({
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
    bool isFirstPage = true;

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
          double newPageCap = usableHeight - tableHeaderHeight;
          if (requiredHeight + totalsHeight + signatureHeight > newPageCap) {
            pages.add(currentPageItems);
            pages.add([]);
          } else {
            pages.add(currentPageItems);
          }
          currentPageItems = [];
        } else {
          if (currentHeight + requiredHeight + totalsHeight + signatureHeight >
              pageCap) {
            currentPageItems.add(item);
            pages.add(currentPageItems);
            currentPageItems = [];
            pages.add([]);
          } else {
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

  // The perfect, system-aligned pixel-perfect screenshot generator
  Future<void> _exportPdfWithScreenshot(bool isPrint) async {
    if (_clientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_req_client_export'.tr)));
      return;
    }

    _calculateTotals();

    // Cache build context states safely
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoader(message: 'generating_pdf'.tr),
    );

    try {
      final Map<String, dynamic> quotationData = {
        'id': _quoteNumberController.text.trim(),
        'date': _quoteDateController.text.trim(),
        'validUntil': _validUntilController.text.trim(),
        'clientName': _clientNameController.text.trim(),
        'email': _clientEmailController.text.trim(),
        'address': _clientAddressController.text.trim(),
        'placeOfSupply': _placeOfSupplyController.text.trim(),
        'subtotal': _subtotal,
        'discountAmount': _discountAmount,
        'taxAmount': _taxAmount,
        'total': _total,
        'gstEnabled': _gstEnabled,
        'taxType': _taxType,
      };

      List<Map<String, dynamic>> itemsList = [];
      for (var item in _itemsControllers) {
        double qty = double.tryParse(item.qtyController.text) ?? 1.0;
        double rate = double.tryParse(item.rateController.text) ?? 0.0;
        double gstRate = double.tryParse(item.gstController.text) ?? 18.0;
        itemsList.add({
          'description': item.nameController.text.trim(),
          'additionalDetails': item.descriptionController.text.trim(),
          'quantity': qty,
          'rate': rate,
          'gst': gstRate,
        });
      }

      // Height specs matched to exact pixel limits
      const double itemHeight = 70.0;
      const double pageHeight = 1123.0;
      const double margin = 40.0;
      const double usableHeight = pageHeight - (margin * 2);
      double headerHeight = 310.0;
      const double tableHeaderHeight = 45.0;
      double totalsHeight = 220.0;
      double signatureHeight = 0.0;

      if (_selectedTemplate == 'vibrant') {
        headerHeight = 360.0;
        totalsHeight = 310.0;
        signatureHeight = 170.0;
      }

      final pages = _paginateQuotationItems(
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
              body: _buildOfflineQuotationA4Page(
                quotationData: quotationData,
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
              delay: const Duration(milliseconds: 150),
              pixelRatio: 4.0, // High quality vector resolution representation
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

      if (mounted) navigator.pop(); // Dismiss loader

      if (isPrint) {
        await Printing.layoutPdf(
          format: PdfPageFormat.a4,
          usePrinterSettings: false,
          onLayout: (PdfPageFormat format) async {
            return pdf.save();
          },
          name: 'Quotation_${quotationData['id']}.pdf',
        );
      } else {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'Quotation_${quotationData['id']}.pdf',
        );
      }
    } catch (e) {
      if (mounted) navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _compileCurrentItems() {
    List<Map<String, dynamic>> list = [];
    for (var item in _itemsControllers) {
      double qty = double.tryParse(item.qtyController.text) ?? 1.0;
      double rate = double.tryParse(item.rateController.text) ?? 0.0;
      double gstRate = double.tryParse(item.gstController.text) ?? 18.0;
      list.add({
        'description': item.nameController.text.trim().isEmpty
            ? 'Item Description'
            : item.nameController.text.trim(),
        'additionalDetails': item.descriptionController.text.trim(),
        'quantity': qty,
        'rate': rate,
        'gst': gstRate,
      });
    }
    return list;
  }

  Widget _buildOfflineQuotationA4Page({
    required Map<String, dynamic> quotationData,
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
    switch (templateId) {
      case 'modern':
        return _buildModernTemplate(
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'modern-blue':
        return _buildModernBlueTemplate(
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'classic':
        return _buildClassicTemplate(
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'minimalist':
        return _buildMinimalistTemplate(
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'elegant':
        return _buildElegantTemplate(
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'vibrant':
        return _buildVibrantTemplate(
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
      case 'standard':
      default:
        return _buildStandardTemplate(
          pageItems: pageItems,
          isFirstPage: isFirstPage,
          isLastPage: isLastPage,
          pageIndex: pageIndex,
          totalPages: totalPages,
          isOffline: isOffline,
        );
    }
  }

  Widget _buildStandardTemplate({
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final paddingValue = isOffline ? 40.0 : 24.0;
    final itemsList = pageItems ?? _compileCurrentItems();
    final clientName = _clientNameController.text.trim().isEmpty
        ? 'Client Name'
        : _clientNameController.text.trim();
    final quoteNumber = _quoteNumberController.text.trim().isEmpty
        ? 'QT-TEMP'
        : _quoteNumberController.text.trim();
    final quoteDate = _quoteDateController.text.trim().isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : _quoteDateController.text.trim();
    final validUntil = _validUntilController.text.trim().isEmpty
        ? DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 30)))
        : _validUntilController.text.trim();
    final placeOfSupply = _placeOfSupplyController.text.trim().isEmpty
        ? 'Telangana'
        : _placeOfSupplyController.text.trim();

    final clientEmail = _clientEmailController.text.trim().isEmpty
        ? '${clientName.toLowerCase().replaceAll(' ', '')}@acme.com'
        : _clientEmailController.text.trim();
    final clientAddress = _clientAddressController.text.trim().isEmpty
        ? 'Corporate Hub, Sector V, Hitech Avenue, Suite 101'
        : _clientAddressController.text.trim();
    final discountPercentage =
        double.tryParse(_discountPercentageController.text) ?? 0.0;

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
                Center(
                  child: Text(
                    _companyInfo['name']!.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.serifFontFamily,
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
                    _companyInfo['address']!.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                    '${_companyInfo['email']!.toUpperCase()}  •  ${_companyInfo['phone']!.toUpperCase()}'
                    '${_companyInfo['website'] != null && _companyInfo['website']!.isNotEmpty ? '  •  ${_companyInfo['website']!.toUpperCase()}' : ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (_gstEnabled &&
                    _companyInfo['gstNumber'] != null &&
                    _companyInfo['gstNumber']!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      'GSTIN: ${_companyInfo['gstNumber']!.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(height: 1.5, color: Colors.black87),
                const SizedBox(height: 16),
              ],
            ),

            // Document Title & Meta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'QUOTATION',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
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
                      '#$quoteNumber',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text(
                            'Date:',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                        Text(
                          quoteDate,
                          style: TextStyle(
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
                        const SizedBox(
                          width: 80,
                          child: Text(
                            'Valid Until:',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                        Text(
                          validUntil,
                          style: TextStyle(
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
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black12, width: 1),
                          ),
                        ),
                        padding: const EdgeInsets.only(bottom: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'TO',
                          style: TextStyle(
                            fontFamily: AppTypography.serifFontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Text(
                        clientName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.serifFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clientAddress,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        clientEmail,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                // Bank Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black12, width: 1),
                          ),
                        ),
                        padding: const EdgeInsets.only(bottom: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'PAY TO',
                          style: TextStyle(
                            fontFamily: AppTypography.serifFontFamily,
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
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: 'name_colon'.tr),
                            TextSpan(
                              text: '${_mockBankDetails['accountName']}\n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(text: 'bank_colon'.tr),
                            TextSpan(
                              text: '${_mockBankDetails['bankName']}\n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(text: 'ac_colon'.tr),
                            TextSpan(
                              text: '${_mockBankDetails['accountNumber']}\n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(text: 'ifsc_colon'.tr),
                            TextSpan(
                              text: '${_mockBankDetails['ifscCode']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quotation Ref: #$quoteNumber',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    fontFamily: AppTypography.serifFontFamily,
                  ),
                ),
                Text(
                  "${'date_colon'.tr}$quoteDate",
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
          ],

          // Elegant double-line table header
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black87, width: 1.5),
                bottom: BorderSide(color: Colors.black87, width: 1.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    'NO.',
                    style: TextStyle(
                      fontFamily: AppTypography.serifFontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontFamily: AppTypography.serifFontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'QTY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.serifFontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'PRICE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppTypography.serifFontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'amount_caps'.tr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppTypography.serifFontFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
            final itemNo = (pageIndex * 10 + index + 1).toString().padLeft(
              2,
              '0',
            );

            return Container(
              decoration: BoxDecoration(
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
                      style: TextStyle(
                        fontFamily: AppTypography.serifFontFamily,
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
                          style: TextStyle(
                            fontFamily: AppTypography.serifFontFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      qty % 1 == 0
                          ? qty.toStringAsFixed(0)
                          : qty.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      formatCurrency.format(rate),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      formatCurrency.format(amount),
                      textAlign: TextAlign.right,
                      style: TextStyle(
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
          Container(height: 1.5, color: Colors.black87),

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
                      Text(
                        'amount_in_words'.tr,
                        style: TextStyle(
                          fontFamily: AppTypography.serifFontFamily,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _convertNumberToWords(_total).toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.serifFontFamily,
                          fontSize: 10,
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
                          Text(
                            'subtotal'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            formatCurrency.format(_subtotal),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${'discount_percent'.tr.split('(')[0]} (${discountPercentage.toStringAsFixed(0)}%)",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '- ${formatCurrency.format(_discountAmount)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_gstEnabled && _taxAmount > 0) ...[
                        const SizedBox(height: 4),
                        if (placeOfSupply.toLowerCase().contains('telangana') ||
                            placeOfSupply.contains('36')) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'cgst_9'.tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                formatCurrency.format(_taxAmount / 2),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'sgst_9'.tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                formatCurrency.format(_taxAmount / 2),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'igst_18'.tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                formatCurrency.format(_taxAmount),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      Divider(height: 12, color: Colors.black12),
                      Container(
                        color: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL',
                              style: TextStyle(
                                fontFamily: AppTypography.serifFontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              formatCurrency.format(_total),
                              style: TextStyle(
                                fontFamily: AppTypography.serifFontFamily,
                                fontSize: 11,
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
            ),
            const SizedBox(height: 24),
            _buildFooterSection(),
          ],

          if (isOffline) ...[
            const Spacer(),
            _buildBottomFooter(pageIndex + 1, totalPages),
          ] else ...[
            const SizedBox(height: 30),
            _buildBottomFooter(1, 1),
          ],
        ],
      ),
    );
  }

  Widget _buildModernTemplate({
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final paddingValue = isOffline ? 40.0 : 24.0;
    final itemsList = pageItems ?? _compileCurrentItems();
    final clientName = _clientNameController.text.trim().isEmpty
        ? 'Client Name'
        : _clientNameController.text.trim();
    final quoteNumber = _quoteNumberController.text.trim().isEmpty
        ? 'QT-TEMP'
        : _quoteNumberController.text.trim();
    final quoteDate = _quoteDateController.text.trim().isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : _quoteDateController.text.trim();
    final validUntil = _validUntilController.text.trim().isEmpty
        ? DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 30)))
        : _validUntilController.text.trim();
    final placeOfSupply = _placeOfSupplyController.text.trim().isEmpty
        ? 'Telangana'
        : _placeOfSupplyController.text.trim();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstPage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _companyInfo['name']!.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_companyInfo['email']!} | ${_companyInfo['phone']!}',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      'GSTIN: ${_companyInfo['gstNumber']!}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ESTIMATE PROPOSAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#$quoteNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'proposal_for'.tr,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          clientName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          quoteDate,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'valid_until_caps'.tr,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          validUntil,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          "${'place_of_supply'.tr}: $placeOfSupply",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Proposal Ref: $quoteNumber',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                  ),
                ),
                Text(
                  "${'date_colon'.tr}$quoteDate",
                  style: TextStyle(
                    fontSize: 11,
                    color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                  ),
                ),
              ],
            ),
            Divider(thickness: 1.0, color: Colors.black12),
            const SizedBox(height: 20),
          ],

          _buildItemTable(
            headerBgColor: AppColors.primary,
            textStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            items: itemsList,
          ),
          const SizedBox(height: 20),

          if (isLastPage) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'bank_accreditation'.tr,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${'ac_name_colon'.tr}${_mockBankDetails['accountName']}",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${'number_colon'.tr}${_mockBankDetails['accountNumber']}",
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          "${'ifsc_colon'.tr}${_mockBankDetails['ifscCode']}",
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildDynamicScreenSummarySection(
                    primaryColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],

          if (isOffline) ...[
            const Spacer(),
            _buildBottomFooter(pageIndex + 1, totalPages),
          ] else ...[
            const SizedBox(height: 30),
            _buildBottomFooter(1, 1),
          ],
        ],
      ),
    );
  }

  Widget _buildModernBlueTemplate({
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final itemsList = pageItems ?? _compileCurrentItems();
    final clientName = _clientNameController.text.trim().isEmpty
        ? 'Client Name'
        : _clientNameController.text.trim();
    final quoteNumber = _quoteNumberController.text.trim().isEmpty
        ? 'QT-TEMP'
        : _quoteNumberController.text.trim();
    final quoteDate = _quoteDateController.text.trim().isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : _quoteDateController.text.trim();
    final validUntil = _validUntilController.text.trim().isEmpty
        ? DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 30)))
        : _validUntilController.text.trim();
    final placeOfSupply = _placeOfSupplyController.text.trim().isEmpty
        ? 'Telangana'
        : _placeOfSupplyController.text.trim();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstPage) ...[
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _companyInfo['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 260,
                        child: Text(
                          _companyInfo['address']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GSTIN: ${_companyInfo['gstNumber']!}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'proposal'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '#$quoteNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${'date_colon'.tr}$quoteDate",
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      Text(
                        "${'valid_until_colon'.tr}$validUntil",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Proposal: $quoteNumber',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "${'date_colon'.tr}$quoteDate",
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirstPage) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'client_details_caps'.tr,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clientName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _clientAddressController.text.trim().isEmpty
                                ? 'Corporate Hub, Sector V, Hitech Avenue, Suite 101'
                                : _clientAddressController.text.trim(),
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'logistics_supply'.tr,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            placeOfSupply,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'fob_delivery'.tr,
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                _buildItemTable(
                  headerBgColor: Color(0xFF1E40AF),
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  items: itemsList,
                ),
                const SizedBox(height: 20),

                if (isLastPage) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'remittance_gateway'.tr,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _mockBankDetails['bankName']!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${'number_colon'.tr}${_mockBankDetails['accountNumber']}",
                              style: TextStyle(fontSize: 10),
                            ),
                            Text(
                              "${'ifsc_colon'.tr}${_mockBankDetails['ifscCode']}",
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xFFDBEAFE)),
                          ),
                          child: _buildDynamicScreenSummarySection(
                            primaryColor: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                _buildFooterSection(),
                const SizedBox(height: 10),
              ],
            ),
          ),

          if (isOffline) ...[
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: _buildBottomFooter(pageIndex + 1, totalPages),
            ),
          ] else ...[
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: _buildBottomFooter(1, 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassicTemplate({
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final paddingValue = isOffline ? 40.0 : 24.0;
    final itemsList = pageItems ?? _compileCurrentItems();
    final clientName = _clientNameController.text.trim().isEmpty
        ? 'Client Name'
        : _clientNameController.text.trim();
    final quoteNumber = _quoteNumberController.text.trim().isEmpty
        ? 'QT-TEMP'
        : _quoteNumberController.text.trim();
    final quoteDate = _quoteDateController.text.trim().isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : _quoteDateController.text.trim();
    final validUntil = _validUntilController.text.trim().isEmpty
        ? DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 30)))
        : _validUntilController.text.trim();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstPage) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    _companyInfo['name']!.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontFamily: AppTypography.serifFontFamily,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _companyInfo['address']!,
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: AppTypography.serifFontFamily,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'GSTIN: ${_companyInfo['gstNumber']!}',
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: AppTypography.serifFontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(thickness: 2, color: Colors.amber),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'to_client'.tr,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clientName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: AppTypography.serifFontFamily,
                      ),
                    ),
                    Text(
                      _clientAddressController.text.trim().isEmpty
                          ? 'Corporate Hub, Sector V, Hitech Avenue, Suite 101'
                          : _clientAddressController.text.trim(),
                      style: TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ESTIMATE #$quoteNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: AppTypography.serifFontFamily,
                      ),
                    ),
                    Text(
                      "${'date_colon'.tr}$quoteDate",
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: AppTypography.serifFontFamily,
                      ),
                    ),
                    Text(
                      "${'valid_until_colon'.tr}$validUntil",
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: AppTypography.serifFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Proposal Ref: $quoteNumber',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTypography.serifFontFamily,
                    color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                  ),
                ),
                Text(
                  "${'date_colon'.tr}$quoteDate",
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppTypography.serifFontFamily,
                    color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                  ),
                ),
              ],
            ),
            Divider(thickness: 1.5, color: Colors.amber),
            const SizedBox(height: 20),
          ],

          _buildItemTable(
            headerBgColor: Colors.black87,
            textStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: AppTypography.serifFontFamily,
            ),
            items: itemsList,
            isSerif: true,
          ),
          const SizedBox(height: 20),

          if (isLastPage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'terms_conditions_caps'.tr,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _companyInfo['defaultTerms']!,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.black54,
                          height: 1.4,
                          fontFamily: AppTypography.serifFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                SizedBox(
                  width: 180,
                  child: _buildDynamicScreenSummarySection(
                    primaryColor: Colors.black,
                    useSerif: true,
                  ),
                ),
              ],
            ),
          ],

          if (isOffline) ...[
            const Spacer(),
            _buildBottomFooter(pageIndex + 1, totalPages),
          ] else ...[
            const SizedBox(height: 30),
            _buildBottomFooter(1, 1),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalistTemplate({
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final paddingValue = isOffline ? 40.0 : 28.0;
    final itemsList = pageItems ?? _compileCurrentItems();
    final clientName = _clientNameController.text.trim().isEmpty
        ? 'Client Name'
        : _clientNameController.text.trim();
    final quoteNumber = _quoteNumberController.text.trim().isEmpty
        ? 'QT-TEMP'
        : _quoteNumberController.text.trim();
    final quoteDate = _quoteDateController.text.trim().isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : _quoteDateController.text.trim();
    final validUntil = _validUntilController.text.trim().isEmpty
        ? DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 30)))
        : _validUntilController.text.trim();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstPage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _companyInfo['name']!.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'proposal'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 20,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _companyInfo['address']!,
              style: TextStyle(fontSize: 9, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'client'.tr,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clientName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${'quote_no_colon'.tr}$quoteNumber",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      "${'issued_colon'.tr}$quoteDate",
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      "${'valid_until_colon'.tr}$validUntil",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${'quote_no_colon'.tr}$quoteNumber",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${'issued_colon'.tr}$quoteDate",
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            Divider(thickness: 1.0, color: Colors.black26),
            const SizedBox(height: 20),
          ],

          _buildItemTable(
            headerBgColor: Colors.transparent,
            textStyle: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            items: itemsList,
          ),
          Divider(thickness: 1, color: Colors.black12),
          const SizedBox(height: 16),

          if (isLastPage) ...[
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 200,
                child: _buildDynamicScreenSummarySection(
                  primaryColor: Colors.black,
                  isMinimalist: true,
                ),
              ),
            ),
          ],

          if (isOffline) ...[
            const Spacer(),
            _buildBottomFooter(pageIndex + 1, totalPages),
          ] else ...[
            const SizedBox(height: 32),
            _buildBottomFooter(1, 1),
          ],
        ],
      ),
    );
  }

  Widget _buildElegantTemplate({
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final paddingValue = isOffline ? 40.0 : 24.0;
    final itemsList = pageItems ?? _compileCurrentItems();
    final clientName = _clientNameController.text.trim().isEmpty
        ? 'Client Name'
        : _clientNameController.text.trim();
    final quoteNumber = _quoteNumberController.text.trim().isEmpty
        ? 'QT-TEMP'
        : _quoteNumberController.text.trim();
    final quoteDate = _quoteDateController.text.trim().isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : _quoteDateController.text.trim();
    final validUntil = _validUntilController.text.trim().isEmpty
        ? DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 30)))
        : _validUntilController.text.trim();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(paddingValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstPage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _companyInfo['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepPurple,
                        fontFamily: AppTypography.serifFontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _companyInfo['address']!,
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'elegant_proposal'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 2,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 2,
              width: double.infinity,
              color: Colors.deepPurple[100],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'prepared_for'.tr,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clientName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: AppTypography.serifFontFamily,
                        ),
                      ),
                      Text(
                        _clientAddressController.text.trim().isEmpty
                            ? 'Cyber Tower Complex, Hyd'
                            : _clientAddressController.text.trim(),
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${'proposal_ref_colon'.tr}#$quoteNumber",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        "${'created_on_colon'.tr}$quoteDate",
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        "${'valid_until_colon'.tr}$validUntil",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${'proposal_ref_colon'.tr}#$quoteNumber",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  "${'date_colon'.tr}$quoteDate",
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 1.5,
              width: double.infinity,
              color: Colors.deepPurple[100],
            ),
            const SizedBox(height: 20),
          ],

          _buildItemTable(
            headerBgColor: Colors.deepPurple[50]!,
            textStyle: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
              fontFamily: AppTypography.serifFontFamily,
            ),
            items: itemsList,
            isSerif: true,
          ),
          const SizedBox(height: 20),

          if (isLastPage) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'payment_protocol'.tr,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${'beneficiary_colon'.tr}${_mockBankDetails['accountName']}",
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        "${'bank_name_colon'.tr}${_mockBankDetails['bankName']}",
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        "${'number_colon'.tr}${_mockBankDetails['accountNumber']}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${'ifsc_colon'.tr}${_mockBankDetails['ifscCode']}",
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepPurple[100]!),
                    ),
                    child: _buildDynamicScreenSummarySection(
                      primaryColor: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (isOffline) ...[
            const Spacer(),
            _buildBottomFooter(pageIndex + 1, totalPages),
          ] else ...[
            const SizedBox(height: 30),
            _buildBottomFooter(1, 1),
          ],
        ],
      ),
    );
  }

  Widget _buildVibrantTemplate({
    List<Map<String, dynamic>>? pageItems,
    bool isFirstPage = true,
    bool isLastPage = true,
    int pageIndex = 0,
    int totalPages = 1,
    bool isOffline = false,
  }) {
    final itemsList = pageItems ?? _compileCurrentItems();
    final clientName = _clientNameController.text.trim().isEmpty
        ? 'Client Name'
        : _clientNameController.text.trim();
    final quoteNumber = _quoteNumberController.text.trim().isEmpty
        ? 'QT-TEMP'
        : _quoteNumberController.text.trim();
    final quoteDate = _quoteDateController.text.trim().isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : _quoteDateController.text.trim();
    final validUntil = _validUntilController.text.trim().isEmpty
        ? DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 30)))
        : _validUntilController.text.trim();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          if (isFirstPage) ...[
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.sparkles,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _companyInfo['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 250,
                        child: Text(
                          _companyInfo['address']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'proposal'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: Color(0xFF7C3AED),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '#$quoteNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${'date_colon'.tr}$quoteDate",
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      Text(
                        "${'valid_until_colon'.tr}$validUntil",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Proposal: #$quoteNumber',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "${'date_colon'.tr}$quoteDate",
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirstPage) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFFF3E8FF),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'billed_client'.tr,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                clientName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _clientEmailController.text.trim().isEmpty
                                    ? '${clientName.toLowerCase().replaceAll(' ', '')}@acme.com'
                                    : _clientEmailController.text.trim(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _clientAddressController.text.trim().isEmpty
                                    ? 'Corporate Hub, Sector V, Hitech Avenue, Suite 101'
                                    : _clientAddressController.text.trim(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFFFDF2F8),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'revenue_channel'.tr,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD946EF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _mockBankDetails['bankName']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "${'ac_colon'.tr}${_mockBankDetails['accountNumber']}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                _buildItemTable(
                  headerBgColor: Color(0xFF7C3AED),
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  items: itemsList,
                ),
                const SizedBox(height: 20),

                if (isLastPage) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'amount_in_words'.tr,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _convertNumberToWords(_total),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildDynamicScreenSummarySection(
                            primaryColor: Colors.white,
                            isVibrant: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                _buildFooterSection(),
              ],
            ),
          ),

          if (isOffline) ...[
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildBottomFooter(pageIndex + 1, totalPages),
            ),
          ] else ...[
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildBottomFooter(1, 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicScreenSummarySection({
    Color? primaryColor,
    bool useSerif = false,
    bool isVibrant = false,
    bool isMinimalist = false,
  }) {
    String place = _placeOfSupplyController.text.trim().toLowerCase();
    bool isOutstate =
        place.isNotEmpty &&
        !place.contains("telangana") &&
        !place.contains("36");
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
                  fontWeight: isGrandTotal
                      ? FontWeight.bold
                      : FontWeight.normal,
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
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildRow('subtotal'.tr, formatCurrency.format(_subtotal)),
        if (_discountAmount > 0)
          buildRow(
            '${'discount'.tr} (${double.tryParse(_discountPercentageController.text) != null ? double.tryParse(_discountPercentageController.text)!.toStringAsFixed(0) : "0"}%)',
            '- ${formatCurrency.format(_discountAmount)}',
          ),
        if (_gstEnabled && _taxAmount > 0) ...[
          if (isOutstate)
            buildRow('IGST (18%)', formatCurrency.format(_taxAmount))
          else ...[
            buildRow('CGST (9%)', formatCurrency.format(_taxAmount / 2)),
            buildRow('SGST (9%)', formatCurrency.format(_taxAmount / 2)),
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
          useSerif ? 'GRAND TOTAL' : 'grand_total'.tr,
          formatCurrency.format(_total),
          isGrandTotal: true,
        ),
      ],
    );
  }

  Widget _buildItemTable({
    required Color headerBgColor,
    required TextStyle textStyle,
    List<Map<String, dynamic>>? items,
    bool isSerif = false,
  }) {
    final list = items ?? _compileCurrentItems();
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
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerBgColor),
              children: [
                _buildTableCell(
                  'Description',
                  textStyle,
                  isHeader: true,
                  useSerif: isSerif,
                ),
                _buildTableCell(
                  'qty'.tr,
                  textStyle,
                  isHeader: true,
                  align: TextAlign.center,
                  useSerif: isSerif,
                ),
                _buildTableCell(
                  'rate'.tr,
                  textStyle,
                  isHeader: true,
                  align: TextAlign.right,
                  useSerif: isSerif,
                ),
                _buildTableCell(
                  'amount'.tr,
                  textStyle,
                  isHeader: true,
                  align: TextAlign.right,
                  useSerif: isSerif,
                ),
              ],
            ),
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
                  _buildTableCell(
                    qty % 1 == 0
                        ? qty.toStringAsFixed(0)
                        : qty.toStringAsFixed(2),
                    TextStyle(
                      fontSize: 10,
                      fontFamily: isSerif ? 'serif' : null,
                    ),
                    align: TextAlign.center,
                  ),
                  _buildTableCell(
                    formatCurrency.format(rate),
                    TextStyle(
                      fontSize: 10,
                      fontFamily: isSerif ? 'serif' : null,
                    ),
                    align: TextAlign.right,
                  ),
                  _buildTableCell(
                    formatCurrency.format(amount),
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

  Widget _buildTableCell(
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

  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        const SizedBox(height: 6),
        Text(
          'terms_conditions_caps'.tr,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _companyInfo['defaultTerms']!,
          style: TextStyle(fontSize: 8, color: Colors.grey, height: 1.3),
        ),
      ],
    );
  }

  Widget _buildBottomFooter(int currentPage, int totalPages) {
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

  String _convertNumberToWords(double amount) {
    if (amount == 0) return 'Zero Rupees only';

    final int value = amount.round();
    final List<String> units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final List<String> tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String convertLessThanThousand(int num) {
      if (num == 0) return '';
      if (num < 20) return units[num];
      if (num < 100) {
        return tens[num ~/ 10] + (num % 10 != 0 ? ' ${units[num % 10]}' : '');
      }
      return '${units[num ~/ 100]} Hundred${num % 100 != 0 ? ' and ${convertLessThanThousand(num % 100)}' : ''}';
    }

    int temp = value;
    String words = '';

    if (temp >= 10000000) {
      words += '${convertLessThanThousand(temp ~/ 10000000)} Crore ';
      temp %= 10000000;
    }
    if (temp >= 100000) {
      words += '${convertLessThanThousand(temp ~/ 100000)} Lakh ';
      temp %= 100000;
    }
    if (temp >= 1000) {
      words += '${convertLessThanThousand(temp ~/ 1000)} Thousand ';
      temp %= 1000;
    }
    if (temp > 0) {
      words += convertLessThanThousand(temp);
    }

    return 'Rupees ${words.trim()} only';
  }

  double get _formCompleteness {
    double score = 0.0;
    if (_clientNameController.text.trim().isNotEmpty) score += 0.25;
    if (_quoteNumberController.text.trim().isNotEmpty) score += 0.25;

    bool hasValidItem =
        _itemsControllers.isNotEmpty &&
        _itemsControllers.any(
          (item) =>
              item.nameController.text.trim().isNotEmpty &&
              (double.tryParse(item.rateController.text) ?? 0) > 0,
        );
    if (hasValidItem) score += 0.25;

    if (_total > 0) score += 0.25;
    return score;
  }

  Widget _buildCompletenessHeader() {
    final progress = _formCompleteness;
    final percentage = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    percentage == 100
                        ? LucideIcons.sparkles
                        : LucideIcons.fileEdit,
                    size: 16,
                    color: percentage == 100 ? Colors.amber : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Proposal Completeness',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: percentage == 100
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: Theme.of(context).scaffoldBackgroundColor),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: 6,
                  width: MediaQuery.of(context).size.width * 0.9 * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: percentage == 100
                          ? [AppColors.success, Color(0xFF047857)]
                          : [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.6),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndShowDetails() async {
    if (_clientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_req_client'.tr)));
      return;
    }

    if (_quoteNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error_req_quote_no'.tr)));
      return;
    }

    for (int i = 0; i < _itemsControllers.length; i++) {
      if (_itemsControllers[i].nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_req_item_name'.tr}${i + 1}')),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoader(
        message: widget.quotationToEdit != null
            ? 'Updating Proposal/Quotation...'
            : 'Creating Proposal/Quotation...',
      ),
    );

    // Compile items to pass to details
    List<Map<String, dynamic>> itemsList = [];
    for (var item in _itemsControllers) {
      double qty = double.tryParse(item.qtyController.text) ?? 1.0;
      double rate = double.tryParse(item.rateController.text) ?? 0.0;
      double gstRate = double.tryParse(item.gstController.text) ?? 18.0;
      itemsList.add({
        'description': item.nameController.text.trim(),
        'additionalDetails': item.descriptionController.text.trim(),
        'quantity': qty,
        'rate': rate,
        'gst': gstRate,
      });
    }

    final payload = {
      'client': {
        'name': _clientNameController.text.trim(),
        'email': _clientEmailController.text.trim(),
        'phone': _clientPhoneController.text.trim(),
        'address': _clientAddressController.text.trim(),
        'gstNumber': _clientGstController.text.trim(),
      },
      'items': itemsList,
      'discountPercentage':
          double.tryParse(_discountPercentageController.text) ?? 0.0,
      'advancePayment': double.tryParse(_advanceReceivedController.text) ?? 0.0,
      'taxRate': 18.0,
      'gstEnabled': _gstEnabled,
      'taxType': _taxType,
      'date': _quoteDateController.text.trim(),
      'validUntil': _validUntilController.text.trim(),
      'placeOfSupply': _placeOfSupplyController.text.trim(),
      'notes': 'Thank you for your business!',
      'terms': _termsController.text.trim(),
    };

    try {
      final http.Response response;
      if (widget.quotationToEdit != null) {
        final id =
            widget.quotationToEdit!['_id'] ?? widget.quotationToEdit!['id'];
        response = await ApiService.put(
          '${ApiConstants.quotations}/$id',
          payload,
        );
      } else {
        response = await ApiService.post(ApiConstants.quotations, payload);
      }
      Navigator.pop(context); // Dismiss loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: widget.quotationToEdit != null
              ? "Quotation updated successfully!"
              : "Quotation created successfully!",
          backgroundColor: AppColors.success,
          textColor: Colors.white,
        );

        final ClientsController clientsController =
            Get.isRegistered<ClientsController>()
            ? Get.find<ClientsController>()
            : Get.put(ClientsController());
        await clientsController.fetchQuotations();

        final responseData = jsonDecode(response.body);
        final qt = responseData['data'] ?? {};
        final clientObj = qt['client'] ?? {};
        final String name = clientObj['name'] ?? 'Unknown';
        final String email = clientObj['email'] ?? '';
        final String phone =
            clientObj['phone'] ?? clientObj['phoneNumber'] ?? '';
        final String address = clientObj['address'] ?? '';
        final String gst = clientObj['gstin'] ?? clientObj['gstNumber'] ?? '';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuotationDetailsScreen(
              quotationId:
                  qt['quotationNumber'] ??
                  qt['quoteNumber'] ??
                  qt['id'] ??
                  _quoteNumberController.text.trim(),
              dbId: qt['_id'] ?? qt['id'] ?? '',
              clientName: name,
              amount: (qt['totalAmount'] ?? qt['grandTotal'] ?? _total)
                  .toDouble(),
              date:
                  qt['date'] ??
                  qt['createdAt'] ??
                  _quoteDateController.text.trim(),
              status: qt['status'] ?? 'Pending',
              items: List<Map<String, dynamic>>.from(
                (qt['items'] ?? []).map((x) => Map<String, dynamic>.from(x)),
              ),
              validUntil: qt['validUntil'] ?? _validUntilController.text.trim(),
              placeOfSupply:
                  qt['placeOfSupply'] ?? _placeOfSupplyController.text.trim(),
              discountPercentage: (qt['discountPercentage'] ?? 0.0).toDouble(),
              gstEnabled: qt['gstEnabled'] ?? false,
              taxType: qt['taxType'] ?? 'exclusive',
              clientEmail: email,
              clientPhone: phone,
              clientAddress: address,
              advancePayment:
                  double.tryParse(_advanceReceivedController.text) ?? 0.0,
            ),
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        final errMsg = responseData['message'] ?? 'Failed to save quotation';
        Fluttertoast.showToast(
          msg: errMsg,
          backgroundColor: AppColors.error,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading dialog
      Fluttertoast.showToast(
        msg: "Error connecting to server: $e",
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.quotationToEdit != null
                  ? 'edit_quotation'.tr
                  : 'new_quotation'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
              ),
            ),
            Text(
              widget.quotationToEdit != null
                  ? 'edit_estimate_proposal'.tr
                  : 'create_new_estimate_proposal'.tr,
              style: TextStyle(
                fontSize: 11,
                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          const SizedBox(width: 6),
          ScaleOnPress(
            onTap: _saveAndShowDetails,
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10, right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Icon(LucideIcons.save, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'save'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 800;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: FadeInUp(
                          delay: const Duration(milliseconds: 50),
                          child: _buildClientSection(isWide),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildQuotationMetaSection(isWide),
                        ),
                      ),
                    ],
                  )
                else ...[
                  FadeInUp(
                    delay: const Duration(milliseconds: 50),
                    child: _buildClientSection(isWide),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: _buildQuotationMetaSection(isWide),
                  ),
                ],
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: _buildItemsSection(isWide),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildSummaryAndTermsSection(isWide),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    IconData? icon,
    Color? iconColor,
    Widget? headerTrailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    letterSpacing: 1.0,
                  ),
                ),
                if (headerTrailing != null) ...[const Spacer(), headerTrailing],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }

  Widget _buildClientSection(bool isWide) {
    return _buildCard(
      title: 'quote_to'.tr,
      icon: LucideIcons.user,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField(
            controller: _clientSearchController,
            label: 'search_existing_client'.tr,
            hint: 'type_to_search_clients'.tr,
            icon: LucideIcons.search,
            suffixIcon: _clientSearchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      _clientSearchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
          ),
          if (_showSuggestions && _filteredClients.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filteredClients.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Theme.of(context).colorScheme.outline),
                itemBuilder: (context, index) {
                  final client = _filteredClients[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      client.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                      ),
                    ),
                    subtitle: Text(
                      client.email.isNotEmpty
                          ? client.email
                          : 'No email address',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: Icon(
                      LucideIcons.arrowUpLeft,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      setState(() {
                        _clientSearchController.clear();
                        _clientNameController.text = client.name;
                        _clientEmailController.text = client.email;
                        _clientAddressController.text = client.address;
                        _clientPhoneController.text = client.phone;
                        _clientGstController.text = client.gstin;
                        _selectedClientId = client.id;
                        _showSuggestions = false;
                      });
                      _calculateTotals();
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _clientNameController,
                  label: 'client_name_star'.tr,
                  hint: 'eg_name'.tr,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _clientEmailController,
                  label: 'email'.tr,
                  hint: 'eg_email'.tr,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _clientAddressController,
            label: 'address'.tr,
            hint: 'eg_address'.tr,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _clientPhoneController,
            label: 'details'.tr,
            hint: 'eg_phone'.tr,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            controller: _clientGstController,
            label: 'gstin'.tr,
            hint: 'gstin'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationMetaSection(bool isWide) {
    return _buildCard(
      title: 'quote_details'.tr,
      icon: LucideIcons.fileText,
      iconColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _quoteDateController,
                  label: 'quotation_date_star'.tr,
                  hint: 'yyyy_mm_dd'.tr,
                  icon: LucideIcons.calendar,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      _quoteDateController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  controller: _validUntilController,
                  label: 'valid_until_star'.tr,
                  hint: 'yyyy_mm_dd'.tr,
                  icon: LucideIcons.calendarClock,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      _validUntilController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(picked);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.creditCard,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'enable_gst'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: _gstEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                        trackOutlineColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _gstEnabled = val;
                          });
                          _calculateTotals();
                        },
                      ),
                    ),
                  ],
                ),
                if (_gstEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _taxType = 'exclusive');
                            _calculateTotals();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _taxType == 'exclusive'
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _taxType == 'exclusive'
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'EXCLUSIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _taxType == 'exclusive'
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _taxType = 'inclusive');
                            _calculateTotals();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _taxType == 'inclusive'
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _taxType == 'inclusive'
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'INCLUSIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _taxType == 'inclusive'
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(bool isWide) {
    return _buildCard(
      title: 'line_items'.tr,
      icon: LucideIcons.list,
      iconColor: Colors.teal,
      headerTrailing: Text(
        '${_itemsControllers.length} Items Added',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemsControllers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = _itemsControllers[index];
              final double qty =
                  double.tryParse(item.qtyController.text) ?? 1.0;
              final double rate =
                  double.tryParse(item.rateController.text) ?? 0.0;
              final double lineAmount = qty * rate;

              return AnimatedItemCard(
                key: ValueKey(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemNameAutocomplete(index, item),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: item.descriptionController,
                      label: 'detailed_description_optional'.tr,
                      hint: 'add_extra_details'.tr,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildInputField(
                            label: 'qty_star'.tr,
                            hint: '1',
                            keyboardType: TextInputType.number,
                            controller: item.qtyController,
                            onChanged: (val) => _calculateTotals(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildInputField(
                            label: 'rate_star'.tr,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            controller: item.rateController,
                            readOnly: false,
                            onChanged: (val) => _calculateTotals(),
                            onTap: () {
                              if (item.rateController.text == '0') {
                                item.rateController.text = '';
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_gstEnabled) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'gst_rate_percent'.tr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value:
                                          [
                                            '0',
                                            '5',
                                            '12',
                                            '18',
                                            '28',
                                          ].contains(item.gstController.text)
                                          ? item.gstController.text
                                          : '18',
                                      items: [
                                        DropdownMenuItem(
                                          value: '0',
                                          child: Text(
                                            '0_exempt'.tr,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '5',
                                          child: Text(
                                            '5%',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '12',
                                          child: Text(
                                            '12%',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '18',
                                          child: Text(
                                            '18%',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '28',
                                          child: Text(
                                            '28%',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            item.gstController.text = val;
                                          });
                                          _calculateTotals();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'tax_amount_caps'.tr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 42,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      double q =
                                          double.tryParse(
                                            item.qtyController.text,
                                          ) ??
                                          0;
                                      double r =
                                          double.tryParse(
                                            item.rateController.text,
                                          ) ??
                                          0;
                                      double g =
                                          double.tryParse(
                                            item.gstController.text,
                                          ) ??
                                          18;
                                      double amt = q * r;
                                      double taxAmt = 0.0;
                                      if (_taxType == 'exclusive') {
                                        taxAmt = amt * (g / 100);
                                      } else {
                                        taxAmt = amt - (amt / (1 + (g / 100)));
                                      }
                                      return Text(
                                        formatCurrency.format(taxAmt),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.blue,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_gstEnabled) ...[
                          Expanded(
                            flex: 1,
                            child: _buildInputField(
                              label: 'hsn_sac_code'.tr,
                              hint: 'code'.tr,
                              controller: item.hsnController,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'amount_caps'.tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  formatCurrency.format(lineAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _addItem,
                label: Text(
                  'add_new_item_line'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              if (_itemsControllers.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      final removed = _itemsControllers.removeLast();
                      removed.dispose();
                    });
                    _calculateTotals();
                  },
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: AppColors.error,
                  ),
                  label: Text(
                    'remove_item'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndTermsSection(bool isWide) {
    String place = _placeOfSupplyController.text.trim().toLowerCase();
    bool isOutstate =
        place.isNotEmpty &&
        !place.contains("maharashtra") &&
        place != 'select state';

    Widget termsCard = _buildCard(
      title: 'terms_notes'.tr,
      icon: LucideIcons.fileSignature,
      iconColor: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'terms_notes'.tr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _termsController,
            maxLines: 4,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
            ),
            decoration: InputDecoration(
              hintText: 'add_terms_cond'.tr,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget financialCard = _buildCard(
      title: 'financial_summary'.tr,
      icon: LucideIcons.calculator,
      iconColor: Colors.deepPurple,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'subtotal'.tr,
                style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
              ),
              Text(
                formatCurrency.format(_subtotal),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'discount_percent'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    height: 26,
                    child: TextField(
                      controller: _discountPercentageController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      onTap: () {
                        if (_discountPercentageController.text == '0') {
                          _discountPercentageController.clear();
                        }
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _discountPercentageController.text = '0';
                          _discountPercentageController.selection =
                              TextSelection.fromPosition(
                                const TextPosition(offset: 1),
                              );
                        } else if (value.startsWith('0') && value.length > 1) {
                          _discountPercentageController.text = value.substring(
                            1,
                          );
                          _discountPercentageController
                              .selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: _discountPercentageController.text.length,
                            ),
                          );
                        }
                        _calculateTotals();
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '- ${formatCurrency.format(_discountAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(
              80,
              (index) => Expanded(
                child: Container(
                  color: index % 2 == 0
                      ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)
                      : Colors.transparent,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'taxable_amount'.tr,
                style: TextStyle(fontSize: 12, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
              ),
              Text(
                formatCurrency.format(
                  (_taxType == 'inclusive' && _gstEnabled)
                      ? (_subtotal - _discountAmount - _taxAmount)
                      : (_subtotal - _discountAmount),
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                ),
              ),
            ],
          ),
          if (_gstEnabled && _taxAmount > 0) ...[
            const SizedBox(height: 16),
            if (isOutstate)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'igst'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                  ),
                  Text(
                    formatCurrency.format(_taxAmount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'cgst'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                  ),
                  Text(
                    formatCurrency.format(_taxAmount / 2),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'sgst'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                  ),
                  Text(
                    formatCurrency.format(_taxAmount / 2),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'advance_received'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    height: 26,
                    child: TextField(
                      controller: _advanceReceivedController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      onTap: () {
                        if (_advanceReceivedController.text == '0') {
                          _advanceReceivedController.clear();
                        }
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _advanceReceivedController.text = '0';
                          _advanceReceivedController.selection =
                              TextSelection.fromPosition(
                                const TextPosition(offset: 1),
                              );
                        } else if (value.startsWith('0') && value.length > 1) {
                          _advanceReceivedController.text = value.substring(1);
                          _advanceReceivedController
                              .selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: _advanceReceivedController.text.length,
                            ),
                          );
                        }
                        _calculateTotals();
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '- ${formatCurrency.format(double.tryParse(_advanceReceivedController.text) ?? 0.0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), height: 1, thickness: 1),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'balance_due'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black87),
                      ),
                    ),
                    Text(
                      formatCurrency
                          .format(
                            (_total -
                                (double.tryParse(
                                      _advanceReceivedController.text,
                                    ) ??
                                    0.0)),
                          )
                          .replaceAll('₹', ''),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${'amount'.tr}: ${formatCurrency.format(_total)}",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: financialCard),
          const SizedBox(width: 16),
          Expanded(child: termsCard),
        ],
      );
    } else {
      return Column(
        children: [financialCard, const SizedBox(height: 16), termsCard],
      );
    }
  }

  Widget _buildInlineInputField({
    required TextEditingController controller,
    required void Function(String) onChanged,
  }) {
    return Container(
      width: 60,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildItemNameAutocomplete(int index, _ItemControllers item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'item_name_title'.tr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
          ),
        ),
        const SizedBox(height: 6),
        Autocomplete<InventoryItem>(
          initialValue: TextEditingValue(text: item.nameController.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<InventoryItem>.empty();
            }
            return _inventoryController.items.where((InventoryItem option) {
              return option.itemName.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ) ||
                  option.sku.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
            });
          },
          displayStringForOption: (InventoryItem option) => option.itemName,
          onSelected: (InventoryItem selection) {
            setState(() {
              item.nameController.text = selection.itemName;
              item.rateController.text = selection.unitPrice.toStringAsFixed(2);
              if (selection.description.isNotEmpty) {
                item.descriptionController.text = selection.description;
              }
              if (_gstEnabled && selection.sku.isNotEmpty) {
                item.hsnController.text = selection.sku;
              }
            });
            _calculateTotals();
          },
          optionsViewBuilder:
              (
                BuildContext context,
                AutocompleteOnSelected<InventoryItem> onSelected,
                Iterable<InventoryItem> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 320,
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Theme.of(context).colorScheme.outline),
                        itemBuilder: (BuildContext context, int index) {
                          final InventoryItem option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.itemName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        option.sku.isNotEmpty
                                            ? option.sku
                                            : 'No SKU',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '₹${option.unitPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController fieldTextEditingController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                // Sync initial text and keep updated
                if (fieldTextEditingController.text !=
                    item.nameController.text) {
                  fieldTextEditingController.text = item.nameController.text;
                }

                // Listen to input changes
                fieldTextEditingController.removeListener(_onFieldChanged);
                fieldTextEditingController.addListener(() {
                  item.nameController.text = fieldTextEditingController.text;
                  _onFieldChanged();
                });

                return TextField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  onSubmitted: (val) => onFieldSubmitted(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                  ),
                  decoration: InputDecoration(
                    hintText: 'e_g_mobile_app_development'.tr,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.tag,
                      color: Colors.grey,
                      size: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool? readOnly,
    VoidCallback? onTap,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label.replaceAll('*', '').trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
            children: [
              if (label.contains('*'))
                TextSpan(
                  text: ' *',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly ?? (onTap != null),
          onTap: onTap,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: Colors.blue)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRowWidget(
    String label,
    String val, {
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isRed ? AppColors.error : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PREMIUM CUSTOM ANIMATIONS HELPER CLASSES ---

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

class AnimatedItemCard extends StatefulWidget {
  final Widget child;
  const AnimatedItemCard({super.key, required this.child});

  @override
  State<AnimatedItemCard> createState() => _AnimatedItemCardState();
}

class _AnimatedItemCardState extends State<AnimatedItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeInUp({super.key, required this.child, required this.delay});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

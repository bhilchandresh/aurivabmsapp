// ignore_for_file: unused_element, unused_local_variable, use_build_context_synchronously, unused_import
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../clients/clients_controller.dart';
import '../inventory/inventory_controller.dart';
import 'invoice_details_screen.dart';
import '../../shared/widgets/app_loader.dart';
import '../../core/constants/app_typography.dart';
import '../../shared/widgets/custom_notification_overlay.dart';
import '../../core/theme/app_extensions.dart';

class _ItemControllers {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final rateController = TextEditingController(text: '0');
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

class CreateInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? invoiceToEdit;
  const CreateInvoiceScreen({super.key, this.invoiceToEdit});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final ClientsController _clientsController =
      Get.isRegistered<ClientsController>()
      ? Get.find<ClientsController>()
      : Get.put(ClientsController());

  final InventoryController _inventoryController =
      Get.isRegistered<InventoryController>()
      ? Get.find<InventoryController>()
      : Get.put(InventoryController());

  String? _selectedClientId;
  List<Client> _filteredClients = [];
  bool _showSuggestions = false;

  bool _gstEnabled = false;
  String _taxType = 'exclusive';

  // State controllers
  final _clientSearchController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientGstController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _placeOfSupplyController = TextEditingController();
  final _discountPercentageController = TextEditingController(text: '0');
  final _advancePaidController = TextEditingController(text: '0');
  final _termsController = TextEditingController(
    text:
        '1. Goods once sold will not be taken back.\n2. Interest @18% pa will be charged if payment is not made within the due date.',
  );
  String _selectedClientState = '';
  double _balanceDue = 0.0;

  final Map<String, dynamic> _mockTenant = {
    'name': 'Auriva Business Solutions Pvt. Ltd.',
    'address': 'Plot 42, Cyber Gateway, Hitech City, Hyderabad, TS - 500081',
    'email': 'admin@aurivabms.com',
    'phone': '+91 98765 43210',
    'website': 'www.aurivatech.com',
    'gstNumber': '27AAAAA1111A1Z1',
  };

  final Map<String, dynamic> _mockBankDetails = {
    'accountName': 'Auriva Business Solutions Pvt. Ltd.',
    'bankName': 'HDFC Bank Ltd',
    'accountNumber': '50200088899911',
    'ifscCode': 'HDFC0000123',
  };

  final List<_ItemControllers> _itemsControllers = [];

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

  void _onFieldChanged() {
    _calculateTotals();
  }

  String sanitizeStateName(String name) {
    if (name.contains(' (')) {
      return name.split(' (')[0].trim();
    }
    return name.trim();
  }

  @override
  void initState() {
    super.initState();
    _selectedClientState = 'select_state'.tr;
    _inventoryController.fetchItems();
    _clientNameController.addListener(_onFieldChanged);
    _clientSearchController.addListener(_onClientSearchChanged);
    _invoiceNumberController.addListener(_onFieldChanged);
    _discountPercentageController.addListener(_calculateTotals);
    _advancePaidController.addListener(_calculateTotals);

    if (widget.invoiceToEdit != null) {
      final inv = widget.invoiceToEdit!;
      _invoiceNumberController.text = inv['invoiceNumber'] ?? '';

      if (inv['date'] != null && inv['date'].toString().isNotEmpty) {
        try {
          _invoiceDateController.text = inv['date'].toString().split('T')[0];
        } catch (_) {
          _invoiceDateController.text = inv['date'].toString();
        }
      } else {
        _invoiceDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());
      }

      if (inv['dueDate'] != null && inv['dueDate'].toString().isNotEmpty) {
        try {
          _dueDateController.text = inv['dueDate'].toString().split('T')[0];
        } catch (_) {
          _dueDateController.text = inv['dueDate'].toString();
        }
      } else {
        _dueDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().add(const Duration(days: 15)));
      }

      final clientObj = inv['client'] ?? {};
      _clientNameController.text = clientObj['name'] ?? '';
      _clientEmailController.text = clientObj['email'] ?? '';
      _clientAddressController.text = clientObj['address'] ?? '';
      _clientPhoneController.text = clientObj['phone'] ?? '';
      _clientGstController.text =
          clientObj['gstin'] ?? clientObj['gstNumber'] ?? '';
      _selectedClientState = sanitizeStateName(
        clientObj['state'] ?? 'select_state'.tr,
      );
      if (!indianStates.contains(_selectedClientState)) {
        _selectedClientState = 'select_state'.tr;
      }
      String pos = sanitizeStateName(
        inv['placeOfSupply'] ?? clientObj['state'] ?? 'Maharashtra',
      );
      if (pos == 'select_state'.tr || !indianStates.contains(pos)) {
        pos = 'Maharashtra';
      }
      _placeOfSupplyController.text = pos;
      _selectedClientId =
          clientObj['clientId'] ?? clientObj['_id'] ?? clientObj['id'];

      _gstEnabled = inv['gstEnabled'] ?? false;
      _taxType = inv['taxType'] ?? 'exclusive';
      _discountPercentageController.text = (inv['discountPercentage'] ?? 0)
          .toString();
      _advancePaidController.text = (inv['advancePayment'] ?? 0.0).toString();
      _termsController.text =
          inv['terms'] ??
          '1. Goods once sold will not be taken back.\n2. Interest @18% pa will be charged if payment is not made within the due date.';

      final List<dynamic> itemsList = inv['items'] ?? [];
      for (var item in itemsList) {
        final controller = _ItemControllers();
        controller.nameController.text = item['description'] ?? '';
        controller.descriptionController.text = item['additionalDetails'] ?? '';
        controller.qtyController.text = (item['quantity'] ?? 1).toString();
        controller.rateController.text = (item['rate'] ?? 0.0).toString();
        controller.hsnController.text = item['hsnCode'] ?? '';
        controller.gstController.text = (item['gstRate'] ?? 18).toString();

        controller.nameController.addListener(_onFieldChanged);
        controller.rateController.addListener(_onFieldChanged);
        controller.qtyController.addListener(_onFieldChanged);
        controller.gstController.addListener(_onFieldChanged);
        _itemsControllers.add(controller);
      }
      if (_itemsControllers.isEmpty) {
        _itemsControllers.add(_ItemControllers());
        _itemsControllers[0].nameController.addListener(_onFieldChanged);
        _itemsControllers[0].rateController.addListener(_onFieldChanged);
        _itemsControllers[0].qtyController.addListener(_onFieldChanged);
        _itemsControllers[0].gstController.addListener(_onFieldChanged);
      }
    } else {
      _invoiceNumberController.text = 'Auto-Generated';
      _invoiceDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      _dueDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 15)));
      _placeOfSupplyController.text = 'Maharashtra';

      _itemsControllers.add(_ItemControllers());
      _itemsControllers[0].nameController.addListener(_onFieldChanged);
      _itemsControllers[0].rateController.addListener(_onFieldChanged);
      _itemsControllers[0].qtyController.addListener(_onFieldChanged);
      _itemsControllers[0].gstController.addListener(_onFieldChanged);
    }

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
    _clientSearchController.removeListener(_onClientSearchChanged);
    _invoiceNumberController.removeListener(_onFieldChanged);
    _discountPercentageController.removeListener(_calculateTotals);
    _advancePaidController.removeListener(_calculateTotals);
    _clientSearchController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _clientPhoneController.dispose();
    _clientGstController.dispose();
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _placeOfSupplyController.dispose();
    _discountPercentageController.dispose();
    _advancePaidController.dispose();
    _termsController.dispose();
    for (var controller in _itemsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateTotals() {
    double tempSubtotal = 0.0;
    double tempTaxAmount = 0.0;

    final double discountPct =
        double.tryParse(_discountPercentageController.text) ?? 0.0;

    for (var item in _itemsControllers) {
      final double qty = double.tryParse(item.qtyController.text) ?? 0.0;
      final double rate = double.tryParse(item.rateController.text) ?? 0.0;
      final double itemSubtotal = qty * rate;
      tempSubtotal += itemSubtotal;

      if (_gstEnabled) {
        final double gstRate = double.tryParse(item.gstController.text) ?? 0.0;
        final double itemDiscount = itemSubtotal * (discountPct / 100);
        final double itemTaxable = itemSubtotal - itemDiscount;

        double itemTax = 0.0;
        if (_taxType == 'exclusive') {
          itemTax = itemTaxable * (gstRate / 100);
        } else {
          // Inclusive
          final double basePrice = itemTaxable / (1 + (gstRate / 100));
          itemTax = itemTaxable - basePrice;
        }
        tempTaxAmount += itemTax;
      }
    }

    _subtotal = tempSubtotal;
    _discountAmount = _subtotal * (discountPct / 100);
    _taxAmount = tempTaxAmount;

    if (_taxType == 'exclusive') {
      _total = (_subtotal - _discountAmount) + _taxAmount;
    } else {
      _total = _subtotal - _discountAmount;
    }

    final double advancePaid =
        double.tryParse(_advancePaidController.text) ?? 0.0;
    _balanceDue = _total - advancePaid;

    setState(() {});
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface:
                  (Theme.of(context).textTheme.displayLarge?.color ??
                  Colors.black),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _exportPdfWithScreenshot(bool isPrint) async {
    if (_clientNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'error_req_client'.tr,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
      return;
    }

    if (_invoiceNumberController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'error_req_invoice_no'.tr,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
      return;
    }

    for (int i = 0; i < _itemsControllers.length; i++) {
      if (_itemsControllers[i].nameController.text.trim().isEmpty) {
        Fluttertoast.showToast(
          msg: '${'error_req_item_name'.tr} #${i + 1}',
          backgroundColor: AppColors.error,
          textColor: Colors.white,
        );
        return;
      }
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 1. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoader(message: 'generating_invoice_pdf'.tr),
    );

    try {
      final screenshotController = ScreenshotController();

      // Compile items
      final List<Map<String, dynamic>> itemsList = [];
      for (var item in _itemsControllers) {
        final double qty = double.tryParse(item.qtyController.text) ?? 1.0;
        final double rate = double.tryParse(item.rateController.text) ?? 0.0;
        final double gstRate = double.tryParse(item.gstController.text) ?? 18.0;
        itemsList.add({
          'description': item.nameController.text.trim(),
          'additionalDetails': item.descriptionController.text.trim(),
          'quantity': qty.toInt(),
          'rate': rate,
          'gst': gstRate,
        });
      }

      final invoiceData = {
        'id': _invoiceNumberController.text.trim(),
        'clientName': _clientNameController.text.trim(),
        'email': _clientEmailController.text.trim(),
        'address': _clientAddressController.text.trim(),
        'clientGst': _clientGstController.text.trim(),
        'date': _invoiceDateController.text.trim(),
        'dueDate': _dueDateController.text.trim(),
        'placeOfSupply': _placeOfSupplyController.text.trim(),
        'items': itemsList,
        'discount': double.tryParse(_discountPercentageController.text) ?? 0.0,
        'subtotal': _subtotal,
        'discountAmount': _discountAmount,
        'taxAmount': _taxAmount,
        'total': _total,
        'gstEnabled': _gstEnabled,
        'taxType': _taxType,
      };

      // Usable height parameters for clean mathematical pagination (A4 standard: 794 x 1123 @96 DPI)
      const double itemHeight = 70.0;
      const double pageHeight = 1123.0;
      const double margin = 40.0;
      const double usableHeight = pageHeight - (margin * 2);
      const double headerHeight = 310.0;
      const double tableHeaderHeight = 45.0;
      const double totalsHeight = 220.0;

      // Run dynamic splitting algorithm
      final pages = _paginateInvoiceItems(
        items: itemsList,
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
              body: _buildOfflineInvoiceA4Page(
                invoiceData: invoiceData,
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
              pixelRatio: 4.0, // High quality to prevent blurry text outputs
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
          name: 'Invoice_${invoiceData['id']}.pdf',
        );
      } else {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'Invoice_${invoiceData['id']}.pdf',
        );
      }
    } catch (e) {
      if (mounted) navigator.pop();
      Fluttertoast.showToast(
        msg: 'Error generating PDF: $e',
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  List<List<Map<String, dynamic>>> _paginateInvoiceItems({
    required List<Map<String, dynamic>> items,
    required double itemHeight,
    required double usableHeight,
    required double headerHeight,
    required double tableHeaderHeight,
    required double totalsHeight,
  }) {
    final List<List<Map<String, dynamic>>> pages = [];
    List<Map<String, dynamic>> currentPageItems = [];
    double currentHeight = 0.0;
    bool isFirstPage = true;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      // Calculate available item height for this page
      double availableHeight = usableHeight - tableHeaderHeight;
      if (isFirstPage) {
        availableHeight -= headerHeight;
      }

      // Check if this is the last item, in which case we MUST fit totals on the same page
      final bool isLastItem = (i == items.length - 1);
      double requiredHeightForThisItem = itemHeight;

      if (isLastItem) {
        requiredHeightForThisItem += totalsHeight;
      }

      if (currentHeight + requiredHeightForThisItem > availableHeight) {
        // Exceeds! Push current page and start a new page
        if (currentPageItems.isNotEmpty) {
          pages.add(currentPageItems);
          currentPageItems = [];
          currentHeight = 0.0;
          isFirstPage = false;
          availableHeight = usableHeight - tableHeaderHeight;
        }

        // Check if item + totals exceeds the full fresh page height
        if (isLastItem && (itemHeight + totalsHeight > availableHeight)) {
          // Put the item on this page, and we will place the totals section on an extra blank page
          currentPageItems.add(item);
          pages.add(currentPageItems);
          currentPageItems = [];
          currentHeight = 0.0;
          // Start a brand new page bucket for the totals section
          pages.add([]);
          break;
        }
      }

      currentPageItems.add(item);
      currentHeight += itemHeight;
    }

    if (currentPageItems.isNotEmpty || pages.isEmpty) {
      pages.add(currentPageItems);
    }

    return pages;
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

  Widget _buildOfflineInvoiceA4Page({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> pageItems,
    required int pageIndex,
    required int totalPages,
    required bool isFirstPage,
    required bool isLastPage,
  }) {
    final double subtotalVal = (invoiceData['subtotal'] as num).toDouble();
    final double discountAmountVal = (invoiceData['discountAmount'] as num)
        .toDouble();
    final double taxAmountVal = (invoiceData['taxAmount'] as num).toDouble();
    final double totalVal = (invoiceData['total'] as num).toDouble();
    final double discountPct = (invoiceData['discount'] as num).toDouble();
    final bool gstEnabledVal = invoiceData['gstEnabled'] as bool? ?? false;
    final String taxTypeVal = invoiceData['taxType'] as String? ?? 'exclusive';
    final String clientGstVal = invoiceData['clientGst'] as String? ?? '';

    return Container(
      width: 794,
      height: 1123,
      padding: const EdgeInsets.all(40),
      color: Colors.white,
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
                    _mockTenant['name']!.toUpperCase(),
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
                    _mockTenant['address']!.toUpperCase(),
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
                    '${_mockTenant['email']!.toUpperCase()}  •  ${_mockTenant['phone']!.toUpperCase()}'
                    '${_mockTenant['website'] != null && _mockTenant['website']!.isNotEmpty ? '  •  ${_mockTenant['website']!.toUpperCase()}' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (gstEnabledVal &&
                    _mockTenant['gstNumber'] != null &&
                    _mockTenant['gstNumber']!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      'GSTIN: ${_mockTenant['gstNumber']!.toUpperCase()}',
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
                  'INVOICE',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w100, // thin
                    color: Colors.black26,
                    letterSpacing: 0.5,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#${invoiceData['id']}',
                      style: const TextStyle(
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
                          invoiceData['date'] as String,
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
                        const SizedBox(
                          width: 80,
                          child: Text(
                            'Due Date:',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                        Text(
                          invoiceData['dueDate'] as String,
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
                        (invoiceData['clientName'] as String).toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.serifFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoiceData['address'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        invoiceData['email'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                      if (gstEnabledVal && clientGstVal.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            color: Colors.black.withValues(alpha: 0.02),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            'GSTIN: $clientGstVal',
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
                  child: Column(
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 10,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                          children: [
                            TextSpan(text: 'name_colon'.tr),
                            TextSpan(
                              text: '${_mockBankDetails['accountName']}\n',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                            ),
                            TextSpan(text: 'bank_colon'.tr),
                            TextSpan(
                              text: '${_mockBankDetails['bankName']}\n',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                            ),
                            TextSpan(text: 'ac_colon'.tr),
                            TextSpan(
                              text: '${_mockBankDetails['accountNumber']}\n',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                            ),
                            TextSpan(text: 'ifsc_colon'.tr),
                            TextSpan(
                              text: '${_mockBankDetails['ifscCode']}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
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
                  'Invoice Ref: #${invoiceData['id']}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    fontFamily: AppTypography.serifFontFamily,
                  ),
                ),
                Text(
                  'Date: ${invoiceData['date']}',
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
          ],

          // Elegant double-line table header
          Container(
            decoration: const BoxDecoration(
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
                if (gstEnabledVal)
                  SizedBox(
                    width: 60,
                    child: Text(
                      'HSN/SAC',
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(pageItems.length, (index) {
                final item = pageItems[index];
                final double qty = ((item['quantity'] ?? 1) as num).toDouble();
                final double rate = ((item['rate'] ?? 0.0) as num).toDouble();
                final double amount = qty * rate;
                final itemNo = (pageIndex * 10 + index + 1).toString().padLeft(
                  2,
                  '0',
                );

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
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (gstEnabledVal)
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
                          qty % 1 == 0
                              ? qty.toStringAsFixed(0)
                              : qty.toStringAsFixed(2),
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
                          formatCurrency.format(rate),
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
                          formatCurrency.format(amount),
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
            ),
          ),

          // Table Bottom Solid Line
          Container(height: 1.5, color: Colors.black87),

          if (isLastPage) ...[
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount in Words & Terms
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AMOUNT IN WORDS',
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
                        _convertNumberToWords(totalVal).toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.serifFontFamily,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        '1. All payments must be made within ${invoiceData['dueDate'].toString().isNotEmpty ? "due date" : "15 days"}.\n'
                        '2. Please quote invoice number on bank transfers.\n'
                        '3. Goods/services once supplied cannot be returned or cancelled.',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[600],
                          height: 1.4,
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            formatCurrency.format(subtotalVal),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (discountAmountVal > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${'discount'.tr} (${discountPct.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '- ${formatCurrency.format(discountAmountVal)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (gstEnabledVal && taxAmountVal > 0) ...[
                        const SizedBox(height: 4),
                        if ((invoiceData['placeOfSupply'] as String? ?? '')
                                .toLowerCase()
                                .contains('telangana') ||
                            (invoiceData['placeOfSupply'] as String? ?? '')
                                .contains('36')) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'cgst_9'.tr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                formatCurrency.format(taxAmountVal / 2),
                                style: const TextStyle(
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
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                formatCurrency.format(taxAmountVal / 2),
                                style: const TextStyle(
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
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                formatCurrency.format(taxAmountVal),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      const Divider(height: 12, color: Colors.black12),
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
                              'balance_due'.tr,
                              style: TextStyle(
                                fontFamily: AppTypography.serifFontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              formatCurrency.format(totalVal),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'for_auriva_business_solutions_pvt_ltd'.tr,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 35),
                    Text(
                      'authorized_signatory'.tr,
                      style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],

          const Spacer(),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thank you for your business!',
                style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color:
                      (Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.grey),
                ),
              ),
              Text(
                'Page ${pageIndex + 1} of $totalPages',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color:
                      (Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isInclusiveGst = false,
    bool isGrandTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 12 : 11,
              fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
              color: isInclusiveGst || isDiscount
                  ? (Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.grey)
                  : (Theme.of(context).textTheme.displayLarge?.color ??
                        Colors.black),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 11,
              fontWeight: FontWeight.bold,
              color: isDiscount
                  ? AppColors.error
                  : isGrandTotal
                  ? AppColors.primary
                  : (Theme.of(context).textTheme.displayLarge?.color ??
                        Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAndShowBill() async {
    if (_clientNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'error_req_client'.tr,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
      return;
    }

    if (_invoiceNumberController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'error_req_invoice_no'.tr,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
      return;
    }

    for (int i = 0; i < _itemsControllers.length; i++) {
      if (_itemsControllers[i].nameController.text.trim().isEmpty) {
        Fluttertoast.showToast(
          msg: '${'error_req_item_name'.tr} #${i + 1}',
          backgroundColor: AppColors.error,
          textColor: Colors.white,
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoader(
        message: widget.invoiceToEdit != null
            ? 'Updating Invoice...'
            : 'Creating Invoice...',
      ),
    );

    final List<Map<String, dynamic>> itemsList = [];
    for (var item in _itemsControllers) {
      final double qty = double.tryParse(item.qtyController.text) ?? 1.0;
      final double rate = double.tryParse(item.rateController.text) ?? 0.0;
      final double gstRate = double.tryParse(item.gstController.text) ?? 18.0;
      itemsList.add({
        'description': item.nameController.text.trim(),
        'additionalDetails': item.descriptionController.text.trim(),
        'quantity': qty.toInt(),
        'rate': rate,
        'gstRate': _gstEnabled ? gstRate : 0.0,
        'hsnCode': _gstEnabled ? item.hsnController.text.trim() : '',
      });
    }

    final Map<String, dynamic> clientData = {
      'name': _clientNameController.text.trim(),
      'email': _clientEmailController.text.trim(),
      'address': _clientAddressController.text.trim(),
      'phone': _clientPhoneController.text.trim(),
      'gstin': _clientGstController.text.trim(),
      'state': _selectedClientState == 'select_state'.tr
          ? ''
          : _selectedClientState,
    };
    if (_selectedClientId != null) {
      clientData['clientId'] = _selectedClientId;
    }

    final payload = {
      'invoiceNumber': _invoiceNumberController.text.trim(),
      'date': _invoiceDateController.text.trim(),
      'dueDate': _dueDateController.text.trim(),
      'client': clientData,
      'items': itemsList,
      'gstEnabled': _gstEnabled,
      'taxType': _taxType,
      'discountPercentage':
          double.tryParse(_discountPercentageController.text) ?? 0.0,
      'advancePayment': double.tryParse(_advancePaidController.text) ?? 0.0,
      'placeOfSupply': _placeOfSupplyController.text.trim(),
      'terms': _termsController.text.trim(),
      'notes': 'Thank you for your business!',
    };

    try {
      final isEdit = widget.invoiceToEdit != null;
      final editId = widget.invoiceToEdit?['_id']?.toString() ?? '';

      final http.Response response;
      if (isEdit) {
        response = await ApiService.put(
          '${ApiConstants.invoices}/$editId',
          payload,
        );
      } else {
        response = await ApiService.post(ApiConstants.invoices, payload);
      }

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final inv = responseData['data'] ?? {};
        final clientObj = inv['client'] ?? {};
        final String clientNameStr = clientObj['name'] ?? 'Unknown';
        final String invoiceNum =
            inv['invoiceNumber'] ?? inv['id'] ?? 'Invoice';
        final double totalAmt = (inv['totalAmount'] ?? inv['grandTotal'] ?? 0.0)
            .toDouble();

        final formattedAmount = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        ).format(totalAmt);

        if (!context.mounted) return;
        CustomNotificationOverlay.show(
          context: context,
          title: isEdit ? 'Invoice Updated' : 'Invoice Created',
          message: isEdit
              ? '$formattedAmount updated for $clientNameStr'
              : '$formattedAmount saved for $clientNameStr',
          amount: formattedAmount,
          invoiceNumber: 'Invoice $invoiceNum',
          type: 'invoice',
        );

        await _clientsController.fetchClients();

        if (isEdit) {
          if (!context.mounted) return;
          Navigator.pop(context);
        } else {
          final String email = clientObj['email'] ?? '';
          final String phone = clientObj['phone'] ?? '';
          final String address = clientObj['address'] ?? '';
          final String gst = clientObj['gstNumber'] ?? '';

          if (!context.mounted) return;

          final clientsController = Get.isRegistered<ClientsController>()
              ? Get.find<ClientsController>()
              : Get.put(ClientsController());
          clientsController.fetchInvoices();

          final shouldShowDialog = false; // Always navigate
          if (!shouldShowDialog) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceDetailsScreen(
                  invoiceId: inv['invoiceNumber'] ?? inv['id'] ?? '',
                  dbId: inv['_id'] ?? inv['id'] ?? '',
                  clientName: clientNameStr,
                  amount: totalAmt,
                  date: inv['date'] ?? inv['createdAt'] ?? '',
                  status: inv['status'] ?? 'Pending',
                  items: List<Map<String, dynamic>>.from(
                    (inv['items'] ?? []).map(
                      (x) => Map<String, dynamic>.from(x),
                    ),
                  ),
                  dueDate: inv['dueDate'],
                  placeOfSupply: inv['placeOfSupply'],
                  discountPercentage: (inv['discountPercentage'] ?? 0.0)
                      .toDouble(),
                  gstEnabled: inv['gstEnabled'] ?? false,
                  taxType: inv['taxType'] ?? 'exclusive',
                  clientEmail: email,
                  clientPhone: phone,
                  clientAddress: address,
                  clientGst: gst,
                  advancePayment: (inv['advancePayment'] ?? 0.0).toDouble(),
                ),
              ),
            );
          }
        }
      } else {
        Fluttertoast.showToast(
          msg: isEdit ? 'Failed to update invoice' : 'Failed to create invoice',
          backgroundColor: AppColors.error,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      Fluttertoast.showToast(
        msg: 'Error saving invoice: $e',
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  double get _formCompleteness {
    double score = 0.0;
    if (_clientNameController.text.trim().isNotEmpty) score += 0.25;
    if (_invoiceNumberController.text.trim().isNotEmpty) score += 0.25;

    final bool hasValidItem =
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
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
                    'invoice_completeness'.tr,
                    style: context.typography.categoryHeader.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          (Theme.of(context).textTheme.displayLarge?.color ??
                          Colors.black),
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: context.typography.percentageText.copyWith(
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
                Container(
                  height: 6,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: 6,
                  width: MediaQuery.of(context).size.width * 0.9 * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: percentage == 100
                          ? [AppColors.success, const Color(0xFF047857)]
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'new_invoice'.tr,
          style: context.typography.invoiceTitle.copyWith(
            color:
                (Theme.of(context).textTheme.displayLarge?.color ??
                Colors.black),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color:
                (Theme.of(context).textTheme.displayLarge?.color ??
                Colors.black),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ScaleOnPress(
            onTap: _saveAndShowBill,
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
                  const Icon(LucideIcons.save, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Save',
                    style: context.typography.buttonText.copyWith(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 800;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  delay: Duration.zero,
                  child: _buildCompletenessHeader(),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 50),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildClientSection()),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _buildInvoiceMetaSection(),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildClientSection(),
                            const SizedBox(height: 16),
                            _buildInvoiceMetaSection(),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildItemsSection(),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: _buildSummarySection()),
                            const SizedBox(width: 24),
                            Expanded(flex: 1, child: _buildTermsSection()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummarySection(),
                            const SizedBox(height: 16),
                            _buildTermsSection(),
                          ],
                        ),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: context.typography.categoryHeader.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color:
                (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildClientSection() {
    return _buildCard(
      title: 'bill_to'.tr,
      icon: LucideIcons.user,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'search_existing_client'.tr,
            hint: 'type_to_search_clients'.tr,
            icon: LucideIcons.search,
            controller: _clientSearchController,
            suffixIcon: _clientSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
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
                color: Theme.of(context).cardTheme.color,
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
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline,
                ),
                itemBuilder: (context, index) {
                  final client = _filteredClients[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      client.name,
                      style: context.typography.clientName.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            (Theme.of(context).textTheme.displayLarge?.color ??
                            Colors.black),
                      ),
                    ),
                    subtitle: Text(
                      client.email.isNotEmpty
                          ? client.email
                          : 'No email address',
                      style: context.typography.clientCompany.copyWith(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: const Icon(
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
                        _selectedClientState = client.state.isNotEmpty
                            ? sanitizeStateName(client.state)
                            : 'select_state'.tr;
                        if (!indianStates.contains(_selectedClientState)) {
                          _selectedClientState = 'select_state'.tr;
                        }
                        _placeOfSupplyController.text = _selectedClientState;
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
                child: _buildTextField(
                  label: 'client_name_star'.tr,
                  hint: 'eg_name'.tr,
                  controller: _clientNameController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'email'.tr,
                  hint: 'eg_email'.tr,
                  controller: _clientEmailController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'address'.tr,
            hint: 'eg_address'.tr,
            maxLines: 2,
            controller: _clientAddressController,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'details'.tr,
            hint: 'eg_phone'.tr,
            controller: _clientPhoneController,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  label: 'gstin'.tr,
                  hint: 'gstin'.tr,
                  controller: _clientGstController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildDropdownField(
                  label: 'state'.tr,
                  value: _selectedClientState,
                  items: indianStates,
                  onChanged: (val) {
                    setState(() {
                      _selectedClientState = val ?? 'select_state'.tr;
                      _placeOfSupplyController.text = _selectedClientState;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceMetaSection() {
    return _buildCard(
      title: 'invoice_details'.tr,
      icon: LucideIcons.fileText,
      iconColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'invoice_date_star'.tr,
                  hint: 'date_format'.tr,
                  icon: LucideIcons.calendar,
                  controller: _invoiceDateController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _invoiceDateController),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'due_date_star'.tr,
                  hint: 'date_format'.tr,
                  icon: LucideIcons.calendar,
                  controller: _dueDateController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _dueDateController),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'place_of_supply_star'.tr,
                  value:
                      _placeOfSupplyController.text.isEmpty ||
                          !indianStates.contains(_placeOfSupplyController.text)
                      ? 'select_state'.tr
                      : _placeOfSupplyController.text,
                  items: indianStates,
                  onChanged: (val) {
                    setState(() {
                      _placeOfSupplyController.text = val ?? 'select_state'.tr;
                    });
                    _calculateTotals();
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: SizedBox(),
              ), // Empty space for alignment as seen in typical 2 column layout
            ],
          ),
          const SizedBox(height: 12),
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
                        const Icon(
                          LucideIcons.creditCard,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'enable_gst'.tr,
                          style: context.typography.categoryHeader.copyWith(
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
                        inactiveTrackColor: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
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
                              'exclusive'.tr,
                              style: context.typography.buttonText.copyWith(
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
                              'inclusive'.tr,
                              style: context.typography.buttonText.copyWith(
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

  Widget _buildItemsSection() {
    return _buildCard(
      title: 'line_items'.tr,
      icon: LucideIcons.listOrdered,
      iconColor: Colors.teal,
      trailing: Text(
        '${_itemsControllers.length} Items Added',
        style: context.typography.cardDescription.copyWith(
          fontSize: 11,
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
              return AnimatedItemCard(
                key: ValueKey(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemNameAutocomplete(index, item),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'desc_optional'.tr,
                      hint: 'add_extra_details'.tr,
                      controller: item.descriptionController,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            label: 'qty_star'.tr,
                            hint: '1',
                            keyboardType: TextInputType.number,
                            controller: item.qtyController,
                            onChanged: _calculateTotals,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            label: 'rate_star'.tr,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            controller: item.rateController,
                            onChanged: _calculateTotals,
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
                                  style: context.typography.categoryHeader
                                      .copyWith(
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
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.5),
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
                                            style: context.typography.tableCell
                                                .copyWith(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '5',
                                          child: Text(
                                            '5%',
                                            style: context.typography.tableCell
                                                .copyWith(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '12',
                                          child: Text(
                                            '12%',
                                            style: context.typography.tableCell
                                                .copyWith(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '18',
                                          child: Text(
                                            '18%',
                                            style: context.typography.tableCell
                                                .copyWith(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '28',
                                          child: Text(
                                            '28%',
                                            style: context.typography.tableCell
                                                .copyWith(fontSize: 12),
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
                                  style: context.typography.categoryHeader
                                      .copyWith(
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
                                      final double q =
                                          double.tryParse(
                                            item.qtyController.text,
                                          ) ??
                                          0;
                                      final double r =
                                          double.tryParse(
                                            item.rateController.text,
                                          ) ??
                                          0;
                                      final double g =
                                          double.tryParse(
                                            item.gstController.text,
                                          ) ??
                                          18;
                                      final double amt = q * r;
                                      double taxAmt = 0.0;
                                      if (_taxType == 'exclusive') {
                                        taxAmt = amt * (g / 100);
                                      } else {
                                        taxAmt = amt - (amt / (1 + (g / 100)));
                                      }
                                      return Text(
                                        formatCurrency.format(taxAmt),
                                        style: context.typography.invoiceAmount
                                            .copyWith(
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
                            child: _buildTextField(
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
                                style: context.typography.categoryHeader
                                    .copyWith(
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  formatCurrency.format(
                                    (double.tryParse(item.qtyController.text) ??
                                            0.0) *
                                        (double.tryParse(
                                              item.rateController.text,
                                            ) ??
                                            0.0),
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color:
                                        (Theme.of(
                                          context,
                                        ).textTheme.displayLarge?.color ??
                                        Colors.black),
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
                onPressed: () {
                  setState(() {
                    final newControllers = _ItemControllers();
                    newControllers.nameController.addListener(_onFieldChanged);
                    newControllers.rateController.addListener(_onFieldChanged);
                    newControllers.qtyController.addListener(_onFieldChanged);
                    newControllers.gstController.addListener(_onFieldChanged);
                    _itemsControllers.add(newControllers);
                  });
                  _calculateTotals();
                },
                label: Text(
                  'add_new_item_line'.tr,
                  style: context.typography.buttonText.copyWith(
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
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: AppColors.error,
                  ),
                  label: Text(
                    'remove_item'.tr,
                    style: context.typography.buttonText.copyWith(
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

  Widget _buildTermsSection() {
    return _buildCard(
      title: 'terms_notes'.tr,
      icon: LucideIcons.fileSignature,
      iconColor: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'terms_conditions_1'.tr,
            style: context.typography.categoryHeader.copyWith(
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
              color:
                  (Theme.of(context).textTheme.displayLarge?.color ??
                  Colors.black),
            ),
            decoration: InputDecoration(
              hintText: 'add_terms_and_conditions'.tr,
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
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                ),
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
  }

  Widget _buildItemNameAutocomplete(int index, _ItemControllers item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'item_name_title'.tr,
          style: context.typography.categoryHeader.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color:
                (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Theme.of(context).colorScheme.outline,
                        ),
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
                                    style: context.typography.clientName
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color:
                                              (Theme.of(
                                                context,
                                              ).textTheme.displayLarge?.color ??
                                              Colors.black),
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
                                        style: context.typography.clientCompany
                                            .copyWith(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                      ),
                                      Text(
                                        '₹${option.unitPrice.toStringAsFixed(0)}',
                                        style: context.typography.invoiceAmount
                                            .copyWith(
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
                if (fieldTextEditingController.text !=
                    item.nameController.text) {
                  fieldTextEditingController.text = item.nameController.text;
                }

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
                    color:
                        (Theme.of(context).textTheme.displayLarge?.color ??
                        Colors.black),
                  ),
                  decoration: InputDecoration(
                    hintText: 'e_g_website_design'.tr,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.tag,
                      color: Colors.grey,
                      size: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.3),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
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

  Widget _buildSummarySection() {
    final String place = _placeOfSupplyController.text.trim().toLowerCase();
    final bool isOutstate =
        place.isNotEmpty &&
        !place.contains("maharashtra") &&
        place != 'select state';

    return _buildCard(
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
                style: context.typography.tableCell.copyWith(
                  fontSize: 12,
                  color:
                      (Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.grey),
                ),
              ),
              Text(
                formatCurrency.format(_subtotal),
                style: context.typography.tableCell.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      (Theme.of(context).textTheme.displayLarge?.color ??
                      Colors.black),
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
                    'discount'.tr,
                    style: context.typography.tableCell.copyWith(
                      fontSize: 12,
                      color:
                          (Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey),
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
                      style: context.typography.inputText.copyWith(
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
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '- ${formatCurrency.format(_discountAmount)}',
                style: context.typography.tableCell.copyWith(
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
                      ? Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5)
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
                style: context.typography.tableCell.copyWith(
                  fontSize: 12,
                  color:
                      (Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.grey),
                ),
              ),
              Text(
                formatCurrency.format(
                  (_taxType == 'inclusive' && _gstEnabled)
                      ? (_subtotal - _discountAmount - _taxAmount)
                      : (_subtotal - _discountAmount),
                ),
                style: context.typography.tableCell.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      (Theme.of(context).textTheme.displayLarge?.color ??
                      Colors.black),
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
                    style: context.typography.tableCell.copyWith(
                      fontSize: 12,
                      color:
                          (Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey),
                    ),
                  ),
                  Text(
                    formatCurrency.format(_taxAmount),
                    style: context.typography.tableCell.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          (Theme.of(context).textTheme.displayLarge?.color ??
                          Colors.black),
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
                    style: context.typography.tableCell.copyWith(
                      fontSize: 12,
                      color:
                          (Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey),
                    ),
                  ),
                  Text(
                    formatCurrency.format(_taxAmount / 2),
                    style: context.typography.tableCell.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          (Theme.of(context).textTheme.displayLarge?.color ??
                          Colors.black),
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
                    style: context.typography.tableCell.copyWith(
                      fontSize: 12,
                      color:
                          (Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey),
                    ),
                  ),
                  Text(
                    formatCurrency.format(_taxAmount / 2),
                    style: context.typography.tableCell.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          (Theme.of(context).textTheme.displayLarge?.color ??
                          Colors.black),
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
                    'advance_paid'.tr,
                    style: context.typography.tableCell.copyWith(
                      fontSize: 12,
                      color:
                          (Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    height: 26,
                    child: TextField(
                      controller: _advancePaidController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: context.typography.inputText.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      onTap: () {
                        if (_advancePaidController.text == '0') {
                          _advancePaidController.clear();
                        }
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _advancePaidController.text = '0';
                          _advancePaidController.selection =
                              TextSelection.fromPosition(
                                const TextPosition(offset: 1),
                              );
                        } else if (value.startsWith('0') && value.length > 1) {
                          _advancePaidController.text = value.substring(1);
                          _advancePaidController.selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: _advancePaidController.text.length,
                                ),
                              );
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '- ${formatCurrency.format(double.tryParse(_advancePaidController.text) ?? 0.0)}',
                style: context.typography.tableCell.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'balance_due'.tr,
                  style: context.typography.categoryHeader.copyWith(
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
                      style: context.typography.currencyText.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color:
                            (Theme.of(context).textTheme.displayLarge?.color ??
                            Colors.black87),
                      ),
                    ),
                    Text(
                      formatCurrency.format(_balanceDue).replaceAll('₹', ''),
                      style: context.typography.invoiceAmount.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color:
                            (Theme.of(context).textTheme.displayLarge?.color ??
                            Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${'total_amount'.tr}: ${formatCurrency.format(_total)}',
                  style: context.typography.cardDescription.copyWith(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    IconData? icon,
    Color? iconColor,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
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
                  title,
                  style: context.typography.cardTitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        iconColor ??
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.grey),
                  ),
                ),
                if (trailing != null) ...[const Spacer(), trailing],
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final selectedValue = items.contains(value) ? value : items.first;
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
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              icon: Icon(
                LucideIcons.chevronDown,
                size: 16,
                color:
                    (Theme.of(context).textTheme.displayLarge?.color ??
                    Colors.black87),
              ),
              style: context.typography.inputText.copyWith(
                color:
                    (Theme.of(context).textTheme.displayLarge?.color ??
                    Colors.black),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: items.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.typography.tableCell.copyWith(
            fontSize: 13,
            color:
                (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
          ),
        ),
        Text(
          amount,
          style: context.typography.tableCell.copyWith(
            fontWeight: FontWeight.bold,
            color: isDiscount
                ? AppColors.error
                : (Theme.of(context).textTheme.displayLarge?.color ??
                      Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
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
          readOnly: readOnly,
          onTap: onTap,
          style: context.typography.inputText.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                (Theme.of(context).textTheme.displayLarge?.color ??
                Colors.black),
          ),
          onChanged: (val) {
            if (onChanged != null) onChanged();
          },
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
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
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

List<String> get indianStates => [
  'select_state'.tr,
  'Andaman and Nicobar Islands',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chandigarh',
  'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu and Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Lakshadweep',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

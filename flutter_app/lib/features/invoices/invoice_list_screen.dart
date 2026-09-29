import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../core/utils/file_exporter.dart';
import 'invoice_controller.dart';
import 'create_invoice_screen.dart';
import 'invoice_details_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/theme/app_extensions.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final InvoiceController _invoiceController =
      Get.isRegistered<InvoiceController>()
      ? Get.find<InvoiceController>()
      : Get.put(InvoiceController());

  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedMonth = 'all';
  String _sortBy = 'newest';
  int? _hoveredIndex;
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Fetch happens in the controller's onInit, but we can ensure it here if needed
    if (_invoiceController.invoices.isEmpty && !_invoiceController.isLoading.value) {
      _invoiceController.fetchInvoices();
    }
  }

  void _fetchData() {
    _invoiceController.fetchInvoices(
      month: _selectedMonth,
      sortBy: _sortBy,
    );
  }

  List<Invoice> get _invoices {
    return _invoiceController.invoices;
  }

  List<String> get _availableMonths {
    final Set<String> months = {};
    for (var inv in _invoices) {
      if (inv.date.isNotEmpty) {
        final parts = inv.date.split('T');
        if (parts.isNotEmpty) {
          final datePart = parts[0]; // yyyy-MM-dd
          if (datePart.length >= 7) {
            months.add(datePart.substring(0, 7)); // yyyy-MM
          }
        }
      }
    }
    final list = months.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<Invoice> get _filteredInvoices {
    List<Invoice> result = List.from(_invoices);

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      result = result.where((inv) {
        return inv.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               inv.clientName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by status
    if (_selectedStatus != 'all') {
      result = result.where((inv) {
        return inv.status.toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
    }

    // Filter by month
    if (_selectedMonth != 'all') {
      result = result.where((inv) {
        return inv.date.startsWith(_selectedMonth);
      }).toList();
    }

    // Sort
    if (_sortBy == 'newest') {
      result.sort((a, b) => b.date.compareTo(a.date));
    } else if (_sortBy == 'oldest') {
      result.sort((a, b) => a.date.compareTo(b.date));
    } else if (_sortBy == 'highest') {
      result.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_sortBy == 'lowest') {
      result.sort((a, b) => a.amount.compareTo(b.amount));
    }

    return result;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'overdue':
        return AppColors.error;
      case 'partially paid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _sharePublicLink(Invoice inv) {
    final publicLink =
        '${ApiConstants.publicWebUrl}/public/invoice/${inv.dbId}';
    Clipboard.setData(ClipboardData(text: publicLink));
    Fluttertoast.showToast(
      msg: "Public Invoice Link copied to clipboard!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
    );
  }

  void _confirmDeleteInvoice(Invoice inv) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset('assets/SVG/delete.svg', colorFilter: ColorFilter.mode(Colors.red.shade400, BlendMode.srcIn), width: 22, height: 22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    'Delete Invoice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    'Are you sure you want to delete\ninvoice ${inv.id} for ${inv.clientName}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset('assets/SVG/invoice.svg', colorFilter: ColorFilter.mode(Colors.indigo.shade400, BlendMode.srcIn), width: 14, height: 14),
                            ),
                            const SizedBox(width: 10),
                            Text('Invoice No.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const Spacer(),
                            Text(inv.id, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.displayLarge?.color)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset('assets/SVG/userround.svg', colorFilter: ColorFilter.mode(Colors.indigo.shade400, BlendMode.srcIn), width: 14, height: 14),
                            ),
                            const SizedBox(width: 10),
                            Text('Client', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const Spacer(),
                            Text(inv.clientName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.displayLarge?.color)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final success = await _invoiceController.deleteInvoice(inv.dbId);
                            if (success) {
                              Fluttertoast.showToast(msg: "Invoice deleted successfully!", backgroundColor: AppColors.success, textColor: Colors.white);
                            } else {
                              Fluttertoast.showToast(msg: "Failed to delete invoice.", backgroundColor: AppColors.error, textColor: Colors.white);
                            }
                          },
                          icon: SvgPicture.asset('assets/SVG/delete.svg', colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), width: 14, height: 14),
                          label: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Close button
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, size: 14, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeStatus(Invoice inv, String newStatus) async {
    final success = await _invoiceController.updateInvoiceStatus(
      inv.dbId,
      newStatus,
    );
    if (success) {
      Fluttertoast.showToast(
        msg: "Status updated to $newStatus",
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: "Failed to update status",
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  String _formatMonthYear(String yyyyMM) {
    try {
      final parts = yyyyMM.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final monthInt = int.parse(parts[1]);
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[monthInt - 1]} $year';
      }
    } catch (_) {}
    return yyyyMM;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'invoices'.tr,
        showProfile: false,
        showBadge: false,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/SVG/refresh.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).textTheme.displayLarge?.color ?? Colors.black,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              _invoiceController.fetchInvoices();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mounted) {
            setState(() {
              _isManualRefreshing = true;
            });
          }
          await _invoiceController.fetchInvoices();
          if (mounted) {
            setState(() {
              _isManualRefreshing = false;
            });
          }
        },
        child: Obx(() {
          final isLoading = _invoiceController.isLoading.value;
          final isFirstLoad = _invoiceController.invoices.isEmpty;
          final showSkeleton =
              isLoading && (isFirstLoad || _isManualRefreshing);
          final listItems = showSkeleton
              ? List.generate(
                  5,
                  (index) => Invoice(
                    dbId: 'loading_$index',
                    id: 'INV-2026-000$index',
                    clientName: 'Placeholder Customer Name',
                    clientEmail: 'email@example.com',
                    clientPhone: '9876543210',
                    clientAddress: '123, Loading Street, Loading City',
                    clientGst: '07AAAAA0000A1Z0',
                    amount: 15000.0,
                    subtotal: 15000.0,
                    discountPercentage: 0,
                    taxAmount: 2700,
                    date: '2026-06-10T00:00:00Z',
                    dueDate: '2026-06-20T00:00:00Z',
                    status: 'Pending',
                    gstEnabled: true,
                    taxType: 'exclusive',
                    placeOfSupply: 'Delhi',
                    items: [],
                    advancePayment: 0.0,
                  ),
                )
              : _filteredInvoices;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Skeletonizer(
                enabled: showSkeleton,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 225,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    try {
                                      final excel =
                                          excel_pkg.Excel.createExcel();
                                      final sheet = excel['Sheet1'];

                                      // Set headers matching GST Sales Register
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 0,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'Invoice Number',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 1,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'Invoice Date',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 2,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'Customer Name',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 3,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'Customer GSTIN',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 4,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'Place Of Supply',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 5,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'GST Mode',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 6,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'Taxable Value (INR)',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 7,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'CGST (INR)',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 8,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'SGST (INR)',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 9,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'IGST (INR)',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 10,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = const excel_pkg.DoubleCellValue(
                                        0.0,
                                      ); // Temp place
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 10,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'Total Value (INR)',
                                      );
                                      sheet
                                          .cell(
                                            excel_pkg
                                                .CellIndex.indexByColumnRow(
                                              columnIndex: 11,
                                              rowIndex: 0,
                                            ),
                                          )
                                          .value = excel_pkg.TextCellValue(
                                        'Status',
                                      );

                                      // Fill data
                                      final list = _filteredInvoices;
                                      for (int i = 0; i < list.length; i++) {
                                        final inv = list[i];

                                        final discountAmt =
                                            inv.subtotal *
                                            (inv.discountPercentage / 100);
                                        final taxableValue =
                                            inv.subtotal - discountAmt;

                                        // Check if state is Out of State
                                        final isOutstate =
                                            inv.placeOfSupply.toLowerCase() !=
                                            'delhi';
                                        double cgst = 0;
                                        double sgst = 0;
                                        double igst = 0;

                                        if (inv.gstEnabled) {
                                          if (isOutstate) {
                                            igst = inv.taxAmount;
                                          } else {
                                            cgst = inv.taxAmount / 2;
                                            sgst = inv.taxAmount / 2;
                                          }
                                        }

                                        final String formattedDate =
                                            inv.date.isNotEmpty
                                            ? inv.date.split('T')[0]
                                            : '';

                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 0,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.TextCellValue(
                                          inv.id,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 1,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.TextCellValue(
                                          formattedDate,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 2,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.TextCellValue(
                                          inv.clientName,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 3,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.TextCellValue(
                                          inv.clientGst,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 4,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.TextCellValue(
                                          inv.placeOfSupply,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 5,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.TextCellValue(
                                          inv.taxType.toUpperCase(),
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 6,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.DoubleCellValue(
                                          taxableValue,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 7,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.DoubleCellValue(
                                          cgst,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 8,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.DoubleCellValue(
                                          sgst,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 9,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.DoubleCellValue(
                                          igst,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 10,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.DoubleCellValue(
                                          inv.amount,
                                        );
                                        sheet
                                            .cell(
                                              excel_pkg
                                                  .CellIndex.indexByColumnRow(
                                                columnIndex: 11,
                                                rowIndex: i + 1,
                                              ),
                                            )
                                            .value = excel_pkg.TextCellValue(
                                          inv.status,
                                        );
                                      }

                                      final fileBytes = excel.save();
                                      if (fileBytes != null) {
                                        saveAndShareFile(
                                          Uint8List.fromList(fileBytes),
                                          'gst_sales_register.xlsx',
                                        );
                                        Fluttertoast.showToast(
                                          msg:
                                              "GST Sales Register exported successfully!",
                                          backgroundColor: AppColors.success,
                                          textColor: Colors.white,
                                        );
                                      }
                                    } catch (e) {
                                      Fluttertoast.showToast(
                                        msg: "Failed to export: $e",
                                        backgroundColor: AppColors.error,
                                        textColor: Colors.white,
                                      );
                                    }
                                  },
                                  icon: SvgPicture.asset(
                                    'assets/SVG/downloac.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  ),
                                  label: Text('export_to_excel'.tr),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    elevation: 1,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CreateInvoiceScreen(),
                                      ),
                                    );
                                    _invoiceController.fetchInvoices();
                                  },
                                  icon: SvgPicture.asset('assets/SVG/addclient.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                  label: Text('create_invoice'.tr),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 1,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Search and Filter Panel
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.01),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        onChanged: (val) {
                                          setState(() {
                                            _searchQuery = val;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'search_invoices'.tr,
                                          hintStyle: context.typography.searchHint.copyWith(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                          prefixIcon: UnconstrainedBox(
                                            child: SvgPicture.asset(
                                              'assets/SVG/search.svg',
                                              width: 18,
                                              height: 18,
                                              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: AppColors.primary.withValues(
                                                alpha: 0.5,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CustomSortDropdown(
                                      selectedSort: _sortBy,
                                      onChanged: (val) {
                                        setState(() {
                                          _sortBy = val;
                                        });
                                        _fetchData();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomStatusFilterDropdown(
                                        selectedStatus: _selectedStatus,
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedStatus = val;
                                          });
                                        },
                                        totalCount: _invoiceController.invoices.length,
                                        paidCount: _invoiceController.invoices.where((i) => i.status.toLowerCase() == 'paid').length,
                                        pendingCount: _invoiceController.invoices.where((i) => i.status.toLowerCase() == 'pending').length,
                                        partiallyPaidCount: _invoiceController.invoices.where((i) => i.status.toLowerCase() == 'partially paid').length,
                                        overdueCount: _invoiceController.invoices.where((i) => i.status.toLowerCase() == 'overdue').length,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CustomMonthFilterDropdown(
                                        selectedMonth: _selectedMonth,
                                        availableMonths: _availableMonths,
                                        formatMonthYear: _formatMonthYear,
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedMonth = val;
                                          });
                                          _fetchData();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invoices Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice Register',
                              style: context.typography.cardTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Total: ${listItems.length}',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // View toggle (static for now to match UI exactly)
                              
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Invoices List with entrance animation
                        if (listItems.isEmpty)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.fileSearch,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'no_invoices_found'.tr,
                                  style: context.typography.emptyStateDescription.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (listItems.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: listItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final inv = listItems[index];
                        final statusColor = _getStatusColor(inv.status);
                        final isHovered = _hoveredIndex == index;

                        String formattedDate = inv.date;
                        try {
                          if (inv.date.isNotEmpty) {
                            final parsed = DateTime.parse(inv.date);
                            formattedDate = DateFormat(
                              'dd MMM yyyy',
                            ).format(parsed);
                          }
                        } catch (_) {}

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 200 + (index * 40)),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 15 * (1.0 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoiceDetailsScreen(
                                    invoiceId: inv.id,
                                    dbId: inv.dbId,
                                    clientName: inv.clientName,
                                    amount: inv.amount,
                                    date: inv.date,
                                    status: inv.status,
                                    items: List<Map<String, dynamic>>.from(
                                      inv.items.map(
                                        (x) => Map<String, dynamic>.from(x),
                                      ),
                                    ),
                                    dueDate: inv.dueDate,
                                    placeOfSupply: inv.placeOfSupply,
                                    discountPercentage: inv.discountPercentage,
                                    gstEnabled: inv.gstEnabled,
                                    taxType: inv.taxType,
                                    clientEmail: inv.clientEmail,
                                    clientPhone: inv.clientPhone,
                                    clientAddress: inv.clientAddress,
                                    clientGst: inv.clientGst,
                                    advancePayment: inv.advancePayment,
                                  ),
                                ),
                              );
                            },
                            onHover: (hovering) {
                              setState(() {
                                _hoveredIndex = hovering ? index : null;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isHovered
                                      ? AppColors.primary.withValues(alpha: 0.5)
                                      : Theme.of(context).colorScheme.outline,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isHovered
                                        ? AppColors.primary.withValues(
                                            alpha: 0.04,
                                          )
                                        : Colors.black.withValues(alpha: 0.01),
                                    blurRadius: isHovered ? 12 : 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        height: 44,
                                        width: 44,
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: SvgPicture.asset(
                                            inv.status.toLowerCase() == 'paid'
                                                ? 'assets/SVG/paid.svg'
                                                : (inv.status.toLowerCase() == 'pending'
                                                    ? 'assets/SVG/pending.svg'
                                                    : (inv.status.toLowerCase() == 'partially paid'
                                                        ? 'assets/SVG/partialypaid.svg'
                                                        : 'assets/SVG/overdue.svg')),
                                            width: 20,
                                            height: 20,
                                            colorFilter: ColorFilter.mode(statusColor, BlendMode.srcIn),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          (inv.createdBy ?? 'Admin').length > 7 ? '${(inv.createdBy ?? 'Admin').substring(0, 7)}..' : (inv.createdBy ?? 'Admin'),
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    inv.id,
                                                    style: context.typography.invoiceNumber.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                      color: AppColors.primary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    onSelected: (newStatus) {
                                                      _changeStatus(inv, newStatus);
                                                    },
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'Paid',
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset('assets/SVG/paid.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(AppColors.success, BlendMode.srcIn)),
                                                            const SizedBox(width: 8),
                                                            Text('paid'.tr),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'Pending',
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset('assets/SVG/pending.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(AppColors.warning, BlendMode.srcIn)),
                                                            const SizedBox(width: 8),
                                                            Text('pending'.tr),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'Partially Paid',
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset('assets/SVG/partialypaid.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcIn)),
                                                            const SizedBox(width: 8),
                                                            Text('partially_paid'.tr),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'Overdue',
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset('assets/SVG/overdue.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(AppColors.error, BlendMode.srcIn)),
                                                            const SizedBox(width: 8),
                                                            Text('overdue'.tr),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: statusColor.withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(
                                                          color: statusColor.withValues(alpha: 0.15),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            inv.status.toUpperCase(),
                                                            style: context.typography.invoiceStatus.copyWith(
                                                              fontSize: 7,
                                                              fontWeight: FontWeight.bold,
                                                              color: statusColor,
                                                              letterSpacing: 0.5,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Icon(LucideIcons.chevronDown, size: 8, color: statusColor),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              formatCurrency.format(inv.amount),
                                              style: context.typography.invoiceAmount.copyWith(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                                letterSpacing: -0.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          inv.clientName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/SVG/calendernormal.svg',
                                                    width: 12,
                                                    height: 12,
                                                    colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      formattedDate,
                                                      style: context.typography.dueDate.copyWith(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Tooltip(
                                                  message: 'Share',
                                                  child: InkWell(
                                                    onTap: () => _sharePublicLink(inv),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                      ),
                                                      child: SvgPicture.asset('assets/SVG/share.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color ?? Colors.grey.shade400, BlendMode.srcIn)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Tooltip(
                                                  message: 'View Details',
                                                  child: InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => InvoiceDetailsScreen(
                                                            invoiceId: inv.id,
                                                            dbId: inv.dbId,
                                                            clientName: inv.clientName,
                                                            amount: inv.amount,
                                                            date: inv.date,
                                                            status: inv.status,
                                                            items: List<Map<String, dynamic>>.from(inv.items.map((x) => Map<String, dynamic>.from(x))),
                                                            dueDate: inv.dueDate,
                                                            placeOfSupply: inv.placeOfSupply,
                                                            discountPercentage: inv.discountPercentage,
                                                            gstEnabled: inv.gstEnabled,
                                                            taxType: inv.taxType,
                                                            clientEmail: inv.clientEmail,
                                                            clientPhone: inv.clientPhone,
                                                            clientAddress: inv.clientAddress,
                                                            clientGst: inv.clientGst,
                                                            advancePayment: inv.advancePayment,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                      ),
                                                      child: SvgPicture.asset('assets/SVG/eyeview.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color ?? Colors.grey.shade400, BlendMode.srcIn)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Tooltip(
                                                  message: 'Edit Invoice',
                                                  child: InkWell(
                                                    onTap: () {
                                                      final rawInvoice = _invoiceController.invoices.firstWhere(
                                                        (model) => model.dbId == inv.dbId,
                                                        orElse: () => inv,
                                                      );
                                                      final Map<String, dynamic> invoiceJson = {
                                                        '_id': rawInvoice.dbId,
                                                        'id': rawInvoice.id,
                                                        'invoiceNumber': rawInvoice.id,
                                                        'client': {
                                                          'name': rawInvoice.clientName,
                                                          'email': rawInvoice.clientEmail,
                                                          'phone': rawInvoice.clientPhone,
                                                          'address': rawInvoice.clientAddress,
                                                          'gstin': rawInvoice.clientGst,
                                                        },
                                                        'totalAmount': rawInvoice.amount,
                                                        'subTotal': rawInvoice.subtotal,
                                                        'discountPercentage': rawInvoice.discountPercentage,
                                                        'gstAmount': rawInvoice.taxAmount,
                                                        'date': rawInvoice.date,
                                                        'dueDate': rawInvoice.dueDate,
                                                        'status': rawInvoice.status,
                                                        'gstEnabled': rawInvoice.gstEnabled,
                                                        'taxType': rawInvoice.taxType,
                                                        'placeOfSupply': rawInvoice.placeOfSupply,
                                                        'items': rawInvoice.items,
                                                        'advancePayment': rawInvoice.advancePayment,
                                                      };
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => CreateInvoiceScreen(invoiceToEdit: invoiceJson),
                                                        ),
                                                      ).then((_) => _invoiceController.fetchInvoices());
                                                    },
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                      ),
                                                      child: SvgPicture.asset('assets/SVG/edit.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Theme.of(context).iconTheme.color ?? Colors.grey.shade400, BlendMode.srcIn)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Tooltip(
                                                  message: 'Delete',
                                                  child: InkWell(
                                                    onTap: () => _confirmDeleteInvoice(inv),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                      ),
                                                      child: SvgPicture.asset('assets/SVG/delete.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.red.shade400, BlendMode.srcIn)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Custom Dropdown Widgets

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color..style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(0, size.height); 
    path.lineTo(size.width / 2, 0); 
    path.lineTo(size.width, size.height); 
    path.close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.1), 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomStatusFilterDropdown extends StatefulWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;
  final int totalCount;
  final int paidCount;
  final int pendingCount;
  final int partiallyPaidCount;
  final int overdueCount;

  const CustomStatusFilterDropdown({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
    required this.totalCount,
    required this.paidCount,
    required this.pendingCount,
    required this.partiallyPaidCount,
    required this.overdueCount,
  });

  @override
  State<CustomStatusFilterDropdown> createState() => _CustomStatusFilterDropdownState();
}

class _CustomStatusFilterDropdownState extends State<CustomStatusFilterDropdown> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconAsset,
    required Color color,
    required String value,
    required bool isSelected,
    bool isVertical = false,
  }) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(value);
        _closeDropdown();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            if (isVertical)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(iconAsset, width: 16, height: 16, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppColors.primary : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(iconAsset, width: 16, height: 16, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppColors.primary : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 4,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildOption(context: context, title: 'All', subtitle: '${widget.totalCount} Invoices', iconAsset: 'assets/SVG/allcube.svg', color: AppColors.primary, value: 'all', isSelected: widget.selectedStatus == 'all', isVertical: false),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildOption(context: context, title: 'Paid', subtitle: '${widget.paidCount} Invoices', iconAsset: 'assets/SVG/paid.svg', color: AppColors.success, value: 'paid', isSelected: widget.selectedStatus == 'paid', isVertical: false)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildOption(context: context, title: 'Pending', subtitle: '${widget.pendingCount} Invoices', iconAsset: 'assets/SVG/pending.svg', color: AppColors.warning, value: 'pending', isSelected: widget.selectedStatus == 'pending', isVertical: false)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildOption(context: context, title: 'Partially Paid', subtitle: '${widget.partiallyPaidCount} Invoices', iconAsset: 'assets/SVG/partialypaid.svg', color: Colors.blue, value: 'partially paid', isSelected: widget.selectedStatus == 'partially paid', isVertical: false)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildOption(context: context, title: 'Overdue', subtitle: '${widget.overdueCount} Invoices', iconAsset: 'assets/SVG/overdue.svg', color: AppColors.error, value: 'overdue', isSelected: widget.selectedStatus == 'overdue', isVertical: false)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 1,
                    left: offset.dx - 16 + (size.width / 2) - 10,
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: TrianglePainter(color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentText = 'all'.tr;
    String currentIcon = 'assets/SVG/allcube.svg';
    
    if (widget.selectedStatus == 'paid') {
      currentText = 'paid'.tr;
      currentIcon = 'assets/SVG/paid.svg';
    } else if (widget.selectedStatus == 'pending') {
      currentText = 'pending'.tr;
      currentIcon = 'assets/SVG/pending.svg';
    } else if (widget.selectedStatus == 'partially paid') {
      currentText = 'partially_paid'.tr;
      currentIcon = 'assets/SVG/partialypaid.svg';
    } else if (widget.selectedStatus == 'overdue') {
      currentText = 'overdue'.tr;
      currentIcon = 'assets/SVG/overdue.svg';
    }

    return GestureDetector(
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isOpen ? AppColors.primary.withValues(alpha: 0.05) : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          border: Border.all(
            color: _isOpen ? AppColors.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SvgPicture.asset(currentIcon, width: 16, height: 16, colorFilter: ColorFilter.mode(_isOpen ? AppColors.primary : Colors.grey.shade600, BlendMode.srcIn)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentText,
                style: TextStyle(
                  color: _isOpen ? AppColors.primary : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 16,
              color: _isOpen ? AppColors.primary : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Sort Dropdown Widget

class CustomSortDropdown extends StatefulWidget {
  final String selectedSort;
  final ValueChanged<String> onChanged;

  const CustomSortDropdown({
    super.key,
    required this.selectedSort,
    required this.onChanged,
  });

  @override
  State<CustomSortDropdown> createState() => _CustomSortDropdownState();
}

class _CustomSortDropdownState extends State<CustomSortDropdown> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String svgPath,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(value);
        _closeDropdown();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              svgPath,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                isSelected ? AppColors.primary : Colors.grey.shade600,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  color: isSelected ? AppColors.primary : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _openDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 4,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOption(context: context, title: 'Newest First', svgPath: 'assets/SVG/newfirst.svg', value: 'newest', isSelected: widget.selectedSort == 'newest'),
                    _buildOption(context: context, title: 'Oldest First', svgPath: 'assets/SVG/oldfirst.svg', value: 'oldest', isSelected: widget.selectedSort == 'oldest'),
                    _buildOption(context: context, title: 'Highest Amount', svgPath: 'assets/SVG/ztoa.svg', value: 'highest', isSelected: widget.selectedSort == 'highest'),
                    _buildOption(context: context, title: 'Lowest Amount', svgPath: 'assets/SVG/atoz.svg', value: 'lowest', isSelected: widget.selectedSort == 'lowest'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentText = 'Newest First';
    if (widget.selectedSort == 'oldest') currentText = 'Oldest First';
    else if (widget.selectedSort == 'highest') currentText = 'Highest Amount';
    else if (widget.selectedSort == 'lowest') currentText = 'Lowest Amount';

    return GestureDetector(
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isOpen ? AppColors.primary.withValues(alpha: 0.05) : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          border: Border.all(
            color: _isOpen ? AppColors.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgPicture.asset(
          'assets/SVG/moreappbar.svg',
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(_isOpen ? AppColors.primary : Colors.grey.shade600, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class CustomMonthFilterDropdown extends StatefulWidget {
  final String selectedMonth;
  final List<String> availableMonths;
  final ValueChanged<String> onChanged;
  final String Function(String) formatMonthYear;

  const CustomMonthFilterDropdown({
    super.key,
    required this.selectedMonth,
    required this.availableMonths,
    required this.onChanged,
    required this.formatMonthYear,
  });

  @override
  State<CustomMonthFilterDropdown> createState() => _CustomMonthFilterDropdownState();
}

class _CustomMonthFilterDropdownState extends State<CustomMonthFilterDropdown> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  int _currentYear = DateTime.now().year;

  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    if (widget.selectedMonth != 'all') {
      final parts = widget.selectedMonth.split('-');
      if (parts.length == 2) {
        _currentYear = int.tryParse(parts[0]) ?? _currentYear;
      }
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  void _openDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    if (widget.selectedMonth != 'all') {
      final parts = widget.selectedMonth.split('-');
      if (parts.length == 2) {
        _currentYear = int.tryParse(parts[0]) ?? DateTime.now().year;
      }
    } else {
      _currentYear = DateTime.now().year;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 4,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setStateOverlay) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => setStateOverlay(() => _currentYear--),
                                child: const Icon(LucideIcons.chevronLeft, size: 20),
                              ),
                              Text('$_currentYear', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              InkWell(
                                onTap: () => setStateOverlay(() => _currentYear++),
                                child: const Icon(LucideIcons.chevronRight, size: 20),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(12, (index) {
                            String monthVal = '$_currentYear-${(index + 1).toString().padLeft(2, '0')}';
                            bool isSelected = widget.selectedMonth == monthVal;
                            
                            return InkWell(
                              onTap: () {
                                widget.onChanged(monthVal);
                                _closeDropdown();
                              },
                              child: Container(
                                width: (MediaQuery.of(context).size.width - 32 - 32 - 24) / 4.1,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _months[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                widget.onChanged('all');
                                _closeDropdown();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text('Clear', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                DateTime now = DateTime.now();
                                widget.onChanged('${now.year}-${now.month.toString().padLeft(2, '0')}');
                                _closeDropdown();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text('This Month', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentText = widget.selectedMonth == 'all' ? 'All Months' : widget.formatMonthYear(widget.selectedMonth);

    return GestureDetector(
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isOpen ? AppColors.primary.withValues(alpha: 0.05) : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          border: Border.all(
            color: _isOpen ? AppColors.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SvgPicture.asset('assets/SVG/calendernormal.svg', width: 16, height: 16, colorFilter: ColorFilter.mode(_isOpen ? AppColors.primary : Colors.grey.shade600, BlendMode.srcIn)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentText,
                style: TextStyle(
                  color: _isOpen ? AppColors.primary : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 16,
              color: _isOpen ? AppColors.primary : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}


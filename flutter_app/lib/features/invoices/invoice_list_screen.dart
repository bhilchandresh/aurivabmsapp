import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../core/utils/file_exporter.dart';
import '../clients/clients_controller.dart';
import 'create_invoice_screen.dart';
import 'invoice_details_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Invoice {
  final String dbId;
  final String id; // This is the invoiceNumber
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final String clientGst;
  final double amount;
  final double subtotal;
  final double discountPercentage;
  final double taxAmount;
  final String date;
  final String dueDate;
  final String status;
  final bool gstEnabled;
  final String taxType;
  final String placeOfSupply;
  final List<dynamic> items;
  final double advancePayment;

  Invoice({
    required this.dbId,
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.clientAddress,
    required this.clientGst,
    required this.amount,
    required this.subtotal,
    required this.discountPercentage,
    required this.taxAmount,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.gstEnabled,
    required this.taxType,
    required this.placeOfSupply,
    required this.items,
    this.advancePayment = 0.0,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final clientObj = json['client'] ?? {};
    final String name = clientObj['name'] ?? 'Unknown';
    final String email = clientObj['email'] ?? '';
    final String phone = clientObj['phone'] ?? clientObj['phoneNumber'] ?? '';
    final String address = clientObj['address'] ?? '';
    final String gst = clientObj['gstin'] ?? clientObj['gstNumber'] ?? '';
    final String state = clientObj['state'] ?? '';

    return Invoice(
      dbId: json['_id'] ?? json['id'] ?? '',
      id: json['invoiceNumber'] ?? '',
      clientName: name,
      clientEmail: email,
      clientPhone: phone,
      clientAddress: address,
      clientGst: gst,
      amount: (json['totalAmount'] ?? 0.0).toDouble(),
      subtotal: (json['subTotal'] ?? 0.0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      taxAmount: (json['gstAmount'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'Pending',
      gstEnabled: json['gstEnabled'] ?? false,
      taxType: json['taxType'] ?? 'exclusive',
      placeOfSupply: json['placeOfSupply'] ?? state,
      items: json['items'] ?? [],
      advancePayment: (json['advancePayment'] ?? 0.0).toDouble(),
    );
  }
}

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> with SingleTickerProviderStateMixin {
  final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final ClientsController _clientsController = Get.isRegistered<ClientsController>()
      ? Get.find<ClientsController>()
      : Get.put(ClientsController());

  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedMonth = 'all';
  int? _hoveredIndex;
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
    _clientsController.fetchClients();
  }

  List<Invoice> get _invoices {
    return _clientsController.allInvoices.map<Invoice>((json) {
      return Invoice.fromJson(Map<String, dynamic>.from(json));
    }).toList();
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
    return _invoices.where((inv) {
      final matchesSearch = inv.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inv.clientName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'all' || inv.status.toLowerCase() == _selectedStatus.toLowerCase();
      
      bool matchesMonth = _selectedMonth == 'all';
      if (_selectedMonth != 'all' && inv.date.isNotEmpty) {
        matchesMonth = inv.date.startsWith(_selectedMonth);
      }
      
      return matchesSearch && matchesStatus && matchesMonth;
    }).toList();
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
    final publicLink = '${ApiConstants.publicWebUrl}/public/invoice/${inv.dbId}';
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete invoice ${inv.id} for ${inv.clientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _clientsController.deleteInvoice(inv.dbId);
              if (success) {
                Fluttertoast.showToast(
                  msg: "Invoice deleted successfully!",
                  backgroundColor: AppColors.success,
                  textColor: Colors.white,
                );
              } else {
                Fluttertoast.showToast(
                  msg: "Failed to delete invoice.",
                  backgroundColor: AppColors.error,
                  textColor: Colors.white,
                );
              }
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeStatus(Invoice inv, String newStatus) async {
    final success = await _clientsController.updateInvoiceStatus(inv.dbId, newStatus);
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
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[monthInt - 1]} $year';
      }
    } catch (_) {}
    return yyyyMM;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'invoices'.tr,
        subtitle: 'manage_billing'.tr,
        showProfile: false,
        showBadge: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mounted) {
            setState(() {
              _isManualRefreshing = true;
            });
          }
          await _clientsController.fetchClients();
          if (mounted) {
            setState(() {
              _isManualRefreshing = false;
            });
          }
        },
        child: Obx(() {
          final isLoading = _clientsController.isLoading.value;
          final isFirstLoad = _clientsController.allInvoices.isEmpty;
          final showSkeleton = isLoading && (isFirstLoad || _isManualRefreshing);
          final listItems = showSkeleton
              ? List.generate(5, (index) => Invoice(
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
                ))
              : _filteredInvoices;

          return Skeletonizer(
            enabled: showSkeleton,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.background,
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
                          final excel = excel_pkg.Excel.createExcel();
                          final sheet = excel['Sheet1'];
                          
                          // Set headers matching GST Sales Register
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = excel_pkg.TextCellValue('Invoice Number');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = excel_pkg.TextCellValue('Invoice Date');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = excel_pkg.TextCellValue('Customer Name');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = excel_pkg.TextCellValue('Customer GSTIN');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = excel_pkg.TextCellValue('Place Of Supply');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = excel_pkg.TextCellValue('GST Mode');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = excel_pkg.TextCellValue('Taxable Value (INR)');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0)).value = excel_pkg.TextCellValue('CGST (INR)');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 0)).value = excel_pkg.TextCellValue('SGST (INR)');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0)).value = excel_pkg.TextCellValue('IGST (INR)');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0)).value = excel_pkg.DoubleCellValue(0.0); // Temp place
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 0)).value = excel_pkg.TextCellValue('Total Value (INR)');
                          sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 0)).value = excel_pkg.TextCellValue('Status');
                          
                          // Fill data
                          final list = _filteredInvoices;
                          for (int i = 0; i < list.length; i++) {
                            final inv = list[i];
                            
                            final discountAmt = inv.subtotal * (inv.discountPercentage / 100);
                            final taxableValue = inv.subtotal - discountAmt;
                            
                            // Check if state is Out of State
                            final isOutstate = inv.placeOfSupply.toLowerCase() != 'delhi';
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
                            
                            final String formattedDate = inv.date.isNotEmpty ? inv.date.split('T')[0] : '';

                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = excel_pkg.TextCellValue(inv.id);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = excel_pkg.TextCellValue(formattedDate);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = excel_pkg.TextCellValue(inv.clientName);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = excel_pkg.TextCellValue(inv.clientGst);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = excel_pkg.TextCellValue(inv.placeOfSupply);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1)).value = excel_pkg.TextCellValue(inv.taxType.toUpperCase());
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1)).value = excel_pkg.DoubleCellValue(taxableValue);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 1)).value = excel_pkg.DoubleCellValue(cgst);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: i + 1)).value = excel_pkg.DoubleCellValue(sgst);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: i + 1)).value = excel_pkg.DoubleCellValue(igst);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: i + 1)).value = excel_pkg.DoubleCellValue(inv.amount);
                            sheet.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: i + 1)).value = excel_pkg.TextCellValue(inv.status);
                          }
                          
                          final fileBytes = excel.save();
                          if (fileBytes != null) {
                            saveAndShareFile(Uint8List.fromList(fileBytes), 'gst_sales_register.xlsx');
                            Fluttertoast.showToast(
                              msg: "GST Sales Register exported successfully!",
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
                      icon: const Icon(LucideIcons.download, size: 16),
                      label: const Text('Export to Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
                        );
                        _clientsController.fetchClients();
                      },
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Create Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'search_invoices'.tr,
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(LucideIcons.search, color: Colors.grey, size: 18),
                        filled: true,
                        fillColor: AppColors.background.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedStatus,
                                icon: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                items: [
                                  DropdownMenuItem(value: 'all', child: Text('all'.tr)),
                                  DropdownMenuItem(value: 'paid', child: Text('paid'.tr)),
                                  DropdownMenuItem(value: 'pending', child: Text('pending'.tr)),
                                  DropdownMenuItem(value: 'partially paid', child: Text('partially_paid'.tr)),
                                  DropdownMenuItem(value: 'overdue', child: Text('overdue'.tr)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedStatus = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedMonth,
                                icon: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                items: [
                                  const DropdownMenuItem(value: 'all', child: Text('All Months')),
                                  ..._availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(_formatMonthYear(m)))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedMonth = val;
                                    });
                                  }
                                },
                              ),
                            ),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invoices Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice Register',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Icon(LucideIcons.slidersHorizontal, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),

              // Invoices List with entrance animation
              if (listItems.isEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.fileSearch, size: 40, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'no_invoices_found'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                    final inv = listItems[index];
                    final statusColor = _getStatusColor(inv.status);
                    final isHovered = _hoveredIndex == index;

                    String formattedDate = inv.date;
                    try {
                      if (inv.date.isNotEmpty) {
                        final parsed = DateTime.parse(inv.date);
                        formattedDate = DateFormat('dd MMM yyyy').format(parsed);
                      }
                    } catch (_) {}

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 200 + (index * 40)),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 15 * (1.0 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHovered ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isHovered
                                    ? AppColors.primary.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.01),
                                blurRadius: isHovered ? 12 : 6,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  inv.status.toLowerCase() == 'paid'
                                      ? LucideIcons.check
                                      : (inv.status.toLowerCase() == 'pending' ? LucideIcons.clock : LucideIcons.alertTriangle),
                                  size: 18,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              inv.id,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppColors.primary,
                                              ),
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
                                                      const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.success),
                                                      const SizedBox(width: 8),
                                                      Text('paid'.tr),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Pending',
                                                  child: Row(
                                                    children: [
                                                      const Icon(LucideIcons.clock, size: 16, color: AppColors.warning),
                                                      const SizedBox(width: 8),
                                                      Text('pending'.tr),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Partially Paid',
                                                  child: Row(
                                                    children: [
                                                      const Icon(LucideIcons.clock, size: 16, color: Colors.blue),
                                                      const SizedBox(width: 8),
                                                      Text('partially_paid'.tr),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'Overdue',
                                                  child: Row(
                                                    children: [
                                                      const Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.error),
                                                      const SizedBox(width: 8),
                                                      Text('overdue'.tr),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: statusColor.withValues(alpha: 0.15), width: 1),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      inv.status.toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                        color: statusColor,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Icon(
                                                      LucideIcons.chevronDown,
                                                      size: 10,
                                                      color: statusColor,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Text(
                                            formatCurrency.format(inv.amount),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              color: AppColors.textPrimary,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      inv.clientName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(LucideIcons.calendar, size: 13, color: Colors.grey.shade400),
                                            const SizedBox(width: 6),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Tooltip(
                                              message: 'Copy Link',
                                              child: InkWell(
                                                onTap: () => _sharePublicLink(inv),
                                                borderRadius: BorderRadius.circular(6),
                                                hoverColor: AppColors.primary.withValues(alpha: 0.08),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(6.0),
                                                  child: Icon(
                                                    LucideIcons.share2,
                                                    size: 16,
                                                    color: AppColors.textSecondary,
                                                  ),
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
                                                hoverColor: AppColors.primary.withValues(alpha: 0.08),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(6.0),
                                                  child: Icon(
                                                    LucideIcons.eye,
                                                    size: 16,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Tooltip(
                                              message: 'Edit Invoice',
                                              child: InkWell(
                                                onTap: () {
                                                  final rawInvoice = _clientsController.allInvoices.firstWhere(
                                                    (json) => (json['_id'] ?? json['id']) == inv.dbId,
                                                    orElse: () => null,
                                                  );
                                                  if (rawInvoice != null) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => CreateInvoiceScreen(invoiceToEdit: rawInvoice),
                                                      ),
                                                    ).then((_) => _clientsController.fetchClients());
                                                  }
                                                },
                                                borderRadius: BorderRadius.circular(6),
                                                hoverColor: AppColors.primary.withValues(alpha: 0.08),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(6.0),
                                                  child: Icon(
                                                    LucideIcons.edit,
                                                    size: 16,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Tooltip(
                                              message: 'Delete',
                                              child: InkWell(
                                                onTap: () => _confirmDeleteInvoice(inv),
                                                borderRadius: BorderRadius.circular(6),
                                                hoverColor: AppColors.error.withValues(alpha: 0.08),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(6.0),
                                                  child: Icon(
                                                    LucideIcons.trash2,
                                                    size: 16,
                                                    color: AppColors.textSecondary,
                                                  ),
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
      );
    }),
   ),
  );
}
}


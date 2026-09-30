import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_loader.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../clients/clients_controller.dart';
import 'create_quotation_screen.dart';
import 'quotation_details_screen.dart';
import '../../navigation/main_layout.dart';
import '../../core/theme/app_extensions.dart';

class Quotation {
  final String dbId;
  final String id;
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
  final String status;
  final bool gstEnabled;
  final String taxType;
  final String placeOfSupply;
  final List<dynamic> items;
  final String? convertedInvoiceId;
  final double advancePayment;
  final String? validUntil;
  final String? templateId;
  final String? createdBy;

  Quotation({
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
    required this.status,
    required this.gstEnabled,
    required this.taxType,
    required this.placeOfSupply,
    required this.items,
    this.convertedInvoiceId,
    this.advancePayment = 0.0,
    this.validUntil,
    this.templateId,
    this.createdBy,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final clientObj = json['client'] ?? {};
    final String name = clientObj['name'] ?? 'Unknown';
    final String email = clientObj['email'] ?? '';
    final String phone = clientObj['phone'] ?? clientObj['phoneNumber'] ?? '';
    final String address = clientObj['address'] ?? '';
    final String gst = clientObj['gstin'] ?? clientObj['gstNumber'] ?? '';
    final String state = clientObj['state'] ?? '';

    return Quotation(
      dbId: json['_id'] ?? json['id'] ?? '',
      id: json['quoteNumber'] ?? json['quotationNumber'] ?? '',
      clientName: name,
      clientEmail: email,
      clientPhone: phone,
      clientAddress: address,
      clientGst: gst,
      amount: (json['totalAmount'] ?? json['grandTotal'] ?? 0.0).toDouble(),
      subtotal: (json['subTotal'] ?? json['subtotal'] ?? 0.0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      taxAmount: (json['gstAmount'] ?? json['taxAmount'] ?? 0.0).toDouble(),
      date: json['date'] ?? json['createdAt'] ?? '',
      status: json['status'] ?? 'Pending',
      gstEnabled: json['gstEnabled'] ?? false,
      taxType: json['taxType'] ?? 'exclusive',
      placeOfSupply: json['placeOfSupply'] ?? state,
      items: json['items'] ?? [],
      convertedInvoiceId: json['convertedInvoiceId']?.toString(),
      advancePayment: (json['advancePayment'] ?? json['advanceReceived'] ?? 0.0)
          .toDouble(),
      validUntil: json['validUntil'] ?? json['dueDate'] ?? '',
      templateId: json['templateId'] ?? json['template'],
      createdBy: json['createdBy']?.toString(),
    );
  }
}

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  String _searchQuery = '';
  String _selectedStatus = 'all';
  int? _hoveredIndex;
  bool _isManualRefreshing = false;

  final ClientsController _clientsController =
      Get.isRegistered<ClientsController>()
      ? Get.find<ClientsController>()
      : Get.put(ClientsController());

  @override
  void initState() {
    super.initState();
    _clientsController.fetchClients();
  }

  List<Quotation> get _quotations {
    return _clientsController.allQuotations.map<Quotation>((json) {
      return Quotation.fromJson(Map<String, dynamic>.from(json));
    }).toList();
  }

  List<Quotation> get _filteredQuotations {
    return _quotations.where((qt) {
      final matchesSearch =
          qt.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          qt.clientName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _selectedStatus == 'all' || qt.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
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

  void _sharePublicLink(Quotation qt) {
    final publicLink =
        '${ApiConstants.publicWebUrl}/public/quotation/${qt.dbId}';
    Clipboard.setData(ClipboardData(text: publicLink));
    Fluttertoast.showToast(
      msg: "Public Quotation Link copied to clipboard!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: context.colorScheme.primary,
      textColor: Colors.white,
    );
  }

  void _confirmDeleteQuotation(Quotation qt) {
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
                    'Delete Quotation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    'Are you sure you want to delete\nquotation ${qt.id} for ${qt.clientName}?',
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
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
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
                            Text('Quotation No.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const Spacer(),
                            Text(qt.id, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.displayLarge?.color)),
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
                            Text(qt.clientName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.displayLarge?.color)),
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
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final success = await _clientsController.deleteQuotation(qt.dbId);
                            if (success) {
                              Fluttertoast.showToast(msg: "Quotation deleted successfully!", backgroundColor: AppColors.success, textColor: Colors.white);
                            } else {
                              Fluttertoast.showToast(msg: "Failed to delete quotation.", backgroundColor: AppColors.error, textColor: Colors.white);
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
            // Close Button
            Positioned(
              right: 12,
              top: 12,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.x, size: 16, color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeStatus(Quotation qt, String newStatus) async {
    final success = await _clientsController.updateQuotationStatus(
      qt.dbId,
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

  void _convertToInvoice(Quotation qt) async {
    final screenContext = context;
    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('convert_to_invoice'.tr),
        content: Text('Convert quotation ${qt.id} into a live invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              BuildContext? loadingContext;
              showDialog(
                context: screenContext,
                barrierDismissible: false,
                builder: (ctx) {
                  loadingContext = ctx;
                  return const AppLoader(message: 'Converting quotation...');
                },
              );

              final invoiceId = await _clientsController
                  .convertQuotationToInvoice(qt.dbId);

              if (loadingContext != null && loadingContext!.mounted) {
                Navigator.pop(loadingContext!);
              }

              if (invoiceId != null) {
                Fluttertoast.showToast(
                  msg: "Converted to invoice successfully!",
                  backgroundColor: AppColors.success,
                  textColor: Colors.white,
                );
                if (Get.isRegistered<MainLayoutController>()) {
                  Get.find<MainLayoutController>().changeIndex(1);
                }
              } else {
                Fluttertoast.showToast(
                  msg: "Failed to convert quotation.",
                  backgroundColor: AppColors.error,
                  textColor: Colors.white,
                );
              }
            },
            child: Text('convert'.tr, style: context.typography.buttonText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'quotations'.tr,
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
              _clientsController.fetchClients();
              _clientsController.fetchQuotations();
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
          await _clientsController.fetchClients();
          await _clientsController.fetchQuotations();
          if (mounted) {
            setState(() {
              _isManualRefreshing = false;
            });
          }
        },
        child: Obx(() {
          final isLoading = _clientsController.isLoading.value;
          final isFirstLoad = _clientsController.allQuotations.isEmpty;
          final showSkeleton =
              isLoading && (isFirstLoad || _isManualRefreshing);
          final listItems = showSkeleton
              ? List.generate(
                  5,
                  (index) => Quotation(
                    dbId: 'loading_$index',
                    id: 'QT-2026-000$index',
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
                    status: 'Pending',
                    gstEnabled: true,
                    taxType: 'exclusive',
                    placeOfSupply: 'Delhi',
                    items: [],
                    advancePayment: 0.0,
                  ),
                )
              : _filteredQuotations;

          return Skeletonizer(
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
                  toolbarHeight: 160,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInUp(
                            delay: Duration.zero,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ScaleOnPress(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateQuotationScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            Color(0xFF1D4ED8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: context.colorScheme.primary
                                                .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/SVG/plus.svg',
                                            width: 16,
                                            height: 16,
                                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'create_quotation'.tr,
                                            style: context.typography.buttonText
                                                .copyWith(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            delay: const Duration(milliseconds: 50),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.01),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'search_quotations'.tr,
                                        hintStyle:
                                            context.typography.searchHint,
                                        prefixIcon: UnconstrainedBox(
                                          child: SvgPicture.asset(
                                            'assets/SVG/search.svg',
                                            width: 18,
                                            height: 18,
                                            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .scaffoldBackgroundColor
                                            .withValues(alpha: 0.5),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: context.colorScheme.outline
                                                .withValues(alpha: 0.5),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  CustomStatusDropdown(
                                    selectedValue: _selectedStatus,
                                    allCount: _quotations.length,
                                    acceptedCount: _quotations.where((q) => q.status == 'Accepted').length,
                                    pendingCount: _quotations.where((q) => q.status == 'Pending').length,
                                    rejectedCount: _quotations.where((q) => q.status == 'Rejected').length,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedStatus = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
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
                        // Register Header with FadeInUp
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Text(
                              'Quotation Register',
                              style: context.typography.cardTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                              ),
                            ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Total: ${listItems.length}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Quotes Registry list
                        if (listItems.isEmpty)
                          FadeInUp(
                            delay: const Duration(milliseconds: 150),
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
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
                                    'no_quotations_found'.tr,
                                    style: context
                                        .typography
                                        .emptyStateDescription
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
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
                        final qt = listItems[index];
                        final statusColor = _getStatusColor(qt.status);
                        final isHovered = _hoveredIndex == index;

                        String formattedDate = qt.date;
                        try {
                          if (qt.date.isNotEmpty) {
                            final parsed = DateTime.parse(qt.date);
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
                          child: Hero(
                            tag: 'quote_card_${qt.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: MouseRegion(
                                onEnter: (_) {
                                  setState(() {
                                    _hoveredIndex = index;
                                  });
                                },
                                onExit: (_) {
                                  setState(() {
                                    _hoveredIndex = null;
                                  });
                                },
                                child: ScaleOnPress(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            QuotationDetailsScreen(
                                              quotationId: qt.id,
                                              dbId: qt.dbId,
                                              clientName: qt.clientName,
                                              amount: qt.amount,
                                              date: qt.date,
                                              status: qt.status,
                                              items:
                                                  List<
                                                    Map<String, dynamic>
                                                  >.from(
                                                    qt.items.map(
                                                      (x) =>
                                                          Map<
                                                            String,
                                                            dynamic
                                                          >.from(x),
                                                    ),
                                                  ),
                                              placeOfSupply: qt.placeOfSupply,
                                              discountPercentage:
                                                  qt.discountPercentage,
                                              gstEnabled: qt.gstEnabled,
                                              taxType: qt.taxType,
                                              clientEmail: qt.clientEmail,
                                              clientPhone: qt.clientPhone,
                                              clientAddress: qt.clientAddress,
                                              advancePayment: qt.advancePayment,
                                              validUntil: qt.validUntil,
                                              templateId: qt.templateId,
                                            ),
                                      ),
                                    );
                                  },
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
                                              ? AppColors.primary.withValues(alpha: 0.04)
                                              : Colors.black.withValues(alpha: 0.01),
                                          blurRadius: isHovered ? 12 : 6,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              children: [
                                                Container(
                                                  height: 40,
                                                  width: 40,
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      qt.status == 'Accepted'
                                                          ? 'assets/SVG/accepted.svg'
                                                          : (qt.status == 'Pending'
                                                                ? 'assets/SVG/pending.svg'
                                                                : 'assets/SVG/regected.svg'),
                                                      width: 18,
                                                      height: 18,
                                                      colorFilter: ColorFilter.mode(statusColor, BlendMode.srcIn),
                                                    ),
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
                                                              qt.id,
                                                              style: context.typography.invoiceNumber.copyWith(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 13,
                                                                color: AppColors.primary,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            PopupMenuButton<String>(
                                                              padding: EdgeInsets.zero,
                                                              onSelected: (newStatus) {
                                                                _changeStatus(qt, newStatus);
                                                              },
                                                              itemBuilder: (context) => [
                                                                PopupMenuItem(
                                                                  value: 'Accepted',
                                                                  child: Row(
                                                                    children: [
                                                                      SvgPicture.asset('assets/SVG/accepted.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(AppColors.success, BlendMode.srcIn)),
                                                                      const SizedBox(width: 8),
                                                                      Text('accepted'.tr),
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
                                                                  value: 'Rejected',
                                                                  child: Row(
                                                                    children: [
                                                                      SvgPicture.asset('assets/SVG/regected.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(AppColors.error, BlendMode.srcIn)),
                                                                      const SizedBox(width: 8),
                                                                      Text('rejected'.tr),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: statusColor.withValues(alpha: 0.08),
                                                                  borderRadius: BorderRadius.circular(6),
                                                                  border: Border.all(
                                                                    color: statusColor.withValues(alpha: 0.15),
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                     const SizedBox(width: 3),
                                                                    Text(
                                                                      qt.status.toUpperCase(),
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
                                                        formatCurrency.format(qt.amount),
                                                        style: context.typography.invoiceAmount.copyWith(
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 15,
                                                          color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                                          letterSpacing: -0.5,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          qt.clientName.isNotEmpty ? '${qt.clientName[0].toUpperCase()}${qt.clientName.substring(1)}' : qt.clientName,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 13,
                                                            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primary.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          'Admin',
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.primary,
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
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            
                                            Expanded(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset('assets/SVG/calendernormal.svg', width: 12, height: 12, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      formattedDate,
                                                      style: context.typography.dueDate.copyWith(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade500,
                                                        fontWeight: FontWeight.w500,
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
                                                    onTap: () => _sharePublicLink(qt),
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                      ),
                                                      child: SvgPicture.asset('assets/SVG/share.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.grey.shade700, BlendMode.srcIn)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Tooltip(
                                                  message: 'View Details',
                                                  child: InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => QuotationDetailsScreen(
                                                            quotationId: qt.id,
                                                            dbId: qt.dbId,
                                                            clientName: qt.clientName,
                                                            amount: qt.amount,
                                                            date: qt.date,
                                                            status: qt.status,
                                                            items: List<Map<String, dynamic>>.from(qt.items.map((x) => Map<String, dynamic>.from(x))),
                                                            placeOfSupply: qt.placeOfSupply,
                                                            discountPercentage: qt.discountPercentage,
                                                            gstEnabled: qt.gstEnabled,
                                                            taxType: qt.taxType,
                                                            clientEmail: qt.clientEmail,
                                                            clientPhone: qt.clientPhone,
                                                            clientAddress: qt.clientAddress,
                                                            advancePayment: qt.advancePayment,
                                                            validUntil: qt.validUntil,
                                                            templateId: qt.templateId,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                      ),
                                                      child: SvgPicture.asset('assets/SVG/eyeview.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.grey.shade700, BlendMode.srcIn)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                if (qt.convertedInvoiceId != null && qt.convertedInvoiceId!.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        SvgPicture.asset('assets/SVG/checkmark.svg', width: 14, height: 14, colorFilter: ColorFilter.mode((Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.grey), BlendMode.srcIn)),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Converted',
                                                          style: context.typography.liveIndicator.copyWith(
                                                            color: (Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.grey),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else ...[
                                                  Tooltip(
                                                    message: 'Convert to Invoice',
                                                    child: InkWell(
                                                      onTap: () => _convertToInvoice(qt),
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                        ),
                                                        child: SvgPicture.asset('assets/SVG/convert.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.purple.shade600, BlendMode.srcIn)),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Tooltip(
                                                    message: 'edit_quotation'.tr,
                                                    child: InkWell(
                                                      onTap: () {
                                                        final rawQuotation = _clientsController.allQuotations.firstWhere(
                                                          (json) => (json['_id'] ?? json['id']) == qt.dbId,
                                                          orElse: () => null,
                                                        );
                                                        if (rawQuotation != null) {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => CreateQuotationScreen(
                                                                quotationToEdit: rawQuotation,
                                                              ),
                                                            ),
                                                          ).then((_) => _clientsController.fetchClients());
                                                        }
                                                      },
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                        ),
                                                        child: SvgPicture.asset('assets/SVG/edit.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.blue.shade600, BlendMode.srcIn)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(width: 6),
                                                Tooltip(
                                                  message: 'delete'.tr,
                                                  child: InkWell(
                                                    onTap: () => _confirmDeleteQuotation(qt),
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                                                      ),
                                                      child: SvgPicture.asset('assets/SVG/delete.svg', width: 14, height: 14, colorFilter: ColorFilter.mode(Colors.red.shade600, BlendMode.srcIn)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),                                  ),
                                ),
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
      end: 0.96,
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
      duration: const Duration(milliseconds: 400),
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

class DropdownArrowPainter extends CustomPainter {
  final Color color;
  DropdownArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomStatusDropdown extends StatefulWidget {
  final String selectedValue;
  final int allCount;
  final int acceptedCount;
  final int pendingCount;
  final int rejectedCount;
  final ValueChanged<String> onChanged;

  const CustomStatusDropdown({
    super.key,
    required this.selectedValue,
    required this.allCount,
    required this.acceptedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.onChanged,
  });

  @override
  State<CustomStatusDropdown> createState() => _CustomStatusDropdownState();
}

class _CustomStatusDropdownState extends State<CustomStatusDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(size.width - 250, size.height + 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 250,
                child: Material(
                  color: Colors.transparent,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.1 * value),
                        alignment: Alignment.topRight,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: CustomPaint(
                            size: const Size(14, 7),
                            painter: DropdownArrowPainter(color: Theme.of(context).cardColor),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              _buildOption('all', 'All', widget.allCount, 'assets/SVG/allcube.svg', Colors.blue),
                              _buildOption('Accepted', 'Accepted', widget.acceptedCount, 'assets/SVG/accepted.svg', AppColors.success),
                              _buildOption('Pending', 'Pending', widget.pendingCount, 'assets/SVG/pending.svg', AppColors.warning),
                              _buildOption('Rejected', 'Rejected', widget.rejectedCount, 'assets/SVG/regected.svg', AppColors.error),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  Widget _buildOption(String value, String title, int count, String svgPath, Color color) {
    final isSelected = widget.selectedValue == value;
    return InkWell(
      onTap: () {
        widget.onChanged(value);
        _closeDropdown();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(svgPath, width: 20, height: 20, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count Quotations',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentSvg = 'assets/SVG/allcube.svg';
    Color currentColor = Colors.blue;

    if (widget.selectedValue == 'Accepted') {
      currentSvg = 'assets/SVG/accepted.svg';
      currentColor = AppColors.success;
    } else if (widget.selectedValue == 'Pending') {
      currentSvg = 'assets/SVG/pending.svg';
      currentColor = AppColors.warning;
    } else if (widget.selectedValue == 'Rejected') {
      currentSvg = 'assets/SVG/regected.svg';
      currentColor = AppColors.error;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isOpen ? Colors.blue : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(currentSvg, width: 18, height: 18, colorFilter: ColorFilter.mode(currentColor, BlendMode.srcIn)),
              const SizedBox(width: 6),
              Icon(
                _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

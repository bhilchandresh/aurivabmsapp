import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
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
      builder: (context) => AlertDialog(
        title: Text('delete_quotation'.tr),
        content: Text(
          'Are you sure you want to delete quotation ${qt.id} for ${qt.clientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _clientsController.deleteQuotation(qt.dbId);
              if (success) {
                Fluttertoast.showToast(
                  msg: "Quotation deleted successfully!",
                  backgroundColor: AppColors.success,
                  textColor: Colors.white,
                );
              } else {
                Fluttertoast.showToast(
                  msg: "Failed to delete quotation.",
                  backgroundColor: AppColors.error,
                  textColor: Colors.white,
                );
              }
            },
            child: Text('delete'.tr, style: context.typography.buttonText),
          ),
        ],
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
        subtitle: 'estimates_proposals'.tr,
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
                                          const Icon(
                                            LucideIcons.plus,
                                            size: 16,
                                            color: Colors.white,
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
                                        prefixIcon: const Icon(
                                          LucideIcons.search,
                                          color: Colors.grey,
                                          size: 18,
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
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor
                                            .withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: _selectedStatus,
                                          icon: const Icon(
                                            LucideIcons.chevronDown,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          style: context.typography.inputText
                                              .copyWith(
                                                color:
                                                    (Theme.of(context)
                                                        .textTheme
                                                        .displayLarge
                                                        ?.color ??
                                                    Colors.black),
                                              ),
                                          items: [
                                            DropdownMenuItem(
                                              value: 'all',
                                              child: Text('all'.tr),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Accepted',
                                              child: Text('accepted'.tr),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Pending',
                                              child: Text('pending'.tr),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Rejected',
                                              child: Text('rejected'.tr),
                                            ),
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
                                'Estimates & Quotes',
                                style: context.typography.categoryHeader,
                              ),
                              const Icon(
                                LucideIcons.slidersHorizontal,
                                size: 16,
                                color: Colors.grey,
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
                                            ? AppColors.primary.withValues(
                                                alpha: 0.5,
                                              )
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isHovered
                                              ? AppColors.primary.withValues(
                                                  alpha: 0.04,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.01,
                                                ),
                                          blurRadius: isHovered ? 12 : 6,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            qt.status == 'Accepted'
                                                ? LucideIcons.check
                                                : (qt.status == 'Pending'
                                                      ? LucideIcons.clock
                                                      : LucideIcons.xCircle),
                                            size: 18,
                                            color: statusColor,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            qt.id,
                                                            style: context
                                                                .typography
                                                                .invoiceNumber
                                                                .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 13,
                                                                  color: context
                                                                      .colorScheme
                                                                      .primary,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        PopupMenuButton<String>(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          onSelected:
                                                              (newStatus) {
                                                                _changeStatus(
                                                                  qt,
                                                                  newStatus,
                                                                );
                                                              },
                                                          itemBuilder: (context) => [
                                                            PopupMenuItem(
                                                              value: 'Accepted',
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    LucideIcons
                                                                        .checkCircle,
                                                                    size: 16,
                                                                    color: AppColors
                                                                        .success,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    'accepted'
                                                                        .tr,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            PopupMenuItem(
                                                              value: 'Pending',
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    LucideIcons
                                                                        .clock,
                                                                    size: 16,
                                                                    color: AppColors
                                                                        .warning,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    'pending'
                                                                        .tr,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            PopupMenuItem(
                                                              value: 'Rejected',
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    LucideIcons
                                                                        .xCircle,
                                                                    size: 16,
                                                                    color: AppColors
                                                                        .error,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    'rejected'
                                                                        .tr,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 3,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: statusColor
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              border: Border.all(
                                                                color: statusColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.15,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  qt.status
                                                                      .toUpperCase(),
                                                                  style: context
                                                                      .typography
                                                                      .invoiceStatus
                                                                      .copyWith(
                                                                        fontSize:
                                                                            8,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            statusColor,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 3,
                                                                ),
                                                                Icon(
                                                                  LucideIcons
                                                                      .chevronDown,
                                                                  size: 10,
                                                                  color:
                                                                      statusColor,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 6,
                                                          left: 4,
                                                        ),
                                                    child: Text(
                                                      formatCurrency.format(
                                                        qt.amount,
                                                      ),
                                                      style: context
                                                          .typography
                                                          .invoiceAmount
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 15,
                                                            color:
                                                                (Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .displayLarge
                                                                    ?.color ??
                                                                Colors.black),
                                                            letterSpacing: -0.5,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                qt.clientName,
                                                style: context
                                                    .typography
                                                    .clientName
                                                    .copyWith(
                                                      color:
                                                          (Theme.of(context)
                                                              .textTheme
                                                              .displayLarge
                                                              ?.color ??
                                                          Colors.black),
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          LucideIcons.calendar,
                                                          size: 13,
                                                          color: Colors
                                                              .grey
                                                              .shade400,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            formattedDate,
                                                            style: context
                                                                .typography
                                                                .cardSubtitle
                                                                .copyWith(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade500,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Tooltip(
                                                        message: 'Copy Link',
                                                        child: InkWell(
                                                          onTap: () =>
                                                              _sharePublicLink(
                                                                qt,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          hoverColor: AppColors
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  4.0,
                                                                ),
                                                            child: Icon(
                                                              LucideIcons
                                                                  .share2,
                                                              size: 16,
                                                              color: AppColors
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Tooltip(
                                                        message: 'View Details',
                                                        child: InkWell(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => QuotationDetailsScreen(
                                                                  quotationId:
                                                                      qt.id,
                                                                  dbId: qt.dbId,
                                                                  clientName: qt
                                                                      .clientName,
                                                                  amount:
                                                                      qt.amount,
                                                                  date: qt.date,
                                                                  status:
                                                                      qt.status,
                                                                  items:
                                                                      List<
                                                                        Map<
                                                                          String,
                                                                          dynamic
                                                                        >
                                                                      >.from(
                                                                        qt.items.map(
                                                                          (x) =>
                                                                              Map<
                                                                                String,
                                                                                dynamic
                                                                              >.from(
                                                                                x,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                  placeOfSupply:
                                                                      qt.placeOfSupply,
                                                                  discountPercentage:
                                                                      qt.discountPercentage,
                                                                  gstEnabled: qt
                                                                      .gstEnabled,
                                                                  taxType: qt
                                                                      .taxType,
                                                                  clientEmail: qt
                                                                      .clientEmail,
                                                                  clientPhone: qt
                                                                      .clientPhone,
                                                                  clientAddress:
                                                                      qt.clientAddress,
                                                                  advancePayment:
                                                                      qt.advancePayment,
                                                                  validUntil: qt
                                                                      .validUntil,
                                                                  templateId: qt
                                                                      .templateId,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          hoverColor: AppColors
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  4.0,
                                                                ),
                                                            child: Icon(
                                                              LucideIcons.eye,
                                                              size: 16,
                                                              color: AppColors
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      if (qt.convertedInvoiceId !=
                                                              null &&
                                                          qt
                                                              .convertedInvoiceId!
                                                              .isNotEmpty)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .outline
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .outline
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                LucideIcons
                                                                    .checkCircle,
                                                                size: 12,
                                                                color:
                                                                    (Theme.of(
                                                                          context,
                                                                        )
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.color
                                                                        ?.withValues(
                                                                          alpha:
                                                                              0.7,
                                                                        ) ??
                                                                    Colors
                                                                        .grey),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                'Converted',
                                                                style: context
                                                                    .typography
                                                                    .liveIndicator
                                                                    .copyWith(
                                                                      color:
                                                                          (Theme.of(
                                                                            context,
                                                                          ).textTheme.bodyMedium?.color?.withValues(
                                                                            alpha:
                                                                                0.7,
                                                                          ) ??
                                                                          Colors
                                                                              .grey),
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      else
                                                        Tooltip(
                                                          message:
                                                              'Convert to Invoice',
                                                          child: InkWell(
                                                            onTap: () =>
                                                                _convertToInvoice(
                                                                  qt,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            hoverColor: Colors
                                                                .purple
                                                                .withValues(
                                                                  alpha: 0.08,
                                                                ),
                                                            child: const Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    4.0,
                                                                  ),
                                                              child: Icon(
                                                                LucideIcons
                                                                    .arrowRightCircle,
                                                                size: 16,
                                                                color: Colors
                                                                    .purple,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      const SizedBox(width: 2),
                                                      if (qt.convertedInvoiceId ==
                                                              null ||
                                                          qt
                                                              .convertedInvoiceId!
                                                              .isEmpty) ...[
                                                        Tooltip(
                                                          message:
                                                              'edit_quotation'
                                                                  .tr,
                                                          child: InkWell(
                                                            onTap: () {
                                                              final rawQuotation = _clientsController
                                                                  .allQuotations
                                                                  .firstWhere(
                                                                    (json) =>
                                                                        (json['_id'] ??
                                                                            json['id']) ==
                                                                        qt.dbId,
                                                                    orElse: () =>
                                                                        null,
                                                                  );
                                                              if (rawQuotation !=
                                                                  null) {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (
                                                                          context,
                                                                        ) => CreateQuotationScreen(
                                                                          quotationToEdit:
                                                                              rawQuotation,
                                                                        ),
                                                                  ),
                                                                ).then(
                                                                  (
                                                                    _,
                                                                  ) => _clientsController
                                                                      .fetchClients(),
                                                                );
                                                              }
                                                            },
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            hoverColor:
                                                                AppColors
                                                                    .primary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.08,
                                                                    ),
                                                            child: const Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    4.0,
                                                                  ),
                                                              child: Icon(
                                                                LucideIcons
                                                                    .edit,
                                                                size: 16,
                                                                color: AppColors
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                      ],
                                                      Tooltip(
                                                        message: 'Delete',
                                                        child: InkWell(
                                                          onTap: () =>
                                                              _confirmDeleteQuotation(
                                                                qt,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          hoverColor: AppColors
                                                              .error
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  6.0,
                                                                ),
                                                            child: Icon(
                                                              LucideIcons
                                                                  .trash2,
                                                              size: 16,
                                                              color: AppColors
                                                                  .textSecondary,
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

// ignore_for_file: unused_field, unused_local_variable, unused_element
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_input_field.dart';
import '../../shared/widgets/state_picker_bottom_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'clients_controller.dart';
import '../invoices/invoice_details_screen.dart';
import '../quotations/quotation_details_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;
  final Client? initialClient;

  const ClientDetailsScreen({
    super.key,
    required this.clientId,
    this.initialClient,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;

  static final Client _dummyClient = Client(
    id: 'skeleton_client_id',
    name: 'Loading Client Details',
    email: 'client@example.com',
    phone: '+91 98765 43210',
    gstin: '24AAAAA0000A1Z5',
    state: 'State',
    address: 'Loading address...',
    totalBilled: 125000.0,
    balance: 35000.0,
    addedBy: 'System',
  );

  static final List<ClientInvoice> _mockInvoices = [
    ClientInvoice(
      id: 'mock_inv_1',
      invoiceNumber: 'INV-0473',
      totalAmount: 1990.0,
      remainingAmount: 1990.0,
      date: '2026-10-10T21:57:00Z',
      status: 'Pending',
      createdBy: 'Shukan',
    ),
    ClientInvoice(
      id: 'mock_inv_2',
      invoiceNumber: 'INV-0472',
      totalAmount: 1270.0,
      remainingAmount: 1270.0,
      date: '2026-10-09T20:23:00Z',
      status: 'Pending',
      createdBy: 'Shukan',
    ),
  ];

  static final List<ClientQuotation> _mockQuotations = [
    ClientQuotation(
      id: 'mock_qt_1',
      quotationNumber: 'QT-2024-001',
      grandTotal: 55000.0,
      date: '2024-03-05',
    ),
    ClientQuotation(
      id: 'mock_qt_2',
      quotationNumber: 'QT-2024-002',
      grandTotal: 28000.0,
      date: '2024-02-10',
    ),
  ];

  static final List<ClientPayment> _mockPayments = [
    ClientPayment(
      id: 'mock_pay_1',
      amount: 1270.0,
      date: '2026-10-09T20:29:00Z',
      paymentMode: 'Other',
      referenceNote: 'Invoice INV-0472',
      invoiceNumber: 'INV-0472',
      createdBy: 'Shukan',
    ),
  ];

  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  final _clientsController = Get.find<ClientsController>();

  String _activeTab = 'invoices'; // 'invoices', 'quotations', 'ledger'
  String _sortOrder = 'desc'; // 'desc', 'asc'
  bool _isSyncing = false;
  bool _isSendingEmail = false;

  late AnimationController _animationController;

  final List<String> _indianStates = [
    "Andaman and Nicobar Islands",
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chandigarh",
    "Chhattisgarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jammu and Kashmir",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Ladakh",
    "Lakshadweep",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Puducherry",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final futures = <Future<dynamic>>[
        _clientsController.fetchPayments(widget.clientId),
        _clientsController.fetchQuotations(widget.clientId),
      ];

      if (_clientsController.clients.isEmpty) {
        futures.add(_clientsController.fetchClients());
      } else {
        futures.add(_clientsController.fetchInvoices(widget.clientId));
      }

      // Smooth skeleton shimmer duration
      futures.add(Future.delayed(const Duration(milliseconds: 450)));

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error loading client details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _safeFormatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return dateStr;
      return _displayDateFormat.format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  String _capitalizeName(String name) {
    if (name.trim().isEmpty) return name;
    return name
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Widget _buildAnimatedWidget(int index, Widget child) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (index * 0.15).clamp(0.0, 1.0),
        ((index * 0.15) + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        elevation: 0.5,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: InkWell(
              onTap: () => Get.back(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/SVG/backarrow.svg',
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).textTheme.displayLarge?.color ?? Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'client_ledger_profile'.tr,
          style: TextStyle(
            color: Theme.of(context).textTheme.displayLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        // Find client dynamically in the controller's reactive list
        final clientIndex = _clientsController.clients.indexWhere(
          (c) => c.id == widget.clientId,
        );

        Client? currentClient;
        if (clientIndex != -1) {
          currentClient = _clientsController.clients[clientIndex];
        } else if (widget.initialClient != null) {
          currentClient = widget.initialClient;
        } else if (_isLoading) {
          currentClient = _dummyClient;
        }

        if (currentClient == null) {
          return Center(
            child: Text(
              'client_not_found_or_has_been_deleted'.tr,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final client = currentClient;
        final rawInvoices = _clientsController.clientInvoices[client.id] ?? [];
        final rawQuotations =
            _clientsController.clientQuotations[client.id] ?? [];
        final rawPayments =
            _clientsController.clientPayments[client.id] ?? [];

        final invoices = (_isLoading && rawInvoices.isEmpty)
            ? _mockInvoices
            : rawInvoices;
        final quotations = (_isLoading && rawQuotations.isEmpty)
            ? _mockQuotations
            : rawQuotations;
        final payments = (_isLoading && rawPayments.isEmpty)
            ? _mockPayments
            : rawPayments;

        final totalBilled = (_isLoading && rawInvoices.isEmpty)
            ? (client.totalBilled > 0 ? client.totalBilled : 125000.0)
            : invoices.fold<double>(
                0.0,
                (sum, inv) => sum + inv.totalAmount,
              );
        final totalPaid = (_isLoading && rawPayments.isEmpty)
            ? (client.totalBilled > 0
                ? (client.totalBilled - client.balance)
                : 90000.0)
            : payments.fold<double>(
                0.0,
                (sum, pay) => sum + pay.amount,
              );
        final balance =
            (_isLoading && rawInvoices.isEmpty && rawPayments.isEmpty)
                ? client.balance
                : (totalBilled - totalPaid);

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: Skeletonizer(
            enabled: _isLoading,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Master Info Card
                  _buildAnimatedWidget(
                    0,
                    _buildClientInfoCard(
                      client,
                      balance,
                      totalBilled,
                      totalPaid,
                      invoices,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats Row (Paid, Billed, Balance)
                  _buildAnimatedWidget(
                    1,
                    _buildStatsRow(balance, totalBilled, totalPaid, client.id),
                  ),
                  const SizedBox(height: 16),

                  // Tabs Navigation
                  _buildAnimatedWidget(
                    2,
                    _buildTabsSection(client, invoices, quotations, payments),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // --- CLIENT INFO CARD ---
  Widget _buildClientInfoCard(
    Client client,
    double balance,
    double billed,
    double paid,
    List<ClientInvoice> invoices,
  ) {
    final hasGstin = client.gstin.trim().isNotEmpty;
    final isLargeScreen = MediaQuery.of(context).size.width > 950;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = (Theme.of(context).cardTheme.color ?? Colors.white);
    final borderColor = Theme.of(context).colorScheme.outline;
    final textColor = (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black);
    final subtextColor = (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey);

    final Widget infoDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          'assets/SVG/mail.svg',
          client.email.isNotEmpty ? client.email : 'no_email_added'.tr,
          Colors.blue.shade400,
          subtextColor,
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'assets/SVG/phone.svg',
          client.phone.isNotEmpty ? client.phone : 'no_phone_added'.tr,
          Colors.green.shade500,
          subtextColor,
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'assets/SVG/location.svg',
          client.address.isNotEmpty ? client.address : 'no_address_added'.tr,
          Colors.red.shade400,
          subtextColor,
        ),
        if (hasGstin) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.purple.shade900.withValues(alpha: 0.15)
                  : Colors.purple.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? Colors.purple.shade900.withValues(alpha: 0.5)
                    : Colors.purple.shade100,
              ),
            ),
            child: Text(
              'GST: ${client.gstin.toUpperCase()}',
              style: TextStyle(
                color: isDark ? Colors.purple.shade300 : Colors.purple.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );

    final Widget actionsList = Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                iconSvg: 'assets/SVG/call.svg',
                label: 'call_sms'.tr,
                backgroundColor: Colors.blue.shade900.withValues(alpha: isDark ? 0.15 : 0.1),
                foregroundColor: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
                borderColor: Colors.blue.shade900.withValues(alpha: isDark ? 0.4 : 0.3),
                onTap: () => _showCallSmsDialog(client, balance, billed, paid, invoices),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                iconSvg: 'assets/SVG/whatsapp.svg',
                label: 'whatsapp'.tr,
                backgroundColor: const Color(0xFF25D366).withValues(alpha: isDark ? 0.15 : 0.1),
                foregroundColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF128C7E),
                borderColor: const Color(0xFF25D366).withValues(alpha: isDark ? 0.4 : 0.3),
                onTap: () => _shareWhatsApp(client, balance, billed, paid, invoices),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                iconSvg: 'assets/SVG/mail.svg',
                label: 'email'.tr,
                backgroundColor: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.05),
                foregroundColor: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                borderColor: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.2),
                isLoading: _isSendingEmail,
                onTap: () => _sendEmailSummary(client),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                iconSvg: 'assets/SVG/edit.svg',
                label: 'edit'.tr,
                backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
                foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.grey.shade700,
                borderColor: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                onTap: () => _showEditClientDialog(client),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCollectPaymentDialog(client),
                icon: SvgPicture.asset('assets/SVG/moneytotal.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                label: Text(
                  'collect'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0.5,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                iconSvg: 'assets/SVG/delete.svg',
                label: 'delete'.tr,
                backgroundColor: isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50,
                foregroundColor: isDark ? Colors.red.shade400 : Colors.red.shade600,
                borderColor: Colors.red.shade900.withValues(alpha: isDark ? 0.4 : 0.1),
                onTap: () => _showDeleteConfirmation(client),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLargeScreen
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    client.name.trim().isNotEmpty
                        ? client.name.trim()[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalizeName(client.name),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      infoDetails,
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                actionsList,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        client.name.trim().isNotEmpty
                            ? client.name.trim()[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalizeName(client.name),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          infoDetails,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 16),
                actionsList,
              ],
            ),
    );
  }

  Widget _buildInfoRow(
    String svgIcon,
    String text,
    Color iconColor,
    Color textColor,
  ) {
    return Row(
      children: [
        SvgPicture.asset(svgIcon, width: 13, height: 13, colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String iconSvg,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            else
              SvgPicture.asset(iconSvg, width: 14, height: 14, colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STATS ROW ---
  Widget _buildStatsRow(
    double balance,
    double billed,
    double paid,
    String clientId,
  ) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine balance color card details
    Color balanceBgColor = const Color(0xFFFFF1F2);
    Color balanceBorderColor = const Color(0xFFFECDD3);
    Color balanceTitleColor = const Color(0xFFE11D48);
    Color balanceAmountColor = const Color(0xFFBE123C);
    String balanceLabel = 'outstanding_due'.tr;

    if (isDark) {
      balanceBgColor = Colors.red.shade900.withValues(alpha: 0.15);
      balanceBorderColor = Colors.red.shade800.withValues(alpha: 0.4);
      balanceTitleColor = Colors.red.shade400;
      balanceAmountColor = Colors.red.shade300;
    }

    if (balance < 0) {
      balanceLabel = 'advance_jama'.tr;
      if (isDark) {
        balanceBgColor = Colors.blue.shade900.withValues(alpha: 0.15);
        balanceBorderColor = Colors.blue.shade800.withValues(alpha: 0.4);
        balanceTitleColor = Colors.blue.shade400;
        balanceAmountColor = Colors.blue.shade300;
      } else {
        balanceBgColor = Colors.blue.shade50;
        balanceBorderColor = Colors.blue.shade200;
        balanceTitleColor = Colors.blue.shade600;
        balanceAmountColor = Colors.blue.shade700;
      }
    } else if (balance == 0) {
      balanceLabel = '${'settled'.tr} ✓';
      if (isDark) {
        balanceBgColor = Colors.green.shade900.withValues(alpha: 0.15);
        balanceBorderColor = Colors.green.shade800.withValues(alpha: 0.3);
        balanceTitleColor = Colors.green.shade400;
        balanceAmountColor = Colors.green.shade300;
      } else {
        balanceBgColor = const Color(0xFFECFDF5);
        balanceBorderColor = const Color(0xFFA7F3D0);
        balanceTitleColor = const Color(0xFF059669);
        balanceAmountColor = const Color(0xFF047857);
      }
    }

    final List<Widget> cards = [
      _buildStatCard(
        title: 'total_paid'.tr,
        amount: paid,
        color: isDark ? Colors.green.shade400 : AppColors.success,
        backgroundColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
        borderColor: Theme.of(context).colorScheme.outline,
      ),
      _buildStatCard(
        title: 'total_billed'.tr,
        amount: billed,
        color: Theme.of(context).textTheme.displayLarge?.color ?? Colors.black,
        backgroundColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
        borderColor: Theme.of(context).colorScheme.outline,
      ),
      _buildStatCard(
        title: balanceLabel,
        amount: balance.abs(),
        color: balanceAmountColor,
        backgroundColor: balanceBgColor,
        borderColor: balanceBorderColor,
        titleColor: balanceTitleColor,
        isOutstanding: true,
        clientId: clientId,
      ),
    ];

    if (isLargeScreen) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: cards[0],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: cards[1],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          cards[2],
        ],
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
    Color? titleColor,
    bool isOutstanding = false,
    String? clientId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color:
                        titleColor ??
                        ((Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isOutstanding && clientId != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _syncLedger(clientId),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF475569)
                            : Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _isSyncing
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                isDark ? Colors.white : AppColors.primary,
                              ),
                            ),
                          )
                        : Icon(
                            LucideIcons.refreshCw,
                            size: 12,
                            color: isDark ? Colors.white : Colors.grey,
                          ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency.format(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- TABS SECTION ---
  Widget _buildTabsSection(
    Client client,
    List<ClientInvoice> invoices,
    List<ClientQuotation> quotations,
    List<ClientPayment> payments,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Header Row
          _buildTabHeader(),
          
          const SizedBox(height: 12),
          
          // List Header (e.g. "8 Invoices") and Sort Dropdown
          _buildListHeader(invoices, quotations, payments),
          
          const SizedBox(height: 12),

        // Animated Tab Body Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(_activeTab),
            child: _buildTabBody(client, invoices, quotations, payments),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildListHeader(
    List<ClientInvoice> invoices,
    List<ClientQuotation> quotations,
    List<ClientPayment> payments,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int count = 0;
    String label = '';
    if (_activeTab == 'invoices') {
      count = invoices.length;
      label = 'invoices'.tr;
    } else if (_activeTab == 'quotations') {
      count = quotations.length;
      label = 'quotations'.tr;
    } else {
      count = invoices.length + payments.length;
      label = 'transactions'.tr;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
            elevation: 8,
            onSelected: (val) {
              setState(() {
                _sortOrder = val;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'desc',
                padding: EdgeInsets.zero,
                child: _buildSortMenuItem('desc', 'newest'.tr.isNotEmpty ? 'newest'.tr : 'Newest'),
              ),
              PopupMenuItem(
                value: 'asc',
                padding: EdgeInsets.zero,
                child: _buildSortMenuItem('asc', 'oldest'.tr.isNotEmpty ? 'oldest'.tr : 'Oldest'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.arrowUpDown,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _sortOrder == 'desc' 
                        ? ('newest'.tr.isNotEmpty ? 'newest'.tr : 'Newest')
                        : ('oldest'.tr.isNotEmpty ? 'oldest'.tr : 'Oldest'),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.displayLarge?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ],
              ),
            ),
        ),
      ],
      ),
    );
  }

  Widget _buildSortMenuItem(String value, String label) {
    final isSelected = _sortOrder == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : const Color(0xFFEFF6FF))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? Colors.blue.shade800.withValues(alpha: 0.5) : const Color(0xFFDBEAFE)) // blue-100
                  : (isDark ? Colors.grey.shade800 : const Color(0xFFF3F4F6)), // grey-100
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              value == 'desc' ? 'assets/SVG/newfirst.svg' : 'assets/SVG/oldfirst.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                isSelected
                    ? (isDark ? Colors.blue.shade300 : const Color(0xFF2563EB)) // blue-600
                    : (isDark ? Colors.grey.shade400 : const Color(0xFF6B7280)), // grey-500
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
          ),
          // Checkmark / Circle
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            color: isSelected 
                ? (isDark ? Colors.blue.shade400 : const Color(0xFF3B82F6)) // blue-500
                : (isDark ? Colors.grey.shade400 : const Color(0xFFD1D5DB)), // grey-300
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _buildTabButton('invoices', 'invoices'.tr.isNotEmpty ? 'invoices'.tr : 'Invoices'),
          _buildTabButton('quotations', 'quotations'.tr.isNotEmpty ? 'quotations'.tr : 'Quotations'),
          _buildTabButton('ledger', 'ledger'.tr.isNotEmpty ? 'ledger'.tr : 'Ledger'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabKey, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _activeTab == tabKey;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = tabKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive 
                ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.2) : const Color(0xFFEFF6FF))
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              right: tabKey != 'ledger' 
                  ? BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              label.isNotEmpty ? '${label[0].toUpperCase()}${label.substring(1)}' : label,
              style: TextStyle(
                color: isActive
                    ? AppColors.primary
                    : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToInvoiceDetails(ClientInvoice inv, Client client) async {
    Map<String, dynamic>? fullInvoice = inv.rawJson;
    if (fullInvoice == null || fullInvoice['items'] == null) {
      for (var x in _clientsController.allInvoices) {
        if (x is Map &&
            (x['_id'] == inv.id ||
                x['id'] == inv.id ||
                x['invoiceNumber'] == inv.invoiceNumber)) {
          fullInvoice = Map<String, dynamic>.from(x);
          break;
        }
      }
    }

    List<Map<String, dynamic>>? parsedItems;
    if (fullInvoice != null && fullInvoice['items'] is List) {
      parsedItems = List<Map<String, dynamic>>.from(
        (fullInvoice['items'] as List).map(
          (x) => x is Map ? Map<String, dynamic>.from(x) : <String, dynamic>{},
        ),
      );
    }

    final double invAmount =
        fullInvoice != null && fullInvoice['totalAmount'] != null
            ? (fullInvoice['totalAmount'] as num).toDouble()
            : inv.totalAmount;

    final String invDate =
        fullInvoice != null && fullInvoice['date'] != null
            ? fullInvoice['date'].toString()
            : inv.date;

    final String invStatus =
        fullInvoice != null && fullInvoice['status'] != null
            ? fullInvoice['status'].toString()
            : inv.status;

    final String? dueDate = fullInvoice?['dueDate']?.toString();
    final String? placeOfSupply =
        fullInvoice?['placeOfSupply']?.toString() ??
        (client.state.isNotEmpty ? client.state : null);
    final double? discountPercentage =
        fullInvoice?['discountPercentage'] != null
            ? (fullInvoice!['discountPercentage'] as num).toDouble()
            : null;
    final bool? gstEnabled =
        fullInvoice?['gstEnabled'] is bool
            ? fullInvoice!['gstEnabled'] as bool
            : null;
    final String? taxType = fullInvoice?['taxType']?.toString();
    final double? advancePayment =
        fullInvoice?['advancePayment'] != null
            ? (fullInvoice!['advancePayment'] as num).toDouble()
            : null;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsScreen(
          invoiceId:
              inv.invoiceNumber.isNotEmpty ? inv.invoiceNumber : inv.id,
          dbId: inv.id,
          clientName: client.name,
          amount: invAmount,
          date: invDate,
          status: invStatus,
          items: parsedItems,
          dueDate: dueDate,
          placeOfSupply: placeOfSupply,
          discountPercentage: discountPercentage,
          gstEnabled: gstEnabled,
          taxType: taxType,
          clientEmail: client.email.isNotEmpty ? client.email : null,
          clientPhone: client.phone.isNotEmpty ? client.phone : null,
          clientAddress: client.address.isNotEmpty ? client.address : null,
          clientGst: client.gstin.isNotEmpty ? client.gstin : null,
          advancePayment: advancePayment,
        ),
      ),
    );

    if (mounted) {
      _loadData();
    }
  }

  Future<void> _navigateToQuotationDetails(
    ClientQuotation quote,
    Client client,
  ) async {
    Map<String, dynamic>? fullQuote = quote.rawJson;
    if (fullQuote == null || fullQuote['items'] == null) {
      for (var x in _clientsController.allQuotations) {
        if (x is Map &&
            (x['_id'] == quote.id ||
                x['id'] == quote.id ||
                x['quoteNumber'] == quote.quotationNumber ||
                x['quotationNumber'] == quote.quotationNumber)) {
          fullQuote = Map<String, dynamic>.from(x);
          break;
        }
      }
    }

    List<Map<String, dynamic>>? parsedItems;
    if (fullQuote != null && fullQuote['items'] is List) {
      parsedItems = List<Map<String, dynamic>>.from(
        (fullQuote['items'] as List).map(
          (x) => x is Map ? Map<String, dynamic>.from(x) : <String, dynamic>{},
        ),
      );
    }

    final double quoteAmount =
        fullQuote != null &&
                (fullQuote['totalAmount'] ?? fullQuote['grandTotal']) != null
            ? ((fullQuote['totalAmount'] ?? fullQuote['grandTotal']) as num)
                .toDouble()
            : quote.grandTotal;

    final String quoteDate =
        fullQuote != null && fullQuote['date'] != null
            ? fullQuote['date'].toString()
            : quote.date;

    final String quoteStatus =
        fullQuote != null && fullQuote['status'] != null
            ? fullQuote['status'].toString()
            : quote.status;

    final String? validUntil = fullQuote?['validUntil']?.toString();
    final String? placeOfSupply =
        fullQuote?['placeOfSupply']?.toString() ??
        (client.state.isNotEmpty ? client.state : null);
    final double? discountPercentage =
        fullQuote?['discountPercentage'] != null
            ? (fullQuote!['discountPercentage'] as num).toDouble()
            : null;
    final bool? gstEnabled =
        fullQuote?['gstEnabled'] is bool
            ? fullQuote!['gstEnabled'] as bool
            : null;
    final String? taxType = fullQuote?['taxType']?.toString();
    final double? advancePayment =
        fullQuote?['advancePayment'] != null
            ? (fullQuote!['advancePayment'] as num).toDouble()
            : null;
    final String? templateId = fullQuote?['templateId']?.toString();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuotationDetailsScreen(
          quotationId:
              quote.quotationNumber.isNotEmpty
                  ? quote.quotationNumber
                  : quote.id,
          dbId: quote.id,
          clientName: client.name,
          amount: quoteAmount,
          date: quoteDate,
          status: quoteStatus,
          items: parsedItems,
          validUntil: validUntil,
          placeOfSupply: placeOfSupply,
          discountPercentage: discountPercentage,
          gstEnabled: gstEnabled,
          taxType: taxType,
          clientEmail: client.email.isNotEmpty ? client.email : null,
          clientPhone: client.phone.isNotEmpty ? client.phone : null,
          clientAddress: client.address.isNotEmpty ? client.address : null,
          advancePayment: advancePayment,
          templateId: templateId,
        ),
      ),
    );

    if (mounted) {
      _loadData();
    }
  }

  Widget _buildTabBody(
    Client client,
    List<ClientInvoice> invoices,
    List<ClientQuotation> quotations,
    List<ClientPayment> payments,
  ) {
    if (_activeTab == 'invoices') {
      return _buildInvoicesTable(invoices, client);
    } else if (_activeTab == 'quotations') {
      return _buildQuotationsTable(quotations, client);
    } else {
      return _buildLedgerView(invoices, payments, client);
    }
  }

  // --- INVOICES TAB ---
  Widget _buildInvoicesTable(List<ClientInvoice> invoices, Client client) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (invoices.isEmpty) {
      return _buildEmptyState(LucideIcons.fileText, 'no_invoices_found'.tr);
    }

    final sorted = List<ClientInvoice>.from(invoices);
    sorted.sort((a, b) {
      return _sortOrder == 'desc'
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date);
    });

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final inv = sorted[index];
        final formattedDate = _safeFormatDate(inv.date);
        
        final statusLower = inv.status.toLowerCase();
        
        Color cardBgColor = isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white;
        Color cardBorderColor = Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
        Color iconBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
        Color iconColor = isDark ? Colors.grey.shade300 : Colors.grey.shade600;
        Color pillBgColor = iconBgColor;
        Color pillTextColor = iconColor;
        Color pillDotColor = iconColor;
        
        if (statusLower == 'paid') {
          cardBgColor = isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white;
          iconBgColor = isDark ? Colors.green.shade900.withValues(alpha: 0.3) : const Color(0xFFECFDF5);
          iconColor = isDark ? Colors.green.shade400 : const Color(0xFF10B981);
          pillBgColor = iconBgColor;
          pillTextColor = iconColor;
          pillDotColor = iconColor;
        } else if (statusLower == 'overdue' || (inv.remainingAmount > 0 && statusLower != 'pending' && statusLower != 'partially paid')) {
          cardBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.1) : const Color(0xFFFEF2F2);
          cardBorderColor = isDark ? Colors.red.shade900.withValues(alpha: 0.3) : const Color(0xFFFECDD3);
          iconBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.3) : const Color(0xFFFEE2E2);
          iconColor = isDark ? Colors.red.shade400 : const Color(0xFFEF4444);
          pillBgColor = iconBgColor;
          pillTextColor = iconColor;
          pillDotColor = iconColor;
        } else if (statusLower == 'pending' || statusLower == 'unpaid') {
          cardBgColor = isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white;
          iconBgColor = isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : const Color(0xFFFFF7ED);
          iconColor = isDark ? Colors.orange.shade400 : const Color(0xFFF59E0B);
          pillBgColor = iconBgColor;
          pillTextColor = iconColor;
          pillDotColor = iconColor;
        } else if (statusLower == 'partially paid') {
          cardBgColor = isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white;
          iconBgColor = isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : const Color(0xFFEFF6FF);
          iconColor = isDark ? Colors.blue.shade400 : const Color(0xFF3B82F6);
          pillBgColor = iconBgColor;
          pillTextColor = iconColor;
          pillDotColor = iconColor;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToInvoiceDetails(inv, client),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorderColor),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/SVG/invoice.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              inv.invoiceNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: pillBgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: pillDotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLower == 'partially paid' ? 'PARTIALLY' : inv.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: pillTextColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Amount and Arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency.format(inv.totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inv.remainingAmount > 0
                            ? '${'due'.tr.trim()}: ${formatCurrency.format(inv.remainingAmount)}'
                            : ('settled'.tr.isNotEmpty ? '${'settled'.tr[0].toUpperCase()}${'settled'.tr.substring(1)}' : 'Settled'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: inv.remainingAmount > 0 ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- QUOTATIONS TAB ---
  Widget _buildQuotationsTable(List<ClientQuotation> quotations, Client client) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (quotations.isEmpty) {
      return _buildEmptyState(
        LucideIcons.fileSignature,
        'no_quotations_found'.tr,
      );
    }

    final sorted = List<ClientQuotation>.from(quotations);
    sorted.sort((a, b) {
      return _sortOrder == 'desc'
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date);
    });

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final quote = sorted[index];
        final formattedDate = _safeFormatDate(quote.date);

        final Color iconBgColor = isDark ? Colors.deepPurple.shade900.withValues(alpha: 0.3) : const Color(0xFFF3F0FF);
        final Color iconColor = isDark ? Colors.deepPurple.shade300 : const Color(0xFF4C1D95);
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToQuotationDetails(quote, client),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/SVG/qoutation.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote.quotationNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Amount
                  Text(
                    formatCurrency.format(quote.grandTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- STATEMENT (LEDGER) VIEW ---
  String _formatLedgerDateTime({required DateTime date, DateTime? createdAt}) {
    try {
      final localDate = date.toLocal();
      final datePart = DateFormat('d MMM yyyy').format(localDate);

      // Web logic (ClientProfile.jsx): time comes from createdAt
      DateTime? timeSource = createdAt?.toLocal();

      // If createdAt is missing but date itself has non-midnight hours/minutes
      if (timeSource == null &&
          (localDate.hour != 0 ||
              localDate.minute != 0 ||
              localDate.second != 0)) {
        timeSource = localDate;
      }

      if (timeSource != null) {
        final timePart =
            DateFormat('hh:mm a').format(timeSource).toLowerCase();
        return '$datePart · $timePart';
      }

      return datePart;
    } catch (_) {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  String _resolveCreator(Map<String, dynamic> entry) {
    String creator = entry['createdBy']?.toString().trim() ?? '';
    // If it's a 24-char ObjectId hex string, it is not a user name
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(creator)) {
      creator = '';
    }

    if (creator.isEmpty) {
      final clientIndex = _clientsController.clients.indexWhere(
        (c) => c.id == widget.clientId,
      );
      if (clientIndex != -1 &&
          _clientsController.clients[clientIndex].addedBy?.isNotEmpty == true) {
        final ab = _clientsController.clients[clientIndex].addedBy!.trim();
        if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(ab)) {
          creator = ab;
        }
      }
    }

    if (creator.isEmpty) {
      creator = 'Undefined';
    }

    return _capitalizeName(creator);
  }

  Widget _buildLedgerView(
    List<ClientInvoice> invoices,
    List<ClientPayment> payments,
    Client client,
  ) {
    final List<Map<String, dynamic>> rawEntries = [];

    // Map invoices for fast lookup by id
    final Map<String, ClientInvoice> invoiceMap = {
      for (var inv in invoices) inv.id: inv,
    };

    for (var inv in invoices) {
      final DateTime? invDate = DateTime.tryParse(inv.date);
      final DateTime? invCreated =
          inv.createdAt != null ? DateTime.tryParse(inv.createdAt!) : null;
      final DateTime effectiveDate = invDate ?? invCreated ?? DateTime.now();

      rawEntries.add({
        'key': '${inv.id}_inv',
        'id': inv.id,
        'type': 'invoice',
        'invoiceNumber': inv.invoiceNumber,
        'date': effectiveDate,
        'createdAt': invCreated,
        'debit': inv.totalAmount,
        'credit': 0.0,
        'remainingAmount': inv.remainingAmount,
        'status': inv.status,
        'createdBy': inv.createdBy,
        'note': null,
        'inv': inv,
      });
    }

    for (var pay in payments) {
      final DateTime? payDate = DateTime.tryParse(pay.date);
      final DateTime? payCreated =
          pay.createdAt != null ? DateTime.tryParse(pay.createdAt!) : null;
      final DateTime effectiveDate = payDate ?? payCreated ?? DateTime.now();

      // Clean note / reference matching ClientProfile.jsx (note: p.referenceNote)
      String note = pay.referenceNote.trim();

      // If referenceNote is empty, check if payment is tied to an invoice number
      if (note.isEmpty &&
          pay.invoiceNumber != null &&
          pay.invoiceNumber!.isNotEmpty) {
        final rawInv = pay.invoiceNumber!.trim();
        // If it's not a raw ObjectId hex, use it
        if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(rawInv)) {
          final cleanInv =
              rawInv.replaceAll('Invoice', '').replaceAll('#', '').trim();
          note = 'Invoice #$cleanInv';
        } else if (invoiceMap.containsKey(rawInv)) {
          // If it was an ObjectId that matches a known invoice, resolve its actual number
          final cleanInv =
              invoiceMap[rawInv]!.invoiceNumber.replaceAll('#', '').trim();
          note = 'Invoice #$cleanInv';
        }
      }

      rawEntries.add({
        'key': '${pay.id}_pay',
        'id': pay.id,
        'type': 'payment',
        'date': effectiveDate,
        'createdAt': payCreated,
        'debit': 0.0,
        'credit': pay.amount,
        'paymentMode':
            pay.paymentMode.isNotEmpty ? pay.paymentMode : 'Other',
        'createdBy': pay.createdBy,
        'note': note.isNotEmpty ? note : null,
      });
    }

    if (rawEntries.isEmpty) {
      return _buildEmptyState(
        LucideIcons.calculator,
        'no_ledger_transactions_recorded'.tr,
      );
    }

    // Step 2: Sort oldest → newest (First by Date, then by Exact Time) matching ClientProfile.jsx
    rawEntries.sort((a, b) {
      final dateA = (a['date'] as DateTime).toLocal();
      final dateB = (b['date'] as DateTime).toLocal();
      final dayA = DateTime(dateA.year, dateA.month, dateA.day);
      final dayB = DateTime(dateB.year, dateB.month, dateB.day);
      final cmp = dayA.compareTo(dayB);
      if (cmp != 0) return cmp;
      final createdA = (a['createdAt'] as DateTime?)?.toLocal() ?? dateA;
      final createdB = (b['createdAt'] as DateTime?)?.toLocal() ?? dateB;
      return createdA.compareTo(createdB);
    });

    double running = 0.0;
    final List<Map<String, dynamic>> withBalance = [];
    for (var entry in rawEntries) {
      running += (entry['debit'] as double) - (entry['credit'] as double);
      withBalance.add({...entry, 'balance': running});
    }

    // Sort according to user preference (_sortOrder: desc = newest first)
    final displayEntries = _sortOrder == 'desc'
        ? withBalance.reversed.toList()
        : withBalance;

    return _buildLedgerCardsList(displayEntries, client);
  }

  Widget _buildLedgerCardsList(
    List<Map<String, dynamic>> displayEntries,
    Client client,
  ) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayEntries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = displayEntries[index];
        return _buildLedgerCard(entry, client);
      },
    );
  }

  Widget _buildLedgerCard(Map<String, dynamic> entry, Client client) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final isInvoice = entry['type'] == 'invoice';
    final isDebit = (entry['debit'] as double) > 0;
    final double debit = entry['debit'] as double;
    final double credit = entry['credit'] as double;
    final double amount = isDebit ? debit : credit;
    final double balanceVal = entry['balance'] as double;
    final DateTime dateObj = entry['date'] as DateTime;
    final DateTime? createdObj = entry['createdAt'] as DateTime?;
    final String formattedDateTime = _formatLedgerDateTime(
      date: dateObj,
      createdAt: createdObj,
    );

    // Title
    final String title = isInvoice
        ? 'Invoice #${(entry['invoiceNumber'] ?? '').toString().replaceAll('#', '').trim()}'
        : 'Payment (${entry['paymentMode'] ?? 'Other'})';

    // Creator & Note
    final String creator = _resolveCreator(entry);
    final String? noteText = entry['note'] as String?;

    // Badge
    String badgeLabel;
    Color badgeBg;
    Color badgeColor;

    if (isInvoice) {
      final remaining = (entry['remainingAmount'] as double?) ?? 0.0;
      final isPaid = remaining <= 0 &&
          (entry['status']?.toString().toLowerCase() == 'paid');
      badgeLabel = isPaid ? 'Paid' : 'Due';
      badgeBg = isPaid
          ? (isDark
              ? Colors.green.shade900.withValues(alpha: 0.3)
              : const Color(0xFFDCFCE7))
          : (isDark
              ? Colors.red.shade900.withValues(alpha: 0.3)
              : const Color(0xFFFEF2F2));
      badgeColor =
          isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    } else {
      badgeLabel = 'Received';
      badgeBg = isDark
          ? Colors.green.shade900.withValues(alpha: 0.3)
          : const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF16A34A);
    }

    final cardWidget = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Column(
        children: [
          // Top Row: Icon + Title/Details + Amount/Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Box (Red Document for Invoice, Green Wallet for Payment)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isInvoice
                      ? (isDark
                          ? Colors.red.shade900.withValues(alpha: 0.25)
                          : const Color(0xFFFEF2F2))
                      : (isDark
                          ? Colors.green.shade900.withValues(alpha: 0.25)
                          : const Color(0xFFF0FDF4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    isInvoice
                        ? 'assets/SVG/invoice.svg'
                        : 'assets/SVG/wallet.svg',
                    width: 19,
                    height: 19,
                    colorFilter: ColorFilter.mode(
                      isInvoice
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF16A34A),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitles (Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Date & Time Row
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/SVG/calendernormal.svg',
                          width: 11,
                          height: 11,
                          colorFilter: ColorFilter.mode(
                            isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formattedDateTime,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Note / Description Row (matching ClientProfile.jsx)
                    if (noteText != null && noteText.isNotEmpty) ...[
                      const SizedBox(height: 2.5),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/SVG/file.svg',
                            width: 11,
                            height: 11,
                            colorFilter: ColorFilter.mode(
                              isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              noteText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Dynamic Creator Tag (By: ...)
                    const SizedBox(height: 2.5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/SVG/userround.svg',
                          width: 11,
                          height: 11,
                          colorFilter: ColorFilter.mode(
                            isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'By: ',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            creator,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount & Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isInvoice
                        ? formatCurrency.format(amount)
                        : '+${formatCurrency.format(amount)}',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isInvoice
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom Strip (Debit, Credit, Balance)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 1. Debit (Billed)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debit (Billed)',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isDebit ? formatCurrency.format(debit) : '-',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Divider 1
                Container(
                  height: 26,
                  width: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // 2. Credit (Received)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credit (Received)',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        !isDebit ? formatCurrency.format(credit) : '-',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: !isDebit
                              ? const Color(0xFF16A34A)
                              : textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Divider 2
                Container(
                  height: 26,
                  width: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // 3. Balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        balanceVal == 0
                            ? '₹0.00'
                            : (balanceVal > 0
                                ? '${formatCurrency.format(balanceVal)} (Due)'
                                : '${formatCurrency.format(balanceVal.abs())} (Advance)'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: balanceVal == 0
                              ? textColor
                              : (balanceVal > 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF2563EB)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isInvoice && entry['inv'] is ClientInvoice) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _navigateToInvoiceDetails(entry['inv'] as ClientInvoice, client),
          borderRadius: BorderRadius.circular(18),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }

  Widget _buildEmptyState(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 150,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS LOGIC ---
  void _showCallSmsDialog(
    Client client,
    double balance,
    double billed,
    double paid,
    List<ClientInvoice> invoices,
  ) {
    if (client.phone.trim().isEmpty) {
      Get.snackbar(
        'phone_missing'.tr,
        'phone_not_configured'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        colorText: AppColors.error,
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.user,
                        color: isDark ? Colors.blue.shade300 : const Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'contact_client'.tr} ${client.name}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).textTheme.displayLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'contact_method_prompt'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          final balanceText = balance > 0
                              ? 'outstanding_due_rs'.tr +
                                    NumberFormat.decimalPattern('en_IN').format(balance)
                              : balance < 0
                              ? 'advance_rs'.tr +
                                    NumberFormat.decimalPattern('en_IN').format(balance.abs())
                              : 'outstanding_nil'.tr;
                          final message =
                              '${'hello_greeting'.tr}${client.name},\nHere is your account summary:\nTotal Billed: Rs.${NumberFormat.decimalPattern('en_IN').format(billed)}\nTotal Paid: Rs.${NumberFormat.decimalPattern('en_IN').format(paid)}\n$balanceText\n\nRegards,\nAuriva BMS';
                          final cleanPhone = client.phone.replaceAll(RegExp(r'[^0-9+]'), '');
                          final uri = Uri(
                            scheme: 'sms',
                            path: cleanPhone,
                            queryParameters: <String, String>{'body': message},
                          );
                          _launchURL(uri.toString(), message);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/SVG/sms.svg',
                                width: 16,
                                height: 16,
                                colorFilter: ColorFilter.mode(
                                  isDark ? Colors.blue.shade300 : const Color(0xFF0052CC), 
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SMS',
                                style: TextStyle(
                                  color: isDark ? Colors.blue.shade300 : const Color(0xFF0052CC),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          final cleanPhone = client.phone.replaceAll(RegExp(r'[^0-9+]'), '');
                          final uri = Uri(scheme: 'tel', path: cleanPhone);
                          _launchURL(uri.toString(), '');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.phone, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'call'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareWhatsApp(
    Client client,
    double balance,
    double billed,
    double paid,
    List<ClientInvoice> invoices,
  ) {
    final balanceText = balance > 0
        ? '*Outstanding Due:* ₹${NumberFormat.decimalPattern('en_IN').format(balance)}'
        : balance < 0
        ? '*Advance (Jama):* ₹${NumberFormat.decimalPattern('en_IN').format(balance.abs())}'
        : '*Outstanding Due:* Nil (Account Settled)';

    String lastInvoiceText = '';
    if (invoices.isNotEmpty) {
      final sortedInvs = List<ClientInvoice>.from(invoices);
      sortedInvs.sort((a, b) => b.date.compareTo(a.date));
      final lastInv = sortedInvs.first;
      lastInvoiceText =
          '\n\n*Last Invoice Details:*\n'
          'Invoice No: #${lastInv.invoiceNumber}\n'
          'Date: ${lastInv.date}\n'
          'Bill Amount: ₹${NumberFormat.decimalPattern('en_IN').format(lastInv.totalAmount)}\n'
          'Unpaid on this bill: ₹${NumberFormat.decimalPattern('en_IN').format(lastInv.remainingAmount)}';
    }

    final message =
        'Hello ${client.name},\n\n'
        'Here is your current account summary with us:\n\n'
        '*Total Billed:* ₹${NumberFormat.decimalPattern('en_IN').format(billed)}\n'
        '*Total Paid:* ₹${NumberFormat.decimalPattern('en_IN').format(paid)}\n'
        '$balanceText$lastInvoiceText\n\n'
        'Please let us know if you have any questions.\n\n'
        '*Regards,*\n*Auriva BMS*';

    final encodedMessage = Uri.encodeComponent(message);
    final cleanPhone = client.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneNo = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final urlString = 'https://wa.me/$phoneNo?text=$encodedMessage';

    _launchURL(urlString, message);
  }

  void _sendEmailSummary(Client client) async {
    if (client.email.trim().isEmpty) {
      Get.snackbar(
        'Email Missing',
        'This client does not have an email address configured.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        colorText: AppColors.error,
      );
      return;
    }

    setState(() {
      _isSendingEmail = true;
    });

    final success = await _clientsController.sendAccountSummary(client.id);

    if (mounted) {
      setState(() {
        _isSendingEmail = false;
      });
      if (success) {
        Get.snackbar(
          'Email Sent',
          'Account summary email sent to ${client.email} successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          colorText: AppColors.success,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to send account summary email. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
      }
    }
  }

  void _syncLedger(String clientId) async {
    setState(() {
      _isSyncing = true;
    });

    final success = await _clientsController.syncLedger(clientId);

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });
      final isDark = Theme.of(context).brightness == Brightness.dark;
      if (success) {
        Get.snackbar(
          'Ledger Synced',
          'Ledger records matched with all billing history.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: isDark
              ? Colors.blue.shade900.withValues(alpha: 0.2)
              : Colors.blue.shade50,
          colorText: isDark ? Colors.blue.shade300 : Colors.blue.shade800,
        );
      } else {
        Get.snackbar(
          'Sync Failed',
          'Failed to sync ledger records. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
      }
    }
  }

  Future<void> _launchURL(String urlString, String fallbackText) async {
    final uri = Uri.parse(urlString);
    try {
      // Bypassing canLaunchUrl due to Android package visibility restrictions (API 30+)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw 'Could not launch URL';
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      final isDark = Theme.of(context).brightness == Brightness.dark;
      Get.snackbar(
        'Copied to Clipboard',
        'Could not launch WhatsApp. Summary text copied to clipboard instead.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: isDark
            ? Colors.orange.shade900.withValues(alpha: 0.2)
            : Colors.orange.shade50,
        colorText: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
      );
    }
  }
  Widget _getPaymentModeIcon(String mode) {
    switch (mode) {
      case 'UPI':
        return SvgPicture.asset('assets/SVG/upi.svg', width: 20, height: 20);
      case 'Bank Transfer':
        return SvgPicture.asset('assets/SVG/bank.svg', width: 20, height: 20);
      case 'Cash':
        return SvgPicture.asset('assets/SVG/cash.svg', width: 20, height: 20);
      case 'Cheque':
        return SvgPicture.asset('assets/SVG/cheque.svg', width: 20, height: 20);
      default:
        return const Icon(LucideIcons.creditCard, size: 20, color: Colors.grey);
    }
  }

  void _showPaymentModeSelector(String currentMode, Function(String) onSelected) {
    final modes = ['UPI', 'Bank Transfer', 'Cash', 'Cheque'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Payment Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          color: isDark ? Colors.white : Colors.black87,
                          onPressed: () => Navigator.pop(context),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: modes.length,
                  itemBuilder: (context, index) {
                    final mode = modes[index];
                    final isSelected = mode == currentMode;
                    return InkWell(
                      onTap: () {
                        onSelected(mode);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF)) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            _getPaymentModeIcon(mode),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                mode,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: Theme.of(context).textTheme.displayLarge?.color,
                                ),
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade400,
                                  width: isSelected ? 6 : 1.5,
                                ),
                                color: isSelected ? Colors.white : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- COLLECT PAYMENT DIALOG ---
  void _showCollectPaymentDialog(Client client) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String payMode = 'UPI';
    DateTime payDate = DateTime.now();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final Color bgColor = Theme.of(context).cardTheme.color ?? Theme.of(context).scaffoldBackgroundColor;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Grabber
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.indianRupee,
                                  color: Color(0xFF3B82F6),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Collect Payment',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).textTheme.displayLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Record a payment received from this client',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.x, size: 20),
                                color: isDark ? Colors.white : Colors.black87,
                                onPressed: isSaving ? null : () => Navigator.pop(context),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppInputField(
                                label: 'AMOUNT RECEIVED (₹) *',
                                hintText: '0',
                                controller: amountController,
                                enabled: !isSaving,
                                keyboardType: TextInputType.number,
                                prefixIcon: const Icon(LucideIcons.indianRupee, size: 18, color: Colors.grey),
                                fontSize: 14,
                                filled: true,
                                fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                contentPaddingVertical: 12.0,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                                          child: RichText(
                                            text: TextSpan(
                                              text: 'PAYMENT MODE ',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                                letterSpacing: 0.5,
                                              ),
                                              children: const [
                                                TextSpan(
                                                  text: '*',
                                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: isSaving
                                              ? null
                                              : () {
                                                  _showPaymentModeSelector(payMode, (selected) {
                                                    setSheetState(() {
                                                      payMode = selected;
                                                    });
                                                  });
                                                },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                              border: Border.all(
                                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                _getPaymentModeIcon(payMode),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    payMode,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: Theme.of(context).textTheme.displayLarge?.color,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  LucideIcons.chevronDown,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                                          child: RichText(
                                            text: TextSpan(
                                              text: 'DATE ',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                                letterSpacing: 0.5,
                                              ),
                                              children: const [
                                                TextSpan(
                                                  text: '*',
                                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: isSaving
                                              ? null
                                              : () async {
                                                  final picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: payDate,
                                                    firstDate: DateTime(2020),
                                                    lastDate: DateTime(2030),
                                                    builder: (context, child) {
                                                      return Theme(
                                                        data: Theme.of(context).copyWith(
                                                          colorScheme: isDark
                                                              ? const ColorScheme.dark(
                                                                  primary: AppColors.primary,
                                                                  onPrimary: Colors.white,
                                                                  surface: Color(0xFF1E293B),
                                                                  onSurface: Colors.white,
                                                                )
                                                              : const ColorScheme.light(
                                                                  primary: AppColors.primary,
                                                                  onPrimary: Colors.white,
                                                                  surface: Colors.white,
                                                                  onSurface: AppColors.textPrimary,
                                                                ),
                                                        ),
                                                        child: child!,
                                                      );
                                                    },
                                                  );
                                                  if (picked != null) {
                                                    setSheetState(() {
                                                      payDate = picked;
                                                    });
                                                  }
                                                },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                              border: Border.all(
                                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  DateFormat('dd/MM/yyyy').format(payDate),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context).textTheme.displayLarge?.color,
                                                  ),
                                                ),
                                                SvgPicture.asset(
                                                  'assets/SVG/calendernormal.svg',
                                                  width: 16,
                                                  height: 16,
                                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AppInputField(
                                label: 'REMARKS / NOTES',
                                hintText: 'Txn ID, reference, e.g. Payment for INV-0458...',
                                controller: noteController,
                                enabled: !isSaving,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SvgPicture.asset(
                                    'assets/SVG/edit.svg',
                                    width: 18,
                                    height: 18,
                                    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                  ),
                                ),
                                fontSize: 14,
                                filled: true,
                                fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                contentPaddingVertical: 12.0,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      
                      // Footer Buttons
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border(
                            top: BorderSide(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'cancel'.tr,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.displayLarge?.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : () async {
                                  final amt = double.tryParse(amountController.text.trim());
                                  if (amt == null || amt <= 0) {
                                    Get.snackbar('error'.tr, 'amount_greater_than_zero'.tr, backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
                                    return;
                                  }

                                  setSheetState(() => isSaving = true);

                                  final success = await _clientsController.collectPayment(
                                    client.id,
                                    amt,
                                    _apiDateFormat.format(payDate),
                                    payMode,
                                    noteController.text.trim(),
                                  );

                                  if (context.mounted) {
                                    setSheetState(() => isSaving = false);
                                  }

                                  if (success) {
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    Get.snackbar(
                                      'payment_saved'.tr,
                                      'collected_payment_success'.trParams({
                                        'amount': formatCurrency.format(amt),
                                      }),
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                                      colorText: AppColors.success,
                                    );
                                  } else {
                                    Get.snackbar(
                                      'error'.tr,
                                      'failed_save_payment'.tr,
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                      colorText: AppColors.error,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSaving 
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                      )
                                    : const Text(
                                        'Save Record',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
          },
        );
      },
    );
  }

  // --- EDIT CLIENT DIALOG ---
  void _showEditClientDialog(Client client) {
    final nameController = TextEditingController(text: client.name);
    final emailController = TextEditingController(text: client.email);
    final phoneController = TextEditingController(text: client.phone);
    final gstinController = TextEditingController(text: client.gstin);
    final addressController = TextEditingController(text: client.address);
    String selectedState = client.state.isNotEmpty ? client.state : '';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final Color bgColor = Theme.of(context).cardTheme.color ?? Theme.of(context).scaffoldBackgroundColor;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Grabber
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'edit_client_details'.tr,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).textTheme.displayLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Update client information',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.x, size: 20),
                                color: isDark ? Colors.white : Colors.black87,
                                onPressed: isSaving ? null : () => Navigator.pop(context),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppInputField(
                                label: 'BUSINESS NAME *',
                                hintText: 'Acme Corp',
                                controller: nameController,
                                enabled: !isSaving,
                                prefixIcon: SvgPicture.asset(
                                  'assets/SVG/building.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                                fontSize: 14,
                                filled: true,
                                fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                contentPaddingVertical: 12.0,
                              ),
                              const SizedBox(height: 16),
                              AppInputField(
                                label: 'EMAIL ADDRESS',
                                hintText: 'name@company.com',
                                keyboardType: TextInputType.emailAddress,
                                controller: emailController,
                                enabled: !isSaving,
                                prefixIcon: SvgPicture.asset(
                                  'assets/SVG/mail.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                                fontSize: 14,
                                filled: true,
                                fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                contentPaddingVertical: 12.0,
                              ),
                              const SizedBox(height: 16),
                              AppInputField(
                                label: 'PHONE',
                                hintText: '9898989898',
                                keyboardType: TextInputType.phone,
                                controller: phoneController,
                                enabled: !isSaving,
                                prefixIcon: SvgPicture.asset(
                                  'assets/SVG/call.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                                fontSize: 14,
                                filled: true,
                                fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                contentPaddingVertical: 12.0,
                              ),
                              const SizedBox(height: 16),
                              AppInputField(
                                label: 'GSTIN',
                                hintText: '22AAAAA0000A1Z5',
                                controller: gstinController,
                                enabled: !isSaving,
                                prefixIcon: SvgPicture.asset(
                                  'assets/SVG/gst.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                                fontSize: 14,
                                filled: true,
                                fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                contentPaddingVertical: 12.0,
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                                    child: Text(
                                      'STATE / UT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: isSaving ? null : () {
                                      StatePickerBottomSheet.show(
                                        context,
                                        initialSelectedState: selectedState,
                                        onStateSelected: (val) {
                                          setSheetState(() {
                                            selectedState = val;
                                          });
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/SVG/location.svg',
                                            width: 18,
                                            height: 18,
                                            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              selectedState.isEmpty ? 'Select State' : selectedState,
                                              style: TextStyle(
                                                color: selectedState.isEmpty ? Colors.grey.shade500 : Theme.of(context).textTheme.displayLarge?.color,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const Icon(LucideIcons.chevronDown, size: 18, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AppInputField(
                                label: 'BILLING ADDRESS',
                                hintText: 'Full billing address...',
                                controller: addressController,
                                enabled: !isSaving,
                                prefixIcon: SvgPicture.asset(
                                  'assets/SVG/location.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                ),
                                maxLines: 3,
                                fontSize: 14,
                                filled: true,
                                fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                                contentPaddingVertical: 12.0,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      
                      // Footer Buttons
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border(
                            top: BorderSide(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'cancel'.tr,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.displayLarge?.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : () async {
                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();
                                  final phone = phoneController.text.trim();
                                  final address = addressController.text.trim();

                                  if (name.isEmpty || email.isEmpty || phone.isEmpty || selectedState.isEmpty || address.isEmpty) {
                                    Get.snackbar('error'.tr, 'Please fill all fields except GSTIN', backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
                                    return;
                                  }

                                  setSheetState(() => isSaving = true);

                                  final success = await _clientsController.updateClient(
                                    client.id,
                                    name,
                                    email,
                                    phone,
                                    gstinController.text.trim(),
                                    selectedState,
                                    address,
                                  );

                                  if (context.mounted) {
                                    setSheetState(() => isSaving = false);
                                  }

                                  if (success) {
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    Get.snackbar(
                                      'client_updated'.tr,
                                      'changes_saved_success'.tr,
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                                      colorText: AppColors.success,
                                    );
                                  } else {
                                    Get.snackbar(
                                      'error'.tr,
                                      'failed_update_client'.tr,
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                      colorText: AppColors.error,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSaving 
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                      )
                                    : Text(
                                        'save_changes'.tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
          },
        );
      },
    );
  }

  // --- DELETE CLIENT DIALOG ---
  void _showDeleteConfirmation(Client client) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.red.shade900.withValues(alpha: 0.15)
                          : Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.red.shade900.withValues(alpha: 0.3)
                            : Colors.red.shade100,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.trash2,
                      color: Colors.red.shade500,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'delete_client'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'delete_client_warning'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'cancel'.tr,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                setDialogState(() {
                                  isDeleting = true;
                                });

                                final success = await _clientsController
                                    .deleteClient(client.id);

                                if (context.mounted) {
                                  setDialogState(() {
                                    isDeleting = false;
                                  });
                                }

                                if (success) {
                                  if (!context.mounted) return;
                                  Navigator.pop(context); // Pop Dialog
                                  Get.back(); // Pop Details Screen back to directory
                                  Get.snackbar(
                                    'client_deleted'.tr,
                                    'client_removed_from_directory'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red.shade50,
                                    colorText: Colors.red.shade700,
                                  );
                                } else {
                                  Get.snackbar(
                                    'error'.tr,
                                    'failed_delete_client'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.error
                                        .withValues(alpha: 0.1),
                                    colorText: AppColors.error,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'delete'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

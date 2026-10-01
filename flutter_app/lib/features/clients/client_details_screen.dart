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
import 'clients_controller.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
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

    // Fetch payments dynamically on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clientsController.fetchPayments(widget.clientId);
    });
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
        if (clientIndex == -1) {
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

        final client = _clientsController.clients[clientIndex];
        final invoices = _clientsController.clientInvoices[client.id] ?? [];
        final quotations = _clientsController.clientQuotations[client.id] ?? [];
        final payments = _clientsController.clientPayments[client.id] ?? [];

        final totalBilled = invoices.fold<double>(
          0.0,
          (sum, inv) => sum + inv.totalAmount,
        );
        final totalPaid = payments.fold<double>(
          0.0,
          (sum, pay) => sum + pay.amount,
        );
        final balance = totalBilled - totalPaid;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
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

  Widget _buildTabBody(
    Client client,
    List<ClientInvoice> invoices,
    List<ClientQuotation> quotations,
    List<ClientPayment> payments,
  ) {
    if (_activeTab == 'invoices') {
      return _buildInvoicesTable(invoices);
    } else if (_activeTab == 'quotations') {
      return _buildQuotationsTable(quotations);
    } else {
      return _buildLedgerView(invoices, payments);
    }
  }

  // --- INVOICES TAB ---
  Widget _buildInvoicesTable(List<ClientInvoice> invoices) {
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

        return Container(
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
        );
      },
    );
  }

  // --- QUOTATIONS TAB ---
  Widget _buildQuotationsTable(List<ClientQuotation> quotations) {
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
        
        return Container(
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
        );
      },
    );
  }

  // --- STATEMENT (LEDGER) VIEW ---
  Widget _buildLedgerView(
    List<ClientInvoice> invoices,
    List<ClientPayment> payments,
  ) {
    // Build ledger entries
    final List<Map<String, dynamic>> rawEntries = [];
    for (var inv in invoices) {
      rawEntries.add({
        'key': '${inv.id}_inv',
        'date': DateTime.tryParse(inv.date) ?? DateTime.now(),
        'desc': '${'invoice'.tr} #${inv.invoiceNumber}',
        'debit': inv.totalAmount,
        'credit': 0.0,
        'note': null,
      });
    }
    for (var pay in payments) {
      rawEntries.add({
        'key': '${pay.id}_pay',
        'date': DateTime.tryParse(pay.date) ?? DateTime.now(),
        'desc':
            '${'payment'.tr} (${pay.paymentMode.toLowerCase().replaceAll(' ', '_').tr})',
        'debit': 0.0,
        'credit': pay.amount,
        'note': pay.referenceNote,
      });
    }

    if (rawEntries.isEmpty) {
      return _buildEmptyState(
        LucideIcons.calculator,
        'no_ledger_transactions_recorded'.tr,
      );
    }

    // Sort oldest to newest to compute running balance
    rawEntries.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    double running = 0.0;
    final List<Map<String, dynamic>> withBalance = [];
    for (var entry in rawEntries) {
      running += (entry['debit'] as double) - (entry['credit'] as double);
      withBalance.add({...entry, 'balance': running});
    }

    // Re-sort based on user selection
    final displayEntries = _sortOrder == 'desc'
        ? withBalance.reversed.toList()
        : withBalance;

    // Return the desktop table view wrapped in a horizontal scroll for both mobile and desktop
    return _buildDesktopLedgerTable(displayEntries);
  }

  // Responsive: Mobile List Style
  Widget _buildMobileLedgerList(List<Map<String, dynamic>> entries) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (context, index) => Divider(
        color: Theme.of(context).colorScheme.outline,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final dateObj = entry['date'] as DateTime;
        final dateStr = _displayDateFormat.format(dateObj);
        final isDebit = (entry['debit'] as double) > 0;
        final amount = isDebit
            ? entry['debit'] as double
            : entry['credit'] as double;
        final balanceVal = entry['balance'] as double;
        final isAdvance = balanceVal < 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              // Transaction type Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDebit
                      ? (isDark
                            ? Colors.blue.shade900.withValues(alpha: 0.3)
                            : Colors.blue.shade50)
                      : (isDark
                            ? Colors.green.shade900.withValues(alpha: 0.3)
                            : Colors.green.shade50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDebit ? LucideIcons.fileText : LucideIcons.arrowDownLeft,
                  color: isDebit ? Colors.blue.shade500 : AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['desc'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).textTheme.displayLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                          ),
                        ),
                        if (entry['note'] != null &&
                            (entry['note'] as String).isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry['note'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount and Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isDebit
                        ? formatCurrency.format(amount)
                        : '+ ${formatCurrency.format(amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDebit
                          ? ((Theme.of(context).textTheme.displayLarge?.color ?? Colors.black))
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    balanceVal == 0
                        ? 'settled'.tr
                        : '${'balance'.tr.toLowerCase().capitalizeFirst}: ${formatCurrency.format(balanceVal.abs())}${isAdvance ? ' (${'advance'.tr})' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: balanceVal == 0
                          ? AppColors.success
                          : (isAdvance
                                ? Colors.blue.shade500
                                : (isDark
                                      ? Colors.red.shade400
                                      : const Color(0xFFE11D48))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Responsive: Desktop/Tablet Table Style
  Widget _buildDesktopLedgerTable(List<Map<String, dynamic>> displayEntries) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayEntries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = displayEntries[index];
        final dateObj = entry['date'] as DateTime;
        final dateStr = '${dateObj.day.toString().padLeft(2, '0')}/${dateObj.month.toString().padLeft(2, '0')}/${dateObj.year}';
        
        final isDebit = (entry['debit'] as double) > 0;
        final amount = isDebit ? (entry['debit'] as double) : (entry['credit'] as double);
        final balanceVal = entry['balance'] as double;
        final isSettled = balanceVal == 0;
        final isAdvance = balanceVal < 0;
        
        final String balanceText = '${formatCurrency.format(balanceVal.abs())} ${isSettled ? '(Settled)' : (isAdvance ? '(Advance)' : '(Due)')}';
        final Color balanceColor = isSettled 
            ? AppColors.success 
            : (isAdvance ? Colors.blue.shade500 : (isDark ? Colors.red.shade400 : const Color(0xFFDC2626)));
        
        String descText = entry['desc'] as String;
        if (descText.toLowerCase().contains('invoice')) {
            descText = descText.toUpperCase();
        }
        
        String subtitle = '';
        if (entry['note'] != null && (entry['note'] as String).isNotEmpty) {
           subtitle = entry['note'] as String;
        } else {
           if (isDebit) {
               subtitle = 'Invoice generated';
           } else {
               subtitle = 'Advance payment';
           }
        }
    
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side (Description & Dates)
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descText,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Theme.of(context).textTheme.displayLarge?.color),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Vertical Divider
              Container(
                width: 1, 
                height: 55, // Fixed height to prevent unbounded errors
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, 
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              
              // Right Side (Amount & Balance)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      formatCurrency.format(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isDebit ? (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black) : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatCurrency.format(balanceVal.abs()),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: balanceColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSettled 
                            ? (isDark ? Colors.green.shade900.withValues(alpha: 0.3) : const Color(0xFFDCFCE7))
                            : (isAdvance ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : const Color(0xFFDBEAFE))
                                         : (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : const Color(0xFFFEE2E2))),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSettled ? 'Settled' : (isAdvance ? 'Advance' : 'Due'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

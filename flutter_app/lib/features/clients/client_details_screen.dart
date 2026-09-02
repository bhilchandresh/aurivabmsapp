// ignore_for_file: unused_field, unused_local_variable, unused_element
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_input_field.dart';
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
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: Theme.of(context).textTheme.displayLarge?.color,
            size: 20,
          ),
          onPressed: () => Get.back(),
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
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 16),

              // Stats Row (Paid, Billed, Balance)
              _buildAnimatedWidget(
                1,
                _buildStatsRow(balance, totalBilled, totalPaid, client.id),
              ),
              const SizedBox(height: 24),

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
          LucideIcons.mail,
          client.email.isNotEmpty ? client.email : 'no_email_added'.tr,
          Colors.blue.shade400,
          subtextColor,
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          LucideIcons.phone,
          client.phone.isNotEmpty ? client.phone : 'no_phone_added'.tr,
          Colors.green.shade500,
          subtextColor,
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          LucideIcons.mapPin,
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

    final Widget actionsList = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Call / SMS Action
        _buildActionButton(
          icon: LucideIcons.phoneCall,
          label: 'call_sms'.tr,
          backgroundColor: Colors.blue.shade900.withValues(alpha: isDark ? 0.15 : 0.1,
          ),
          foregroundColor: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
          borderColor: Colors.blue.shade900.withValues(alpha: isDark ? 0.4 : 0.3),
          onTap: () =>
              _showCallSmsDialog(client, balance, billed, paid, invoices),
        ),
        // WhatsApp Action
        _buildActionButton(
          icon: LucideIcons.messageSquare,
          label: 'whatsapp'.tr,
          backgroundColor: const Color(
            0xFF25D366,
          ).withValues(alpha: isDark ? 0.15 : 0.1),
          foregroundColor: isDark
              ? const Color(0xFF4ADE80)
              : const Color(0xFF128C7E),
          borderColor: const Color(0xFF25D366).withValues(alpha: isDark ? 0.4 : 0.3),
          onTap: () => _shareWhatsApp(client, balance, billed, paid, invoices),
        ),
        // Email Action
        _buildActionButton(
          icon: LucideIcons.mail,
          label: 'email'.tr,
          backgroundColor: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.05),
          foregroundColor: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
          borderColor: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.2),
          isLoading: _isSendingEmail,
          onTap: () => _sendEmailSummary(client),
        ),
        // Edit Action
        _buildActionButton(
          icon: LucideIcons.edit3,
          label: 'edit'.tr,
          backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
          foregroundColor: isDark
              ? const Color(0xFFE2E8F0)
              : Colors.grey.shade700,
          borderColor: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
          onTap: () => _showEditClientDialog(client),
        ),
        // Delete Action
        _buildActionButton(
          icon: LucideIcons.trash2,
          label: 'delete'.tr,
          backgroundColor: isDark
              ? Colors.red.shade900.withValues(alpha: 0.15)
              : Colors.red.shade50,
          foregroundColor: isDark ? Colors.red.shade400 : Colors.red.shade600,
          borderColor: Colors.red.shade900.withValues(alpha: isDark ? 0.4 : 0.1),
          onTap: () => _showDeleteConfirmation(client),
        ),
        // Collect Payment Action
        ElevatedButton.icon(
          onPressed: () => _showCollectPaymentDialog(client),
          icon: const Icon(LucideIcons.indianRupee, size: 14),
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
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _capitalizeName(client.name),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                infoDetails,
                const SizedBox(height: 20),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 16),
                actionsList,
              ],
            ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color iconColor,
    Color textColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
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
    required IconData icon,
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
          mainAxisSize: MainAxisSize.min,
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
              Icon(icon, size: 14, color: foregroundColor),
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
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor ?? Colors.white,
        borderColor: Theme.of(context).colorScheme.outline,
      ),
      _buildStatCard(
        title: 'total_billed'.tr,
        amount: billed,
        color: Theme.of(context).textTheme.displayLarge?.color ?? Colors.black,
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor ?? Colors.white,
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
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: c,
              ),
            )
            .toList(),
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
      padding: const EdgeInsets.all(16),
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
                    fontSize: 10,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency.format(amount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Header Row
          _buildTabHeader(),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline,
          ),

          // Animated Tab Body Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
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
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final Widget tabButtonsRow = Row(
      children: [
        _buildTabButton('invoices', 'invoices'.tr),
        _buildTabButton('quotations', 'quotations'.tr),
        _buildTabButton('ledger', 'ledger'.tr),
      ],
    );

    final Widget sortDropdownRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMobile
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.arrowUpDown,
            size: 12,
            color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
          ),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOrder,
              dropdownColor: Theme.of(context).cardTheme.color,
              icon: Icon(
                LucideIcons.chevronDown,
                size: 12,
                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              items: [
                DropdownMenuItem(value: 'desc', child: Text('newest_first'.tr)),
                DropdownMenuItem(value: 'asc', child: Text('oldest_first'.tr)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _sortOrder = val;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Container(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : Colors.grey.shade50.withValues(alpha: 0.5),
        child: Column(
          children: [
            tabButtonsRow,
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
            sortDropdownRow,
          ],
        ),
      );
    }

    return Container(
      color: isDark
          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
          : Colors.grey.shade50.withValues(alpha: 0.5),
      child: Row(
        children: [
          Expanded(child: tabButtonsRow),
          sortDropdownRow,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            color: isActive
                ? ((Theme.of(context).cardTheme.color ?? Colors.white))
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppColors.primary
                    : ((Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outline,
      ),
      itemBuilder: (context, index) {
        final inv = sorted[index];
        final formattedDate = _safeFormatDate(inv.date);

        Color badgeColor = isDark
            ? const Color(0xFF334155)
            : Colors.grey.shade100;
        Color textColor = (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey);
        if (inv.status == 'Paid') {
          badgeColor = isDark
              ? Colors.green.shade900.withValues(alpha: 0.3)
              : Colors.green.shade50;
          textColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
        } else if (inv.status == 'Pending' || inv.status == 'Unpaid') {
          badgeColor = isDark
              ? Colors.yellow.shade900.withValues(alpha: 0.3)
              : Colors.yellow.shade50;
          textColor = isDark ? Colors.yellow.shade400 : Colors.yellow.shade800;
        } else if (inv.status == 'Partially Paid') {
          badgeColor = isDark
              ? Colors.orange.shade900.withValues(alpha: 0.3)
              : Colors.orange.shade50;
          textColor = isDark ? Colors.orange.shade400 : Colors.orange.shade800;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            inv.status
                                .toLowerCase()
                                .replaceAll(' ', '_')
                                .tr
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency.format(inv.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inv.remainingAmount > 0
                        ? '${'due'.tr.trim()}: ${formatCurrency.format(inv.remainingAmount)}'
                        : 'settled'.tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: inv.remainingAmount > 0
                          ? AppColors.error
                          : AppColors.success,
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outline,
      ),
      itemBuilder: (context, index) {
        final quote = sorted[index];
        final formattedDate = _safeFormatDate(quote.date);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.quotationNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                formatCurrency.format(quote.grandTotal),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
        child: DataTable(
          columnSpacing: 24,
          horizontalMargin: 0,
          dividerThickness: 0.5,
          columns: [
            DataColumn(
              label: Text(
                'date'.tr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'description'.tr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'debit_billed'.tr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'credit_received'.tr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'balance'.tr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                ),
              ),
            ),
          ],
          rows: displayEntries.map((entry) {
            final dateObj = entry['date'] as DateTime;
            final dateStr = _displayDateFormat.format(dateObj);
            final balanceVal = entry['balance'] as double;
            final isAdvance = balanceVal < 0;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry['desc'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                        ),
                      ),
                      if (entry['note'] != null &&
                          (entry['note'] as String).isNotEmpty)
                        Text(
                          entry['note'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    (entry['debit'] as double) > 0
                        ? formatCurrency.format(entry['debit'])
                        : '-',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    (entry['credit'] as double) > 0
                        ? '+ ${formatCurrency.format(entry['credit'])}'
                        : '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    balanceVal == 0
                        ? '✓ ${'settled'.tr.toLowerCase()}'
                        : '${formatCurrency.format(balanceVal.abs())} ${isAdvance ? '(${'advance'.tr})' : '(${'due'.tr.trim()})'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: balanceVal == 0
                          ? AppColors.success
                          : (isAdvance
                                ? Colors.blue.shade500
                                : (isDark
                                      ? Colors.red.shade400
                                      : const Color(0xFFE11D48))),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
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
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'contact_client'.tr + client.name,
            style: TextStyle(
              color: Theme.of(context).textTheme.displayLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'contact_method_prompt'.tr,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final balanceText = balance > 0
                    ? 'outstanding_due_rs'.tr +
                          NumberFormat.decimalPattern('en_IN').format(balance)
                    : balance < 0
                    ? 'advance_rs'.tr +
                          NumberFormat.decimalPattern(
                            'en_IN',
                          ).format(balance.abs())
                    : 'outstanding_nil'.tr;
                final message =
                    '${'hello_greeting'.tr}${client.name},\nHere is your account summary:\nTotal Billed: Rs.${NumberFormat.decimalPattern('en_IN').format(billed)}\nTotal Paid: Rs.${NumberFormat.decimalPattern('en_IN').format(paid)}\n$balanceText\n\nRegards,\nAuriva BMS';
                final cleanPhone = client.phone.replaceAll(
                  RegExp(r'[^0-9+]'),
                  '',
                );
                final uri = Uri(
                  scheme: 'sms',
                  path: cleanPhone,
                  queryParameters: <String, String>{
                    'body': message,
                  },
                );
                _launchURL(uri.toString(), message);
              },
              icon: const Icon(LucideIcons.messageCircle, color: Colors.blue),
              label: Text(
                'direct_sms'.tr,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final cleanPhone = client.phone.replaceAll(
                  RegExp(r'[^0-9+]'),
                  '',
                );
                final uri = Uri(scheme: 'tel', path: cleanPhone);
                _launchURL(uri.toString(), '');
              },
              icon: const Icon(LucideIcons.phone, size: 18),
              label: Text(
                'call'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
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

  // --- COLLECT PAYMENT DIALOG ---
  void _showCollectPaymentDialog(Client client) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String payMode = 'UPI';
    DateTime payDate = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  const Icon(
                    LucideIcons.indianRupee,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'collect_payment'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9 > 400
                    ? 400
                    : MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppInputField(
                        label: 'amount_received_inr_star'.tr,
                        hintText: '0',
                        controller: amountController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          LucideIcons.indianRupee,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    'payment_mode'.tr.toUpperCase(),
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: payMode,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                  dropdownColor: Theme.of(context).cardTheme.color,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.displayLarge?.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'UPI',
                                      child: Text('upi'.tr),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Bank Transfer',
                                      child: Text('bank_transfer'.tr),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Cash',
                                      child: Text('cash'.tr),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Cheque',
                                      child: Text('cheque'.tr),
                                    ),
                                  ],
                                  onChanged: isSaving
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setDialogState(() {
                                              payMode = val;
                                            });
                                          }
                                        },
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
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    'date'.tr.toUpperCase(),
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      letterSpacing: 0.5,
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
                                                          primary:
                                                              AppColors.primary,
                                                          onPrimary:
                                                              Colors.white,
                                                          surface: Color(
                                                            0xFF1E293B,
                                                          ),
                                                          onSurface:
                                                              Colors.white,
                                                        )
                                                      : const ColorScheme.light(
                                                          primary:
                                                              AppColors.primary,
                                                          onPrimary:
                                                              Colors.white,
                                                          surface: Colors.white,
                                                          onSurface: AppColors
                                                              .textPrimary,
                                                        ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            setDialogState(() {
                                              payDate = picked;
                                            });
                                          }
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(payDate),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).textTheme.displayLarge?.color,
                                          ),
                                        ),
                                        Icon(
                                          LucideIcons.calendar,
                                          size: 16,
                                          color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
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
                        label: 'remarks_notes'.tr,
                        hintText: 'txn_id_reference_etc'.tr,
                        controller: noteController,
                        enabled: !isSaving,
                        prefixIcon: const Icon(LucideIcons.pencil, size: 18),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(
                              'cancel'.tr,
                              style: TextStyle(
                                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final amt = double.tryParse(
                                      amountController.text.trim(),
                                    );
                                    if (amt == null || amt <= 0) {
                                      Get.snackbar(
                                        'error'.tr,
                                        'amount_greater_than_zero'.tr,
                                      );
                                      return;
                                    }

                                    setDialogState(() {
                                      isSaving = true;
                                    });

                                    final success = await _clientsController
                                        .collectPayment(
                                          client.id,
                                          amt,
                                          _apiDateFormat.format(payDate),
                                          payMode,
                                          noteController.text.trim(),
                                        );

                                    if (context.mounted) {
                                      setDialogState(() {
                                        isSaving = false;
                                      });
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
                                        backgroundColor: AppColors.success
                                            .withValues(alpha: 0.1),
                                        colorText: AppColors.success,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'error'.tr,
                                        'failed_save_payment'.tr,
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.error
                                            .withValues(alpha: 0.1),
                                        colorText: AppColors.error,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isSaving
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
                                    'save_record'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
    final String selectedState = client.state.isNotEmpty ? client.state : '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'edit_client_details'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9 > 450
                    ? 450
                    : MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppInputField(
                        label: 'business_name_star'.tr,
                        hintText: 'dhruvil'.tr,
                        controller: nameController,
                        enabled: !isSaving,
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'email'.tr,
                        hintText: 'demo_gmail_com'.tr,
                        controller: emailController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'phone'.tr,
                        hintText: '7567474282',
                        controller: phoneController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'gstin_number'.tr,
                        hintText: '22AAAAA0000A1Z5',
                        controller: gstinController,
                        enabled: !isSaving,
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'billing_address'.tr,
                        hintText: 'asdasd',
                        controller: addressController,
                        enabled: !isSaving,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade100,
                                foregroundColor: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              child: Text(
                                'cancel'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final name = nameController.text.trim();
                                      if (name.isEmpty) {
                                        Get.snackbar(
                                          'error'.tr,
                                          'business_name_required'.tr,
                                        );
                                        return;
                                      }

                                      setDialogState(() {
                                        isSaving = true;
                                      });

                                      final success = await _clientsController
                                          .updateClient(
                                            client.id,
                                            name,
                                            emailController.text.trim(),
                                            phoneController.text.trim(),
                                            gstinController.text.trim(),
                                            selectedState,
                                            addressController.text.trim(),
                                          );

                                      if (context.mounted) {
                                        setDialogState(() {
                                          isSaving = false;
                                        });
                                      }

                                      if (success) {
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                        Get.snackbar(
                                          'client_updated'.tr,
                                          'changes_saved_success'.tr,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppColors.success
                                              .withValues(alpha: 0.1),
                                          colorText: AppColors.success,
                                        );
                                      } else {
                                        Get.snackbar(
                                          'error'.tr,
                                          'failed_update_client'.tr,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppColors.error
                                              .withValues(alpha: 0.1),
                                          colorText: AppColors.error,
                                        );
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'save_changes'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ), // Close Expanded
                        ],
                      ),
                    ],
                  ),
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

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_extensions.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../clients/clients_controller.dart';
import '../expenses/expenses_controller.dart';
import '../invoices/create_invoice_screen.dart';
import '../invoices/invoice_details_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../clients/clients_screen.dart';
import '../expenses/expenses_screen.dart';
import '../clients/select_client_screen.dart';
import '../auth/auth_controller.dart';
import '../quotations/create_quotation_screen.dart';
import '../inventory/inventory_screen.dart';
import '../suppliers/suppliers_screen.dart';
import '../../navigation/main_layout.dart';
import 'dashboard_controller.dart';

// Tailwind color constants matching web aesthetics
const Color tailwindEmerald = Color(0xFF10B981);
const Color tailwindEmeraldLight = Color(0xFFD1FAE5);
const Color tailwindRose = Color(0xFFF43F5E);
const Color tailwindRoseLight = Color(0xFFFFE4E6);
const Color tailwindViolet = Color(0xFF8B5CF6);
const Color tailwindVioletLight = Color(0xFFEDE9FE);
const Color tailwindPurple = Color(0xFFA855F7);
const Color tailwindPurpleLight = Color(0xFFF3E8FF);
const Color tailwindAmber = Color(0xFFF59E0B);
const Color tailwindAmberLight = Color(0xFFFEF3C7);
const Color tailwindIndigo = Color(0xFF6366F1);
const Color tailwindIndigoLight = Color(0xFFE0E7FF);
const Color tailwindBlue = Color(0xFF3B82F6);
const Color tailwindBlueLight = Color(0xFFDBEAFE);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final ClientsController clientsController =
      Get.isRegistered<ClientsController>()
      ? Get.find<ClientsController>()
      : Get.put(ClientsController());
  final ExpensesController expensesController =
      Get.isRegistered<ExpensesController>()
      ? Get.find<ExpensesController>()
      : Get.put(ExpensesController());
  final AuthController authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);
  final DashboardController dashboardController = Get.put(
    DashboardController(),
  );

  // Quick Payment form variables
  String? _selectedClientId;
  final _paymentAmountController = TextEditingController();
  final _paymentNotesController = TextEditingController();
  String _paymentMode = 'Bank Txn';
  bool _isLoggingPayment = false;

  bool get _isPaymentFormValid {
    if (_selectedClientId == null) return false;
    final amountText = _paymentAmountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return false;
    if (_paymentMode.isEmpty) return false;
    return true;
  }

  // Chart state
  final String _chartView = 'monthly'; // 'monthly' or 'yearly'
  String _globalFilter = 'Lifetime';
  bool _isManualRefreshing = false;

  final GlobalKey _quickCollectKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Refresh backend data when dashboard is mounted
    clientsController.fetchClients();
    expensesController.fetchExpenses();
    authController.fetchTenantSettings();
    dashboardController.fetchDashboardStats();
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _paymentNotesController.dispose();
    super.dispose();
  }

  void _handlePaymentSubmit() async {
    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      Fluttertoast.showToast(
        msg: 'please_select_client'.tr,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        textColor: Colors.white,
      );
      return;
    }

    final amountStr = _paymentAmountController.text.trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      Fluttertoast.showToast(
        msg: 'please_enter_amount'.tr,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoggingPayment = true;
    });

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    clientsController.collectPayment(
      _selectedClientId!,
      amount,
      today,
      _paymentMode,
      _paymentNotesController.text.isNotEmpty
          ? _paymentNotesController.text
          : 'Dashboard Quick Collect',
    );

    // Give a brief delay for UI state to settle
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isLoggingPayment = false;
        _paymentAmountController.clear();
        _paymentNotesController.clear();
        _paymentMode = 'Bank Txn';
        _selectedClientId = null;
      });

      Fluttertoast.showToast(
        msg: 'payment_logged_success'.tr,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        textColor: Colors.white,
      );
    }
  }

  int getDaysLeft(String? endDateStr) {
    if (endDateStr == null || endDateStr.isEmpty) return 0;
    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return 0;
    final diff = endDate.difference(DateTime.now());
    return diff.inDays + 1;
  }

  String getPlanName(String? plan) {
    if (plan == null || plan.isEmpty) return 'STARTER PLAN';
    return plan.toUpperCase();
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    final clean = dateStr.trim();
    final parsed = DateTime.tryParse(clean);
    if (parsed != null) return parsed;

    try {
      return DateFormat("dd MMM yyyy").parse(clean);
    } catch (_) {}

    try {
      return DateFormat("yyyy-MM-dd").parse(clean);
    } catch (_) {}

    try {
      final parts = clean.split(RegExp(r'[\s\-]+'));
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final year = int.tryParse(parts[2]);
        final monthNames = [
          "jan",
          "feb",
          "mar",
          "apr",
          "may",
          "jun",
          "jul",
          "aug",
          "sep",
          "oct",
          "nov",
          "dec",
        ];
        final monthIdx =
            monthNames.indexWhere((m) => parts[1].toLowerCase().startsWith(m)) +
            1;
        if (day != null && year != null && monthIdx > 0) {
          return DateTime(year, monthIdx, day);
        }
      }
    } catch (_) {}

    return null;
  }

  String _getTimeframeIcon(String filter) {
    switch (filter) {
      case 'This Year':
        return 'assets/SVG/calendar.svg';
      case 'This Month':
        return 'assets/SVG/calendernormal.svg';
      case 'Today':
        return 'assets/SVG/time.svg';
      case 'Lifetime':
      default:
        return 'assets/SVG/allcube.svg';
    }
  }

  Color _getTimeframeColor(String filter) {
    switch (filter) {
      case 'This Year':
        return const Color(0xFF3B82F6);
      case 'This Month':
        return const Color(0xFF10B981);
      case 'Today':
        return const Color(0xFFF59E0B);
      case 'Lifetime':
      default:
        return const Color(0xFF6366F1);
    }
  }

  Future<void> _showTimeframeFilterBottomSheet(BuildContext context) async {
    final filters = [
      {
        'id': 'Lifetime',
        'title': 'Lifetime',
        'subtitle': 'All historical sales, revenue & expenses',
        'icon': 'assets/SVG/allcube.svg',
        'color': const Color(0xFF6366F1),
        'badge': 'ALL DATA',
      },
      {
        'id': 'This Year',
        'title': 'This Year',
        'subtitle': 'Current year (${DateTime.now().year}) transactions',
        'icon': 'assets/SVG/calendar.svg',
        'color': const Color(0xFF3B82F6),
        'badge': '${DateTime.now().year}',
      },
      {
        'id': 'This Month',
        'title': 'This Month',
        'subtitle':
            '${DateFormat('MMMM yyyy').format(DateTime.now())} overview',
        'icon': 'assets/SVG/calendernormal.svg',
        'color': const Color(0xFF10B981),
        'badge': DateFormat('MMM').format(DateTime.now()).toUpperCase(),
      },
      {
        'id': 'Today',
        'title': 'Today',
        'subtitle':
            'Real-time metrics for ${DateFormat('dd MMM').format(DateTime.now())}',
        'icon': 'assets/SVG/time.svg',
        'color': const Color(0xFFF59E0B),
        'badge': 'LIVE',
      },
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.08);

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset(
                          'assets/SVG/allcube.svg',
                          width: 17,
                          height: 17,
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard Timeframe',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Select period to filter stats & analytics',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: isDark ? Colors.white60 : Colors.grey.shade700,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...filters.map((opt) {
                    final isSelected = _globalFilter == opt['id'];
                    final color = opt['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            final selectedVal = opt['id'] as String;
                            if (selectedVal != _globalFilter) {
                              setState(() {
                                _globalFilter = selectedVal;
                                _isManualRefreshing = true;
                              });
                              await Future.wait([
                                clientsController.fetchClients(),
                                expensesController.fetchExpenses(),
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                ),
                              ]);
                              if (mounted) {
                                setState(() {
                                  _isManualRefreshing = false;
                                });
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(
                                      alpha: isDark ? 0.15 : 0.08,
                                    )
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.03)
                                        : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? color.withValues(alpha: 0.8)
                                    : borderColor,
                                width: isSelected ? 1.2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SvgPicture.asset(
                                    opt['icon'] as String,
                                    width: 17,
                                    height: 17,
                                    colorFilter: ColorFilter.mode(
                                      color,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            opt['title'] as String,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              opt['badge'] as String,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        opt['subtitle'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? color
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : (isDark
                                                ? Colors.white30
                                                : Colors.grey.shade400),
                                      width: isSelected ? 0 : 1.2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'dashboard'.tr,
        subtitle: null,
        showMenu: false,
        showProfile: true,
        showBadge: false,
        showNotification: true,
        showBackButton: false,
        showBorder: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mounted) {
            setState(() {
              _isManualRefreshing = true;
            });
          }
          await clientsController.fetchClients();
          await expensesController.fetchExpenses();
          await authController.fetchTenantSettings();
          await dashboardController.fetchDashboardStats();
          if (mounted) {
            setState(() {
              _isManualRefreshing = false;
            });
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 0,
            bottom: 20.0,
          ),
          child: Obx(() {
            final isLoading = dashboardController.isLoading.value;
            final showSkeleton = isLoading;
            final bool useDummy = showSkeleton;

            // --- Real-time stats from Backend API ---
            double totalRevenue = dashboardController.totalRevenue.value;
            double totalPendingAmount =
                dashboardController.totalPendingAmount.value;
            int totalInvoices = dashboardController.totalInvoices.value;
            int paidCount = dashboardController.paidInvoices.value;
            int pendingCount = dashboardController.pendingCount.value;
            double totalExpenses = dashboardController.totalExpenses.value;
            double netProfit = dashboardController.netProfit.value;
            double totalReceived = totalRevenue - totalPendingAmount;
            int successRate = totalInvoices > 0
                ? ((paidCount / totalInvoices) * 100).round()
                : 0;

            // Note: recentInvoices extraction remains similar but from dashboardController if needed. We'll leave it out for this simplified stat UI as the backend provides it natively.

            if (useDummy) {
              totalRevenue = 250000.0;
              totalExpenses = 85000.0;
              netProfit = totalRevenue - totalExpenses;
              totalPendingAmount = 65000.0;
              totalInvoices = 16;
              paidCount = 12;
              pendingCount = 4;
              successRate = 75;
              totalReceived = totalRevenue - totalPendingAmount;
            }

            // Chart grouping removed as requested

            return Skeletonizer(
              enabled: showSkeleton,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ROW (Welcome & Quick New Invoice) ---
                  FadeInUp(
                    delay: Duration.zero,
                    child: LayoutBuilder(
                      builder: (context, headerConstraints) {
                        final isSmallScreen = headerConstraints.maxWidth < 450;

                        Widget buildWelcomeHeader() {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.hexagon,
                                                  size: 12,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Obx(() {
                                                  final role = authController
                                                      .userRole
                                                      .value
                                                      .toUpperCase();
                                                  String displayRole = 'USER';
                                                  if (role.isNotEmpty) {
                                                    displayRole = role
                                                        .replaceAll('_', ' ');
                                                  }
                                                  return Text(
                                                    displayRole,
                                                    style: context
                                                        .typography
                                                        .roleBadgeText
                                                        .copyWith(
                                                          color: context
                                                              .colorScheme
                                                              .primary,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'welcome_back'.tr,
                                            style: context
                                                .typography
                                                .screenTitle
                                                .copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.color,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  authController
                                                          .userName
                                                          .value
                                                          .isNotEmpty
                                                      ? authController
                                                            .userName
                                                            .value
                                                      : 'Admin',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: context
                                                      .typography
                                                      .screenTitle
                                                      .copyWith(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color(
                                                          0xFF4F46E5,
                                                        ), // Match the primary color
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Lottie.asset(
                                      'assets/lottie/business_analytics.json',
                                      height: 110,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Subscription Badge
                                Obx(() {
                                  final tenant =
                                      authController.tenantInfo.value;
                                  if (tenant == null ||
                                      tenant['subscriptionEnd'] == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final plan =
                                      tenant['subscriptionPlan'] as String?;
                                  final endDateStr =
                                      tenant['subscriptionEnd'] as String?;
                                  final daysLeft = getDaysLeft(endDateStr);
                                  final planName = getPlanName(plan);
                                  final isWarning = daysLeft <= 15;

                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isWarning
                                            ? Colors.red.withValues(alpha: 0.08)
                                            : const Color(
                                                0xFFF0F9FF,
                                              ), // lighter blue
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isWarning
                                              ? Colors.red.withValues(
                                                  alpha: 0.15,
                                                )
                                              : const Color(0xFFE0F2FE),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/SVG/plan.svg',
                                            width: 14,
                                            height: 14,
                                            colorFilter: ColorFilter.mode(
                                              isWarning
                                                  ? Colors.red
                                                  : const Color(0xFF0284C7),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            planName.toUpperCase(),
                                            style: context
                                                .typography
                                                .roleBadgeText
                                                .copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isWarning
                                                      ? Colors.red
                                                      : const Color(0xFF0284C7),
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: isWarning
                                                  ? Colors.red
                                                  : const Color(0xFF0284C7),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            daysLeft > 0
                                                ? '$daysLeft ${'days_left'.tr}'
                                                : 'expired'.tr,
                                            style: context
                                                .typography
                                                .statusLabel
                                                .copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: isWarning
                                                      ? Colors.red
                                                      : const Color(0xFF0284C7),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }

                        Widget buildVisibilityToggleButton({
                          bool isFullWidth = false,
                        }) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                dashboardController.isAmountsVisible.value =
                                    !dashboardController.isAmountsVisible.value;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: isFullWidth ? double.infinity : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: SvgPicture.asset(
                                dashboardController.isAmountsVisible.value
                                    ? 'assets/SVG/eyeview.svg'
                                    : 'assets/SVG/eyehide.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.primary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          );
                        }

                        Widget buildRevealStatsButton({
                          bool isFullWidth = false,
                        }) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                dashboardController.isAmountsVisible.value =
                                    true;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: isFullWidth ? double.infinity : null,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: isFullWidth
                                    ? MainAxisSize.max
                                    : MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/SVG/eyehide.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.primary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Press button to show your statistics',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        Widget buildFilterDropdown({bool isFullWidth = false}) {
                          final iconPath = _getTimeframeIcon(_globalFilter);
                          final color = _getTimeframeColor(_globalFilter);

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _showTimeframeFilterBottomSheet(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: isFullWidth ? double.infinity : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: isFullWidth
                                      ? MainAxisSize.max
                                      : MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: SvgPicture.asset(
                                            iconPath,
                                            width: 14,
                                            height: 14,
                                            colorFilter: ColorFilter.mode(
                                              color,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _globalFilter,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      LucideIcons.chevronDown,
                                      size: 14,
                                      color: color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        if (isSmallScreen) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildWelcomeHeader(),
                              const SizedBox(height: 16),
                              if (dashboardController.isAmountsVisible.value)
                                Row(
                                  children: [
                                    Expanded(
                                      child: buildFilterDropdown(
                                        isFullWidth: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    buildVisibilityToggleButton(),
                                  ],
                                )
                              else
                                buildRevealStatsButton(isFullWidth: true),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: buildWelcomeHeader()),
                              const SizedBox(width: 12),
                              if (dashboardController.isAmountsVisible.value)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    buildFilterDropdown(),
                                    const SizedBox(width: 12),
                                    buildVisibilityToggleButton(),
                                  ],
                                )
                              else
                                buildRevealStatsButton(),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- STATS CARDS GRID (6 Cards) ---
                  if (dashboardController.isAmountsVisible.value) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: context.width < 600 ? 2 : 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: context.width < 600 ? 1.15 : 1.35,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        String obscureValue(String val) =>
                            dashboardController.isAmountsVisible.value
                            ? val
                            : '••••••';
                        switch (index) {
                          case 0:
                            return _buildStatCard(
                              title: 'revenue'.tr,
                              value: obscureValue(
                                formatCurrency.format(totalRevenue),
                              ),
                              subtitle: 'income_arrow'.tr,
                              svgPath: 'assets/SVG/profit.svg',
                              color: tailwindEmerald,
                              bgColor: tailwindEmeraldLight,
                              delay: 50,
                            );
                          case 1:
                            return _buildStatCard(
                              title: 'expenses_caps'.tr,
                              value: obscureValue(
                                formatCurrency.format(totalExpenses),
                              ),
                              subtitle: 'outflow'.tr,
                              svgPath: 'assets/SVG/loss.svg',
                              color: tailwindRose,
                              bgColor: tailwindRoseLight,
                              delay: 100,
                            );
                          case 2:
                            return _buildStatCard(
                              title: 'NET PROFIT',
                              value: obscureValue(
                                formatCurrency.format(netProfit),
                              ),
                              subtitle: 'Rev - (Exp + Purchases)',
                              svgPath: 'assets/SVG/wallet.svg',
                              color: context.colorScheme.primary,
                              bgColor: AppColors.primary.withValues(alpha: 0.1),
                              isFeatured: true,
                              delay: 150,
                            );
                          case 3:
                            return _buildStatCard(
                              title: 'pending'.tr,
                              value: obscureValue(
                                formatCurrency.format(totalPendingAmount),
                              ),
                              subtitle: '$pendingCount ${'unpaid'.tr}',
                              svgPath: 'assets/SVG/time.svg',
                              color: tailwindAmber,
                              bgColor: tailwindAmberLight,
                              delay: 200,
                            );
                          case 4:
                            return _buildStatCard(
                              title: 'invoices'.tr,
                              value: obscureValue('$totalInvoices'),
                              subtitle: 'lifetime_billed'.tr,
                              svgPath: 'assets/SVG/invoice.svg',
                              color: tailwindViolet,
                              bgColor: tailwindVioletLight,
                              delay: 250,
                            );
                          case 5:
                          default:
                            return _buildStatCard(
                              title: 'RECEIVED',
                              value: obscureValue(
                                formatCurrency.format(totalReceived),
                              ),
                              subtitle: 'Payment collected',
                              svgPath: 'assets/SVG/checkmark.svg',
                              color: tailwindPurple,
                              bgColor: tailwindPurpleLight,
                              delay: 300,
                            );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  _buildGridActionButtons(isDark),
                  const SizedBox(height: 24),

                  // --- MAIN LAYOUT (Recent Invoices & Quick Actions) ---
                  Column(
                    children: [
                      if (dashboardController.recentInvoices.isNotEmpty) ...[
                        _buildRecentInvoices(
                          dashboardController.recentInvoices,
                          isDark,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (expensesController.expenses.isNotEmpty) ...[
                        _buildRecentExpenses(
                          expensesController.expenses
                              .take(5)
                              .map(
                                (e) => {
                                  'id': e.id,
                                  '_id': e.id,
                                  'category': e.category,
                                  'amount': e.amount,
                                  'description': e.description,
                                  'date': e.date,
                                  'createdBy': {'name': e.user},
                                },
                              )
                              .toList(),
                          isDark,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildQuickCollectPayment(isDark),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required String svgPath,
    double iconRotation = 0.0,
    required Color color,
    required Color bgColor,
    bool isFeatured = false,
    required int delay,
    bool isSmall = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: HoverScaleContainer(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFeatured
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
              width: isFeatured ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 6.0 : 10.0,
                    vertical: isSmall ? 4.0 : 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmall ? 6 : 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? color.withValues(alpha: 0.15)
                                  : bgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Transform.rotate(
                              angle: iconRotation,
                              child: SvgPicture.asset(
                                svgPath,
                                width: isSmall ? 14 : 16,
                                height: isSmall ? 14 : 16,
                                colorFilter: ColorFilter.mode(
                                  color,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmall ? 8 : 10),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.typography.statisticLabel.copyWith(
                                fontSize: isSmall ? 9 : 10,
                                fontWeight: FontWeight.w900,
                                color:
                                    (Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    Colors.grey),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmall ? 6 : 10),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.statisticValue.copyWith(
                          fontSize: isSmall ? 15 : 18,
                          fontWeight: FontWeight.w900,
                          color: isFeatured
                              ? AppColors.primary
                              : ((Theme.of(
                                      context,
                                    ).textTheme.displayLarge?.color ??
                                    Colors.black)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.trendText.copyWith(
                          fontSize: isSmall ? 9 : 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isFeatured)
                Container(height: 4, color: context.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridActionButtons(bool isDark) {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'New Invoice',
        'svgPath': 'assets/SVG/invoice.svg',
        'color': tailwindBlue,
        'bgColor': tailwindBlueLight,
        'onTap': () {
          Get.to(() => const CreateInvoiceScreen());
        },
      },
      {
        'title': 'New Quotation',
        'svgPath': 'assets/SVG/qoutation.svg',
        'color': tailwindAmber,
        'bgColor': tailwindAmberLight,
        'onTap': () {
          Get.to(() => const CreateQuotationScreen());
        },
      },
      {
        'title': 'Inventory',
        'svgPath': 'assets/SVG/inventory.svg',
        'color': tailwindPurple,
        'bgColor': tailwindPurpleLight,
        'onTap': () {
          Get.to(() => const InventoryScreen());
        },
      },
      {
        'title': 'Add Expense',
        'svgPath': 'assets/SVG/expance.svg',
        'color': tailwindRose,
        'bgColor': tailwindRoseLight,
        'onTap': () {
          final BuildContext context = Get.context!;
          final bool isDark = Theme.of(context).brightness == Brightness.dark;

          Get.to(() => const ExpensesScreen());
          Future.delayed(const Duration(milliseconds: 300), () {
            showAddExpenseBottomSheet(Get.context!, isDark);
          });
        },
      },
      {
        'title': 'Add Client',
        'svgPath': 'assets/SVG/addclient.svg',
        'color': tailwindEmerald,
        'bgColor': tailwindEmeraldLight,
        'onTap': () {
          final mainCtrl = Get.isRegistered<MainLayoutController>()
              ? Get.find<MainLayoutController>()
              : null;
          if (mainCtrl != null) {
            mainCtrl.changeIndex(3);
          } else {
            Get.to(() => const ClientsScreen());
          }
        },
      },
      {
        'title': 'Add Supplier',
        'svgPath': 'assets/SVG/supplier.svg',
        'color': tailwindIndigo,
        'bgColor': tailwindIndigoLight,
        'onTap': () {
          Get.to(() => const SuppliersScreen());
        },
      },
    ];

    return FadeInUp(
      delay: const Duration(milliseconds: 350),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.width < 600 ? 3 : 6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildActionCard(
            title: action['title'] as String,
            svgPath: action['svgPath'] as String,
            color: action['color'] as Color,
            bgColor: action['bgColor'] as Color,
            onTap: action['onTap'] as VoidCallback,
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String svgPath,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleOnPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? color.withValues(alpha: 0.15) : bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SvgPicture.asset(
                svgPath,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices(
    List<Map<String, dynamic>> recentInvoices,
    bool isDark,
  ) {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    'assets/SVG/invoice.svg',
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      context.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Invoices',
                        style: context.typography.cardTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color:
                              (Theme.of(
                                context,
                              ).textTheme.displayLarge?.color ??
                              Colors.black),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Latest billing activities',
                        style: context.typography.cardSubtitle.copyWith(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final mainCtrl = Get.isRegistered<MainLayoutController>()
                        ? Get.find<MainLayoutController>()
                        : null;
                    if (mainCtrl != null) {
                      mainCtrl.changeIndex(1);
                    } else {
                      Get.to(() => const InvoiceListScreen());
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: context.typography.buttonText.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: context.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (recentInvoices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'no_invoices_yet'.tr,
                    style: context.typography.emptyStateDescription.copyWith(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentInvoices.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final Map<String, dynamic> inv = recentInvoices[idx];
                  final clientObj = inv['client'] ?? {};
                  final String clientName =
                      clientObj['name'] ?? 'Unknown Client';
                  final String status = inv['status'] ?? 'Pending';
                  final String statusLower = status.toLowerCase();

                  String svgPath = 'assets/SVG/pending.svg';
                  Color statusColor = tailwindAmber;
                  Color statusBgColor = tailwindAmberLight;

                  if (statusLower == 'paid') {
                    svgPath = 'assets/SVG/paid.svg';
                    statusColor = tailwindEmerald;
                    statusBgColor = tailwindEmeraldLight;
                  } else if (statusLower.contains('partial')) {
                    svgPath = 'assets/SVG/partialypaid.svg';
                    statusColor = tailwindBlue;
                    statusBgColor = tailwindBlueLight;
                  } else if (statusLower == 'overdue') {
                    svgPath = 'assets/SVG/overdue.svg';
                    statusColor = tailwindRose;
                    statusBgColor = tailwindRoseLight;
                  }

                  final double totalAmount = (inv['totalAmount'] ?? 0)
                      .toDouble();
                  final String invoiceNumber = inv['invoiceNumber'] ?? '';
                  final String rawDate = inv['date'] ?? '';
                  final String id = inv['_id'] ?? inv['id'] ?? '';

                  String displayDate = rawDate;
                  final parsedDate = _parseDate(rawDate);
                  if (parsedDate != null) {
                    displayDate = DateFormat('dd MMM yyyy').format(parsedDate);
                  } else if (displayDate.contains('T')) {
                    displayDate = displayDate.split('T')[0];
                  } else if (displayDate.contains(' ')) {
                    if (displayDate.split(' ').length > 2) {
                      // Probably already formatted
                    } else {
                      displayDate = displayDate.split(' ')[0];
                    }
                  }

                  return ScaleOnPress(
                    onTap: () {
                      final rawInvoice = clientsController.allInvoices
                          .firstWhere(
                            (json) =>
                                (json['invoiceNumber'] == invoiceNumber) ||
                                (json['_id'] ?? json['id']) == id,
                            orElse: () => {},
                          );
                      if (rawInvoice.isNotEmpty) {
                        final rawClientObj = rawInvoice['client'] ?? {};
                        final String clientEmail = rawClientObj['email'] ?? '';
                        final String clientAddress =
                            rawClientObj['address'] ?? '';
                        final String clientGst =
                            rawClientObj['gstin'] ??
                            rawClientObj['gstNumber'] ??
                            '';
                        final String placeOfSupply =
                            rawInvoice['placeOfSupply'] ??
                            rawClientObj['state'] ??
                            '';
                        final List<dynamic> rawItems =
                            rawInvoice['items'] ?? [];
                        final List<Map<String, dynamic>> items =
                            List<Map<String, dynamic>>.from(
                              rawItems.map((x) => Map<String, dynamic>.from(x)),
                            );

                        Get.to(
                          () => InvoiceDetailsScreen(
                            invoiceId: invoiceNumber.isNotEmpty
                                ? invoiceNumber
                                : id,
                            dbId: id,
                            clientName: clientName,
                            amount: totalAmount,
                            date: rawDate,
                            status: status,
                            items: items,
                            dueDate: rawInvoice['dueDate'],
                            placeOfSupply: placeOfSupply,
                            discountPercentage:
                                (rawInvoice['discountPercentage'] ?? 0.0)
                                    .toDouble(),
                            gstEnabled: rawInvoice['gstEnabled'] ?? false,
                            taxType: rawInvoice['taxType'] ?? 'exclusive',
                            clientEmail: clientEmail,
                            clientAddress: clientAddress,
                            clientGst: clientGst,
                          ),
                        );
                      } else {
                        Get.to(
                          () => InvoiceDetailsScreen(
                            invoiceId: invoiceNumber.isNotEmpty
                                ? invoiceNumber
                                : id,
                            dbId: id,
                            clientName: clientName,
                            amount: totalAmount,
                            date: rawDate,
                            status: status,
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: statusColor, width: 4),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? statusColor.withValues(alpha: 0.15)
                                      : statusBgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  svgPath,
                                  width: 16,
                                  height: 16,
                                  colorFilter: ColorFilter.mode(
                                    statusColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      clientName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.typography.clientName
                                          .copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                (Theme.of(context)
                                                    .textTheme
                                                    .displayLarge
                                                    ?.color ??
                                                Colors.black),
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(
                                                    0xFF6366F1,
                                                  ).withValues(alpha: 0.15)
                                                : const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                invoiceNumber,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF6366F1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (inv['createdBy'] != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(
                                                      0xFF6366F1,
                                                    ).withValues(alpha: 0.15)
                                                  : const Color(0xFFEEF2FF),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                // const Icon(LucideIcons.user, size: 9, color: Color(0xFF6366F1)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  inv['createdBy']['name'] ??
                                                      'User',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF6366F1),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/SVG/calendernormal.svg',
                                          width: 13,
                                          height: 13,
                                          colorFilter: ColorFilter.mode(
                                            Colors.grey.shade500,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          displayDate,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatCurrency.format(totalAmount),
                                    style: context.typography.invoiceAmount
                                        .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              (Theme.of(
                                                context,
                                              ).textTheme.displayLarge?.color ??
                                              Colors.black),
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? statusColor.withValues(alpha: 0.15)
                                          : statusBgColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 4),
                                        Text(
                                          status,
                                          style: context
                                              .typography
                                              .invoiceStatus
                                              .copyWith(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenses(
    List<Map<String, dynamic>> recentExpenses,
    bool isDark,
  ) {
    return FadeInUp(
      delay: const Duration(milliseconds: 450),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tailwindRose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    'assets/SVG/expance.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      tailwindRose,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Expenses',
                        style: context.typography.cardTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color:
                              (Theme.of(
                                context,
                              ).textTheme.displayLarge?.color ??
                              Colors.black),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Latest expense activities',
                        style: context.typography.cardSubtitle.copyWith(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final mainCtrl = Get.isRegistered<MainLayoutController>()
                        ? Get.find<MainLayoutController>()
                        : null;
                    if (mainCtrl != null && mainCtrl.screens.length > 2) {
                      // Check if Expenses is actually at index 2 or handled differently
                      // We'll navigate directly using Get.to to ensure it opens
                      Get.to(() => const ExpensesScreen());
                    } else {
                      Get.to(() => const ExpensesScreen());
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'View All',
                        style: context.typography.buttonText.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              (Theme.of(
                                context,
                              ).textTheme.displayLarge?.color ??
                              Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color:
                            (Theme.of(context).textTheme.displayLarge?.color ??
                            Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (recentExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No expenses yet',
                    style: context.typography.emptyStateDescription.copyWith(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentExpenses.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 6),
                itemBuilder: (context, idx) {
                  final Map<String, dynamic> exp = recentExpenses[idx];

                  String title = exp['category']?.toString() ?? 'Expense';
                  if (title.trim().isEmpty) {
                    title = 'Expense';
                  }
                  final double amount = (exp['amount'] ?? 0).toDouble();
                  final String rawDate = exp['date'] ?? '';
                  final String user = (exp['createdBy'] != null)
                      ? (exp['createdBy']['name'] ?? '')
                      : '';

                  final expense = Expense(
                    id:
                        exp['_id']?.toString() ??
                        exp['id']?.toString() ??
                        idx.toString(),
                    category: exp['category'] ?? '',
                    amount: amount,
                    description: exp['description'] ?? '',
                    date: rawDate,
                    user: user,
                  );

                  String displayDate = rawDate;
                  final parsedDate = _parseDate(rawDate);
                  if (parsedDate != null) {
                    displayDate = DateFormat('dd MMM yyyy').format(parsedDate);
                  } else if (displayDate.contains('T')) {
                    displayDate = displayDate.split('T')[0];
                  }

                  final desc = (exp['description']?.toString() ?? '').trim();
                  final descText = desc.isEmpty ? 'No Description' : desc;

                  final itemCurrencyFormat = NumberFormat.currency(
                    locale: 'en_IN',
                    symbol: '₹',
                    decimalDigits: 0,
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon Box
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: isDark
                                ? tailwindEmerald.withValues(alpha: 0.15)
                                : tailwindEmeraldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/SVG/expance.svg',
                              width: 23,
                              height: 23,
                              colorFilter: const ColorFilter.mode(
                                tailwindEmerald,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Middle Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // The parenthesis ensure the fallback happens BEFORE the capitalization
                                (title ?? '').toTitleCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: context.colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                descText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/SVG/calendar.svg',
                                    width: 14,
                                    height: 14,
                                    colorFilter: ColorFilter.mode(
                                      Colors.grey.shade500,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    displayDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              itemCurrencyFormat.format(amount),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color:
                                    (Theme.of(
                                      context,
                                    ).textTheme.displayLarge?.color ??
                                    Colors.black),
                              ),
                            ),
                            if (user.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.15)
                                      : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCollectPayment(bool isDark) {
    final activeClient = _selectedClientId != null
        ? clientsController.clients.firstWhere(
            (c) => c.id == _selectedClientId,
            orElse: () => clientsController.clients.first,
          )
        : null;

    double activeClientTotalPaid = 0.0;
    if (_selectedClientId != null) {
      final paymentsList =
          clientsController.clientPayments[_selectedClientId] ?? [];
      activeClientTotalPaid = paymentsList.fold<double>(
        0.0,
        (sum, pay) => sum + pay.amount,
      );
    }

    return FadeInUp(
      key: _quickCollectKey,
      delay: const Duration(milliseconds: 450),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                SvgPicture.asset(
                  'assets/SVG/wallet.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    tailwindEmerald,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'collect_payment'.tr,
                  style: context.typography.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color:
                        (Theme.of(context).textTheme.displayLarge?.color ??
                        Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Client Selection
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await Get.to(() => const SelectClientScreen());
                  if (result != null && result is String) {
                    if (_selectedClientId != result) {
                      setState(() {
                        _selectedClientId = result;
                        _paymentAmountController.clear();
                        _paymentNotesController.clear();
                      });
                    }
                    // Scroll to the Quick Collect section when a client is selected
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_quickCollectKey.currentContext != null) {
                        Scrollable.ensureVisible(
                          _quickCollectKey.currentContext!,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          alignment:
                              1.0, // align bottom of the content to bottom of screen
                        );
                      }
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                              : const Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/SVG/userround.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF6366F1),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedClientId == null || activeClient == null
                            ? Text(
                                'select_client'.tr,
                                style: context.typography.searchHint.copyWith(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeClient.name,
                                    style: context.typography.inputText
                                        .copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color:
                                              (Theme.of(
                                                context,
                                              ).textTheme.displayLarge?.color ??
                                              Colors.black),
                                        ),
                                  ),
                                  if (activeClient.phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      activeClient.phone,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: Colors.grey.shade800,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedClientId != null && activeClient != null) ...[
              const SizedBox(height: 12),

              // Ledger Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Billed',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formatCurrency.format(activeClient.totalBilled),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color:
                                (Theme.of(
                                  context,
                                ).textTheme.displayLarge?.color ??
                                Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Received',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formatCurrency.format(activeClientTotalPaid),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: tailwindEmerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Balance Due',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                (Theme.of(
                                  context,
                                ).textTheme.displayLarge?.color ??
                                Colors.black),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          activeClient.balance > 0
                              ? formatCurrency.format(activeClient.balance)
                              : 'Settled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: activeClient.balance > 0
                                ? tailwindRose
                                : tailwindEmerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (activeClient.balance > 0) ...[
                // ENTER AMOUNT
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Theme.of(context).scaffoldBackgroundColor
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _paymentAmountController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: context.typography.inputText.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color:
                                (Theme.of(
                                  context,
                                ).textTheme.displayLarge?.color ??
                                Colors.black),
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(bottom: 4),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ScaleOnPress(
                          onTap: () {
                            setState(() {
                              _paymentAmountController.text =
                                  activeClient.balance > 0
                                  ? activeClient.balance.toStringAsFixed(0)
                                  : '0';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? tailwindEmerald.withValues(alpha: 0.15)
                                  : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Max',
                              style: TextStyle(
                                color: tailwindEmerald,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // PAYMENT METHOD
                Row(
                  children: [
                    _buildPaymentMethodCard(
                      'Bank Txn',
                      'assets/SVG/bank.svg',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentMethodCard(
                      'UPI',
                      'assets/SVG/mobile.svg',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentMethodCard(
                      'Cash',
                      'assets/SVG/cash.svg',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPaymentMethodCard(
                      'Cheque',
                      'assets/SVG/cheque.svg',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // REMARK
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      SvgPicture.asset(
                        'assets/SVG/note.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          Colors.grey.shade500,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _paymentNotesController,
                          onChanged: (_) => setState(() {}),
                          style: context.typography.inputText.copyWith(
                            fontSize: 12,
                            color:
                                (Theme.of(
                                  context,
                                ).textTheme.displayLarge?.color ??
                                Colors.black),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a note...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(
                              bottom: 10,
                            ), // Adjust vertical centering for 40 height
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Log Payment Button
                ScaleOnPress(
                  onTap: _isLoggingPayment || !_isPaymentFormValid
                      ? () {}
                      : _handlePaymentSubmit,
                  child: Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isPaymentFormValid
                          ? tailwindEmerald
                          : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !_isPaymentFormValid
                          ? []
                          : [
                              BoxShadow(
                                color: tailwindEmerald.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoggingPayment
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.checkCircle,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Log Payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? tailwindEmerald.withValues(alpha: 0.15)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tailwindEmerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        color: tailwindEmerald,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Amount Settled',
                        style: TextStyle(
                          color: tailwindEmerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    String title,
    String svgAssetPath,
    bool isDark,
  ) {
    final bool isSelected = _paymentMode == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paymentMode = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? tailwindEmerald
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? tailwindEmerald.withValues(alpha: 0.15)
                                  : const Color(0xFFECFDF5))
                            : (isDark
                                  ? const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.15)
                                  : const Color(0xFFEEF2FF)),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        svgAssetPath,
                        width: 14,
                        height: 14,
                        colorFilter: ColorFilter.mode(
                          isSelected
                              ? tailwindEmerald
                              : const Color(0xFF6366F1),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color:
                            (Theme.of(context).textTheme.displayLarge?.color ??
                            Colors.black),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -6,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: tailwindEmerald,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withValues(
            alpha: isDark ? 0.6 : 0.8,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quick_actions'.tr,
              style: context.typography.categoryHeader.copyWith(
                letterSpacing: 1.0,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ScaleOnPress(
                    onTap: () {
                      final mainCtrl = Get.isRegistered<MainLayoutController>()
                          ? Get.find<MainLayoutController>()
                          : null;
                      if (mainCtrl != null) {
                        mainCtrl.changeIndex(3); // Clients Screen
                      } else {
                        Get.to(() => const ClientsScreen());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 16,
                            color: context.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'add_client'.tr,
                            style: context.typography.buttonText.copyWith(
                              fontSize: 12,
                              color:
                                  (Theme.of(
                                    context,
                                  ).textTheme.displayLarge?.color ??
                                  Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ScaleOnPress(
                    onTap: () {
                      final mainCtrl = Get.isRegistered<MainLayoutController>()
                          ? Get.find<MainLayoutController>()
                          : null;
                      if (mainCtrl != null) {
                        mainCtrl.changeIndex(1); // Invoices Screen
                      } else {
                        Get.to(() => const InvoiceListScreen());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.arrowRight,
                            size: 16,
                            color: context.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'all_invoices'.tr,
                            style: context.typography.buttonText.copyWith(
                              fontSize: 12,
                              color:
                                  (Theme.of(
                                    context,
                                  ).textTheme.displayLarge?.color ??
                                  Colors.black),
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
  }
}

// --- ANIMATION & HOVER WIDGETS ---

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
      duration: const Duration(milliseconds: 80),
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

class HoverScaleContainer extends StatefulWidget {
  final Widget child;
  const HoverScaleContainer({super.key, required this.child});

  @override
  State<HoverScaleContainer> createState() => _HoverScaleContainerState();
}

class _HoverScaleContainerState extends State<HoverScaleContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.diagonal3Values(
          _isHovered ? 1.02 : 1.0,
          _isHovered ? 1.02 : 1.0,
          1.0,
        ),
        child: widget.child,
      ),
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
      begin: const Offset(0.0, 0.04),
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

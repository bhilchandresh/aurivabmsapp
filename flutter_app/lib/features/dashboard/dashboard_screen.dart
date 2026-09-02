import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_extensions.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../clients/clients_controller.dart';
import '../expenses/expenses_controller.dart';
import '../expenses/widgets/expense_list_item.dart';
import '../invoices/create_invoice_screen.dart';
import '../invoices/invoice_details_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../clients/clients_screen.dart';
import '../expenses/expenses_screen.dart';
import '../clients/select_client_screen.dart';
import '../auth/auth_controller.dart';
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
  final DashboardController dashboardController = Get.put(DashboardController());

  // Quick Payment form variables
  String? _selectedClientId;
  final _paymentAmountController = TextEditingController();
  final String _paymentMode = 'Bank Transfer';
  bool _isLoggingPayment = false;

  // Chart state
  String _chartView = 'monthly'; // 'monthly' or 'yearly'
  String _globalFilter = 'Lifetime';
  bool _isManualRefreshing = false;

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
      'Dashboard Quick Collect',
    );

    // Give a brief delay for UI state to settle
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isLoggingPayment = false;
        _paymentAmountController.clear();
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
    if (plan == 'enterprise') return 'BUSINESS PLAN';
    if (plan == 'premium') return 'PRO PLAN';
    return 'STARTER PLAN';
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

  bool _isDateInFilter(DateTime? date, String filter) {
    if (filter == 'Lifetime' || date == null) return true;
    final now = DateTime.now();
    if (filter == 'This Year') {
      return date.year == now.year;
    } else if (filter == 'This Month') {
      return date.year == now.year && date.month == now.month;
    } else if (filter == 'Today') {
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }
    return true;
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Obx(() {
            final isLoading = dashboardController.isLoading.value;
            final showSkeleton = isLoading;
            final bool useDummy = showSkeleton;

            // --- Real-time stats from Backend API ---
            double totalRevenue = dashboardController.totalRevenue.value;
            double totalPendingAmount = dashboardController.totalPendingAmount.value;
            int totalInvoices = dashboardController.totalInvoices.value;
            int paidCount = dashboardController.paidInvoices.value;
            int pendingCount = dashboardController.pendingCount.value;
            double totalExpenses = dashboardController.totalExpenses.value;
            double netProfit = dashboardController.netProfit.value;
            double totalReceived = totalRevenue - totalPendingAmount;
            int successRate = totalInvoices > 0 ? ((paidCount / totalInvoices) * 100).round() : 0;
            
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.hexagon,
                                                  size: 12,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Obx(() {
                                                  final role = authController.userRole.value.toUpperCase();
                                                  String displayRole = 'USER';
                                                  if (role.isNotEmpty) {
                                                    displayRole = role.replaceAll('_', ' ');
                                                  }
                                                  return Text(
                                                    displayRole,
                                                    style: context.typography.roleBadgeText.copyWith(
                                                      color: context.colorScheme.primary,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'welcome_back'.tr,
                                            style: context.typography.screenTitle.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                authController.userName.value.isNotEmpty
                                                    ? authController.userName.value
                                                    : 'Admin',
                                                style: context.typography.screenTitle.copyWith(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF4F46E5), // Match the primary color
                                                ),
                                              ),
                                              Text(
                                                ' 👋',
                                                style: context.typography.screenTitle.copyWith(
                                                  fontSize: 20,
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
                                  final tenant = authController.tenantInfo.value;
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
                                            : const Color(0xFFF0F9FF), // lighter blue
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isWarning
                                              ? Colors.red.withValues(alpha: 0.15)
                                              : const Color(0xFFE0F2FE),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.crown,
                                            size: 14,
                                            color: isWarning ? Colors.red : const Color(0xFF0284C7),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            planName.toUpperCase(),
                                            style: context.typography.roleBadgeText.copyWith(
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
                                            style: context.typography.statusLabel.copyWith(
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

                        Widget buildNewInvoiceButton({
                          bool isFullWidth = false,
                        }) {
                          return ScaleOnPress(
                            onTap: () {
                              Get.to(() => const CreateInvoiceScreen());
                            },
                            child: Container(
                              width: isFullWidth ? double.infinity : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFF4F46E5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: isFullWidth
                                    ? MainAxisSize.max
                                    : MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'new_invoice'.tr,
                                    style: context.typography.buttonText.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        Widget buildFilterDropdown({bool isFullWidth = false}) {
                          return Container(
                            width: isFullWidth ? double.infinity : null,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _globalFilter,
                                isDense: true,
                                icon: const Icon(LucideIcons.chevronDown, size: 16),
                                isExpanded: isFullWidth,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                items: ['Lifetime', 'This Year', 'This Month', 'Today']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) async {
                                  if (newValue != null && newValue != _globalFilter) {
                                    setState(() {
                                      _globalFilter = newValue;
                                      _isManualRefreshing = true;
                                    });
                                    await Future.wait([
                                      clientsController.fetchClients(),
                                      expensesController.fetchExpenses(),
                                      Future.delayed(const Duration(milliseconds: 600)),
                                    ]);
                                    if (mounted) {
                                      setState(() {
                                        _isManualRefreshing = false;
                                      });
                                    }
                                  }
                                },
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
                              Row(
                                children: [
                                  Expanded(
                                    flex: 35,
                                    child: buildFilterDropdown(isFullWidth: true),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 65,
                                    child: buildNewInvoiceButton(isFullWidth: true),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: buildWelcomeHeader()),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  buildFilterDropdown(),
                                  const SizedBox(width: 12),
                                  buildNewInvoiceButton(isFullWidth: false),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- STATS CARDS GRID (6 Cards) ---
                  // --- STATS CARDS LISTVIEW ---
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
                      switch (index) {
                        case 0:
                          return _buildStatCard(
                            title: 'revenue'.tr,
                            value: formatCurrency.format(totalRevenue),
                            subtitle: 'income_arrow'.tr,
                            icon: LucideIcons.wallet,
                            color: tailwindEmerald,
                            bgColor: tailwindEmeraldLight,
                            delay: 50,
                          );
                        case 1:
                          return _buildStatCard(
                            title: 'expenses_caps'.tr,
                            value: formatCurrency.format(totalExpenses),
                            subtitle: 'outflow'.tr,
                            icon: LucideIcons.trendingUp,
                            iconRotation: 3.1415, // upside down
                            color: tailwindRose,
                            bgColor: tailwindRoseLight,
                            delay: 100,
                          );
                        case 2:
                          return _buildStatCard(
                            title: 'NET PROFIT',
                            value: formatCurrency.format(netProfit),
                            subtitle: 'Rev - (Exp + Purchases)',
                            icon: LucideIcons.trendingUp,
                            color: context.colorScheme.primary,
                            bgColor: AppColors.primary.withValues(alpha: 0.1),
                            isFeatured: true,
                            delay: 150,
                          );
                        case 3:
                          return _buildStatCard(
                            title: 'pending'.tr,
                            value: formatCurrency.format(totalPendingAmount),
                            subtitle: '$pendingCount ${'unpaid'.tr}',
                            icon: LucideIcons.clock,
                            color: tailwindAmber,
                            bgColor: tailwindAmberLight,
                            delay: 200,
                          );
                        case 4:
                          return _buildStatCard(
                            title: 'invoices'.tr,
                            value: '$totalInvoices',
                            subtitle: 'lifetime_billed'.tr,
                            icon: LucideIcons.fileText,
                            color: tailwindViolet,
                            bgColor: tailwindVioletLight,
                            delay: 250,
                          );
                        case 5:
                        default:
                          return _buildStatCard(
                            title: 'RECEIVED',
                            value: formatCurrency.format(totalReceived),
                            subtitle: 'Payment collected',
                            icon: LucideIcons.checkCircle,
                            color: tailwindPurple,
                            bgColor: tailwindPurpleLight,
                            delay: 300,
                          );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- MAIN LAYOUT (Recent Invoices & Quick Actions) ---
                  Column(
                    children: [
                      _buildRecentInvoices(dashboardController.recentInvoices, isDark),
                      const SizedBox(height: 16),
                      _buildRecentExpenses(dashboardController.recentExpenses, isDark),
                      const SizedBox(height: 16),
                      _buildQuickCollectPayment(isDark),
                      const SizedBox(height: 16),
                      _buildQuickActions(isDark),
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
    required IconData icon,
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
            color: (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: isDark ? 0.6 : 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFeatured
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              width: isFeatured ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
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
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Transform.rotate(
                              angle: iconRotation,
                              child: Icon(
                                icon,
                                size: isSmall ? 14 : 16,
                                color: color,
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
                                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
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
                              : ((Theme.of(context).textTheme.displayLarge?.color ?? Colors.black)),
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
              if (isFeatured) Container(height: 4, color: context.colorScheme.primary),
            ],
          ),
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
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: isDark ? 0.6 : 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
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
                  child: Icon(LucideIcons.fileText, color: context.colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Invoices',
                        style: context.typography.cardTitle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Latest billing activities',
                        style: context.typography.cardSubtitle.copyWith(
                          fontSize: 11,
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
                      Icon(LucideIcons.chevronRight, size: 14, color: context.colorScheme.primary),
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
                  final String clientName = clientObj['name'] ?? 'Unknown Client';
                  final String status = inv['status'] ?? 'Pending';
                  final bool isPaid = status.toLowerCase() == 'paid';
                  
                  final double totalAmount = (inv['totalAmount'] ?? 0).toDouble();
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
                      final rawInvoice = clientsController.allInvoices.firstWhere(
                        (json) =>
                            (json['invoiceNumber'] == invoiceNumber) ||
                            (json['_id'] ?? json['id']) == id,
                        orElse: () => {},
                      );
                      if (rawInvoice.isNotEmpty) {
                        final rawClientObj = rawInvoice['client'] ?? {};
                        final String clientEmail = rawClientObj['email'] ?? '';
                        final String clientAddress = rawClientObj['address'] ?? '';
                        final String clientGst =
                            rawClientObj['gstin'] ?? rawClientObj['gstNumber'] ?? '';
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
                            invoiceId: invoiceNumber.isNotEmpty ? invoiceNumber : id,
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
                            invoiceId: invoiceNumber.isNotEmpty ? invoiceNumber : id,
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
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: isPaid ? tailwindEmerald : tailwindAmber,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPaid ? tailwindEmeraldLight : tailwindAmberLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPaid ? LucideIcons.check : LucideIcons.clock,
                                  size: 16,
                                  color: isPaid ? tailwindEmerald : tailwindAmber,
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
                                      style: context.typography.clientName.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: context.colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            invoiceNumber,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: context.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        if (inv['createdBy'] != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: context.colorScheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(LucideIcons.user, size: 9, color: context.colorScheme.primary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  inv['createdBy']['name'] ?? 'User',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: context.colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      displayDate,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                    style: context.typography.invoiceAmount.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? tailwindEmeraldLight
                                          : tailwindAmberLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status,
                                      style: context.typography.invoiceStatus.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: isPaid
                                            ? tailwindEmerald
                                            : tailwindAmber,
                                      ),
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
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: isDark ? 0.6 : 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Expenses',
                          style: context.typography.cardTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Latest expense activities',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
                    children: [
                      Text(
                        'View All',
                        style: context.typography.buttonText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black87),
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
                separatorBuilder: (context, idx) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final Map<String, dynamic> exp = recentExpenses[idx];
                  
                  String title = exp['description'] ?? '';
                  if (title.trim().isEmpty) {
                    title = exp['category'] ?? 'Expense';
                  }
                  final double amount = (exp['amount'] ?? 0).toDouble();
                  final String rawDate = exp['date'] ?? '';
                  final String user = (exp['createdBy'] != null) ? (exp['createdBy']['name'] ?? '') : '';

                  final expense = Expense(
                    id: exp['_id']?.toString() ?? exp['id']?.toString() ?? idx.toString(),
                    category: exp['category'] ?? '',
                    amount: amount,
                    description: exp['description'] ?? '',
                    date: rawDate,
                    user: user,
                  );

                  return ExpenseListItem(
                    expense: expense,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    onTap: () {}, // Optional details tap for dashboard
                    onDelete: () => Future.value(false), // Optional or disabled delete
                    currencyFormat: NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: '₹',
                      decimalDigits: 0,
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
      delay: const Duration(milliseconds: 450),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: isDark ? 0.6 : 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
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
            Row(
              children: [
                const Icon(
                  LucideIcons.wallet,
                  size: 16,
                  color: tailwindEmerald,
                ),
                const SizedBox(width: 8),
                Text(
                  'collect_payment'.tr,
                  style: context.typography.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom Client Selection Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await Get.to(() => const SelectClientScreen());
                  if (result != null && result is String) {
                    setState(() {
                      _selectedClientId = result;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: _selectedClientId != null ? 0.8 : 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _selectedClientId == null || activeClient == null
                            ? Text(
                                'select_client'.tr,
                                style: context.typography.searchHint.copyWith(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeClient.name,
                                    style: context.typography.inputText.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    ),
                                  ),
                                  if (activeClient.phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      activeClient.phone,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      Icon(
                        _selectedClientId != null ? LucideIcons.edit3 : LucideIcons.chevronDown,
                        size: 16,
                        color: _selectedClientId != null ? context.colorScheme.primary : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Khatabook Ledger balance card
            if (_selectedClientId != null && activeClient != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'total_billed'.tr,
                          style: context.typography.dashboardLabel.copyWith(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formatCurrency.format(activeClient.totalBilled),
                            style: context.typography.dashboardValue.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'total_received'.tr,
                          style: context.typography.dashboardLabel.copyWith(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formatCurrency.format(activeClientTotalPaid),
                            style: context.typography.dashboardValue.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: tailwindEmerald,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ledger_balance'.tr,
                          style: context.typography.dashboardLabel.copyWith(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: activeClient.balance > 0
                              ? Text(
                                  '${formatCurrency.format(activeClient.balance)}${'due'.tr}',
                                  style: context.typography.dashboardValue.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: tailwindRose,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : activeClient.balance < 0
                              ? Text(
                                  '${formatCurrency.format(activeClient.balance.abs())}${'adv'.tr}',
                                  style: context.typography.dashboardValue.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: tailwindBlue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text(
                                  'settled'.tr,
                                  style: context.typography.dashboardValue.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: tailwindEmerald,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Payment Inputs (Amount & Submit Button)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: TextField(
                      controller: _paymentAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: context.typography.inputText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: ' ₹ ',
                        prefixStyle: context.typography.inputText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ScaleOnPress(
                  onTap: _selectedClientId == null || _isLoggingPayment
                      ? () {}
                      : _handlePaymentSubmit,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedClientId == null
                          ? Colors.grey.shade300
                          : tailwindEmerald,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selectedClientId == null
                          ? null
                          : [
                              BoxShadow(
                                color: tailwindEmerald.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
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
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.checkCircle,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'log_pay'.tr,
                                style: context.typography.buttonText.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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

  Widget _buildQuickActions(bool isDark) {
    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: isDark ? 0.6 : 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
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
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                              color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
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
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                              color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
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

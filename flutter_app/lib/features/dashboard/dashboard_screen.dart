import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../clients/clients_controller.dart';
import '../expenses/expenses_controller.dart';
import '../invoices/create_invoice_screen.dart';
import '../invoices/invoice_details_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../clients/clients_screen.dart';
import '../auth/auth_controller.dart';
import '../../navigation/main_layout.dart';

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

  // Quick Payment form variables
  String? _selectedClientId;
  final _paymentAmountController = TextEditingController();
  final String _paymentMode = 'Bank Transfer';
  bool _isLoggingPayment = false;

  // Chart state
  String _chartView = 'monthly'; // 'monthly' or 'yearly'
  bool _isManualRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Refresh backend data when dashboard is mounted
    clientsController.fetchClients();
    expensesController.fetchExpenses();
    authController.fetchTenantSettings();
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
        backgroundColor: Color(0xFFEF4444),
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
        backgroundColor: Color(0xFFEF4444),
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
        backgroundColor: Color(0xFF10B981),
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
    var parsed = DateTime.tryParse(clean);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'dashboard'.tr,
        subtitle: 'overview_insights'.tr,
        showMenu: false,
        showProfile: true,
        showBadge: true,
        showNotification: true,
        showBackButton: false,
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
            final isLoading =
                clientsController.isLoading.value ||
                expensesController.isLoading.value;
            final isFirstLoad =
                clientsController.clients.isEmpty &&
                expensesController.expenses.isEmpty;
            final showSkeleton =
                isLoading && (isFirstLoad || _isManualRefreshing);
            final bool useDummy = showSkeleton;

            // --- Calculate Real-time stats ---
            final allInvoices = <Map<String, dynamic>>[];
            double totalRevenue = 0.0;
            double totalPendingAmount = 0.0;
            int paidCount = 0;
            int pendingCount = 0;
            List<Map<String, dynamic>> recentInvoices = [];
            double totalExpenses = 0.0;
            double netProfit = 0.0;
            int totalInvoices = 0;
            int successRate = 0;

            if (useDummy) {
              totalRevenue = 250000.0;
              totalExpenses = 85000.0;
              netProfit = totalRevenue - totalExpenses;
              totalPendingAmount = 65000.0;
              totalInvoices = 16;
              paidCount = 12;
              pendingCount = 4;
              successRate = 75;

              recentInvoices = List.generate(3, (idx) {
                final inv = ClientInvoice(
                  id: 'loading_id_$idx',
                  invoiceNumber: 'INV-2026-000$idx',
                  totalAmount: 25000.0,
                  remainingAmount: idx == 0 ? 0.0 : 25000.0,
                  date: '2026-06-10T00:00:00Z',
                  status: idx == 0 ? 'Paid' : 'Pending',
                );
                final client = Client(
                  id: 'loading_client_$idx',
                  name: 'Placeholder Client Name',
                  email: 'client@example.com',
                  phone: '9876543210',
                  gstin: '07AAAAA0000A1Z0',
                  state: 'Delhi',
                  address: 'Placeholder Address',
                  totalBilled: 25000.0,
                  balance: idx == 0 ? 0.0 : 25000.0,
                );
                return {'invoice': inv, 'client': client};
              });
            } else {
              for (var item in clientsController.allInvoices) {
                final Map<String, dynamic> invMap = Map<String, dynamic>.from(
                  item,
                );
                final inv = ClientInvoice.fromJson(invMap);

                final clientObj = invMap['client'] ?? {};
                final String clientId =
                    clientObj['clientId'] ??
                    clientObj['id'] ??
                    clientObj['_id'] ??
                    '';

                final client = clientsController.clients.firstWhere(
                  (c) => c.id == clientId,
                  orElse: () => Client(
                    id: clientId,
                    name: clientObj['name'] ?? 'Unknown',
                    email: clientObj['email'] ?? '',
                    phone: clientObj['phone'] ?? '',
                    gstin: clientObj['gstin'] ?? clientObj['gstNumber'] ?? '',
                    state: clientObj['state'] ?? '',
                    address: clientObj['address'] ?? '',
                    totalBilled: (clientObj['totalBilled'] ?? 0).toDouble(),
                    balance: (clientObj['balance'] ?? 0).toDouble(),
                  ),
                );

                allInvoices.add({'invoice': inv, 'client': client});

                totalRevenue += inv.totalAmount;
                final statusLower = inv.status.toLowerCase();
                if (statusLower == 'pending' || statusLower == 'overdue') {
                  totalPendingAmount += inv.totalAmount;
                }

                if (statusLower == 'paid') {
                  paidCount++;
                } else if (statusLower == 'pending' ||
                    statusLower == 'overdue') {
                  pendingCount++;
                }
              }

              // Sort invoices by date desc
              allInvoices.sort((a, b) {
                final invA = a['invoice'] as ClientInvoice;
                final invB = b['invoice'] as ClientInvoice;
                final dateA = _parseDate(invA.date) ?? DateTime(2000);
                final dateB = _parseDate(invB.date) ?? DateTime(2000);
                return dateB.compareTo(dateA);
              });

              // Take recent 5
              recentInvoices = allInvoices.take(5).toList();

              totalExpenses = expensesController.totalAllTimeSpent;
              netProfit = totalRevenue - totalExpenses;
              totalInvoices = allInvoices.length;
              successRate = totalInvoices > 0
                  ? ((paidCount / totalInvoices) * 100).round()
                  : 0;
            }

            // --- Dynamic Monthly & Yearly Chart Grouping ---
            final monthNames = [
              "Jan",
              "Feb",
              "Mar",
              "Apr",
              "May",
              "Jun",
              "Jul",
              "Aug",
              "Sep",
              "Oct",
              "Nov",
              "Dec",
            ];

            // Generate last 6 months in chronological order
            final List<Map<String, dynamic>> monthlyData = [];
            final Map<String, int> monthToIndex = {};
            final now = DateTime.now();
            final currentYear = DateTime.now().year;

            if (useDummy) {
              for (int i = 5; i >= 0; i--) {
                final d = DateTime(now.year, now.month - i, 1);
                final mName = monthNames[d.month - 1];
                monthlyData.add({
                  'name': mName,
                  'income': 50000.0 + (i * 10000.0),
                  'expense': 20000.0 + (i * 5000.0),
                });
              }
            } else {
              for (int i = 5; i >= 0; i--) {
                final d = DateTime(now.year, now.month - i, 1);
                final mName = monthNames[d.month - 1];
                monthlyData.add({'name': mName, 'income': 0.0, 'expense': 0.0});
                monthToIndex[mName] = monthlyData.length - 1;
              }

              // Group invoices into monthlyData
              for (var item in allInvoices) {
                final inv = item['invoice'] as ClientInvoice;
                final date = _parseDate(inv.date);
                if (date != null) {
                  final mName = monthNames[date.month - 1];
                  if (monthToIndex.containsKey(mName)) {
                    final idx = monthToIndex[mName]!;
                    monthlyData[idx]['income'] =
                        (monthlyData[idx]['income'] as double) +
                        inv.totalAmount;
                  }
                }
              }

              // Group expenses into monthlyData
              for (var exp in expensesController.expenses) {
                final date = _parseDate(exp.date);
                if (date != null) {
                  final mName = monthNames[date.month - 1];
                  if (monthToIndex.containsKey(mName)) {
                    final idx = monthToIndex[mName]!;
                    monthlyData[idx]['expense'] =
                        (monthlyData[idx]['expense'] as double) + exp.amount;
                  }
                }
              }
            }

            // Generate last 5 years
            final List<Map<String, dynamic>> yearlyData = [];
            final Map<String, int> yearToIndex = {};

            if (useDummy) {
              for (int i = 4; i >= 0; i--) {
                final yName = (currentYear - i).toString();
                yearlyData.add({
                  'name': yName,
                  'income': 500000.0 + (i * 100000.0),
                  'expense': 200000.0 + (i * 50000.0),
                });
              }
            } else {
              for (int i = 4; i >= 0; i--) {
                final yName = (currentYear - i).toString();
                yearlyData.add({'name': yName, 'income': 0.0, 'expense': 0.0});
                yearToIndex[yName] = yearlyData.length - 1;
              }

              // Group invoices into yearlyData
              for (var item in allInvoices) {
                final inv = item['invoice'] as ClientInvoice;
                final date = _parseDate(inv.date);
                if (date != null) {
                  final yName = date.year.toString();
                  if (yearToIndex.containsKey(yName)) {
                    final idx = yearToIndex[yName]!;
                    yearlyData[idx]['income'] =
                        (yearlyData[idx]['income'] as double) + inv.totalAmount;
                  }
                }
              }

              // Group expenses into yearlyData
              for (var exp in expensesController.expenses) {
                final date = _parseDate(exp.date);
                if (date != null) {
                  final yName = date.year.toString();
                  if (yearToIndex.containsKey(yName)) {
                    final idx = yearToIndex[yName]!;
                    yearlyData[idx]['expense'] =
                        (yearlyData[idx]['expense'] as double) + exp.amount;
                  }
                }
              }
            }

            final chartData = _chartView == 'monthly'
                ? monthlyData
                : yearlyData;

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
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'welcome_back'.tr,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  Text(
                                    authController.userName.value.isNotEmpty
                                        ? authController.userName.value
                                        : 'Admin',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    ' 👋',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
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

                                return Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isWarning
                                        ? Colors.red.withValues(alpha: 0.08)
                                        : Color(
                                            0xFFE0F2FE,
                                          ), // light blue-50
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isWarning
                                          ? Colors.red.withValues(alpha: 0.15)
                                          : Color(0xFFBAE6FD),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        planName.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: isWarning
                                              ? Colors.red
                                              : Color(0xFF0369A1),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isWarning
                                              ? Colors.red
                                              : Color(0xFF0369A1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        daysLeft > 0
                                            ? '$daysLeft ${'days_left'.tr}'
                                            : 'expired'.tr,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isWarning
                                              ? Colors.red
                                              : Color(0xFF0284C7),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
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
                                    color: AppColors.primary.withValues(
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
                                  Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'new_invoice'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
                              buildNewInvoiceButton(isFullWidth: true),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: buildWelcomeHeader()),
                              const SizedBox(width: 12),
                              buildNewInvoiceButton(isFullWidth: false),
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
                      crossAxisCount: context.width < 360
                          ? 1
                          : (context.width < 600 ? 2 : 3),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: context.width < 360
                          ? 2.5
                          : (context.width < 600 ? 1.15 : 1.35),
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
                            title: 'net_profit'.tr,
                            value: formatCurrency.format(netProfit),
                            subtitle: 'bottom_line'.tr,
                            icon: LucideIcons.trendingUp,
                            color: AppColors.primary,
                            bgColor: AppColors.primary.withValues(alpha: 0.1),
                            isFeatured: false,
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
                            title: 'success'.tr,
                            value: '$successRate%',
                            subtitle: 'invoices_paid'.tr,
                            icon: LucideIcons.checkCircle,
                            color: tailwindPurple,
                            bgColor: tailwindPurpleLight,
                            delay: 300,
                          );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- MAIN LAYOUT RESPONSIVE COLUMNS (Chart + Side panels) ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 950;

                      final chartSection = _buildChartSection(
                        chartData,
                        isDark,
                      );
                      final sideSection = Column(
                        children: [
                          _buildRecentInvoices(recentInvoices, isDark),
                          const SizedBox(height: 16),
                          _buildQuickCollectPayment(isDark),
                          const SizedBox(height: 16),
                          _buildQuickActions(isDark),
                        ],
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: chartSection),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: sideSection),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            chartSection,
                            const SizedBox(height: 16),
                            sideSection,
                          ],
                        );
                      }
                    },
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
            color: (Theme.of(context).cardTheme.color ?? Colors.white).withOpacity(isDark ? 0.6 : 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFeatured
                  ? AppColors.primary.withOpacity(0.5)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.5),
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
                    horizontal: isSmall ? 12.0 : 16.0,
                    vertical: isSmall ? 8.0 : 12.0,
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
                              style: TextStyle(
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
                        style: TextStyle(
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
                        style: TextStyle(
                          fontSize: isSmall ? 9 : 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isFeatured) Container(height: 4, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(List<Map<String, dynamic>> chartData, bool isDark) {
    // Find maximum Y value for nice scaling
    double maxY = 100000.0;
    for (var m in chartData) {
      final inc = m['income'] as double;
      final exp = m['expense'] as double;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    // Round to next nice number
    maxY = (maxY * 1.15).ceilToDouble();
    if (maxY == 0) maxY = 1000.0;

    return FadeInUp(
      delay: const Duration(milliseconds: 350),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withOpacity(isDark ? 0.6 : 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'revenue_overview'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'income_expense_comparison'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _chartView,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _chartView = val;
                          });
                        }
                      },
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                      ),
                      icon: Icon(LucideIcons.chevronDown, size: 14),
                      items: [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('last_6_months'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'yearly',
                          child: Text('last_5_years'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Legends
            Row(
              children: [
                _buildLegendItem('income'.tr, AppColors.primary),
                const SizedBox(width: 16),
                _buildLegendItem('expense'.tr, tailwindRose),
              ],
            ),
            const SizedBox(height: 20),
            // Chart wrapper
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: maxY,
                  barGroups: chartData.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    final inc = m['income'] as double;
                    final exp = m['expense'] as double;

                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: inc,
                          color: AppColors.primary,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: exp,
                          color: tailwindRose,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < chartData.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                chartData[idx]['name'] as String,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (val, meta) {
                          String label = '';
                          if (val >= 1000000) {
                            label = '₹${(val / 1000000).toStringAsFixed(1)}M';
                          } else if (val >= 1000) {
                            label = '₹${(val / 1000).toStringAsFixed(0)}k';
                          } else {
                            label = '₹${val.toStringAsFixed(0)}';
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Color(0xFF0F172A),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final title = rodIndex == 0
                            ? 'income'.tr
                            : 'expense'.tr;
                        return BarTooltipItem(
                          '$title\n${formatCurrency.format(rod.toY)}',
                          TextStyle(
                            color: rodIndex == 0
                                ? Colors.blue.shade200
                                : Colors.red.shade200,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentInvoices(
    List<Map<String, dynamic>> recentInvoices,
    bool isDark,
  ) {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withOpacity(isDark ? 0.6 : 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'recent_invoices'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'latest_billing_activities'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                      ),
                    ),
                  ],
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
                  child: Text(
                    'view_all'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
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
                    style: TextStyle(
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
                separatorBuilder: (context, idx) =>
                    Divider(height: 12, color: Theme.of(context).colorScheme.outline),
                itemBuilder: (context, idx) {
                  final entry = recentInvoices[idx];
                  final inv = entry['invoice'] as ClientInvoice;
                  final client = entry['client'] as Client;
                  final isPaid = inv.status.toLowerCase() == 'paid';

                  String displayDate = inv.date;
                  final parsedDate = _parseDate(inv.date);
                  if (parsedDate != null) {
                    displayDate = DateFormat('dd MMM yyyy').format(parsedDate);
                  } else if (displayDate.contains('T')) {
                    displayDate = displayDate.split('T')[0];
                  } else if (displayDate.contains(' ')) {
                    // Try to split only if it looks like a standard datetime, not '10 Jun 2026'
                    if (displayDate.split(' ').length > 2) {
                      // Probably already formatted or something else
                    } else {
                      displayDate = displayDate.split(' ')[0];
                    }
                  }

                  return ScaleOnPress(
                    onTap: () {
                      final rawInvoice = clientsController.allInvoices
                          .firstWhere(
                            (json) =>
                                (json['invoiceNumber'] == inv.invoiceNumber) ||
                                (json['_id'] ?? json['id']) == inv.id,
                            orElse: () => null,
                          );
                      if (rawInvoice != null) {
                        final clientObj = rawInvoice['client'] ?? {};
                        final String clientEmail = clientObj['email'] ?? '';
                        final String clientAddress = clientObj['address'] ?? '';
                        final String clientGst =
                            clientObj['gstin'] ?? clientObj['gstNumber'] ?? '';
                        final String placeOfSupply =
                            rawInvoice['placeOfSupply'] ??
                            clientObj['state'] ??
                            '';
                        final List<dynamic> rawItems =
                            rawInvoice['items'] ?? [];
                        final List<Map<String, dynamic>> items =
                            List<Map<String, dynamic>>.from(
                              rawItems.map((x) => Map<String, dynamic>.from(x)),
                            );

                        Get.to(
                          () => InvoiceDetailsScreen(
                            invoiceId: inv.invoiceNumber.isNotEmpty
                                ? inv.invoiceNumber
                                : inv.id,
                            dbId: inv.id,
                            clientName: client.name,
                            amount: inv.totalAmount,
                            date: inv.date,
                            status: inv.status,
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
                            invoiceId: inv.invoiceNumber.isNotEmpty
                                ? inv.invoiceNumber
                                : inv.id,
                            dbId: inv.id,
                            clientName: client.name,
                            amount: inv.totalAmount,
                            date: inv.date,
                            status: inv.status,
                          ),
                        );
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? tailwindEmeraldLight
                                  : tailwindAmberLight,
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
                                  client.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${inv.invoiceNumber} • $displayDate',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency.format(inv.totalAmount),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                ),
                              ),
                              const SizedBox(height: 2),
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
                                  inv.status,
                                  style: TextStyle(
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
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withOpacity(isDark ? 0.6 : 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
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
                Icon(
                  LucideIcons.wallet,
                  size: 16,
                  color: tailwindEmerald,
                ),
                const SizedBox(width: 8),
                Text(
                  'collect_payment'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dropdown Client Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  style: TextStyle(
                    fontSize: 13,
                    color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                    fontFamily: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.fontFamily,
                  ),
                  hint: Text(
                    'select_client'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  isExpanded: true,
                  onChanged: (val) {
                    setState(() {
                      _selectedClientId = val;
                    });
                  },
                  items: clientsController.clients.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                        ),
                      ),
                    );
                  }).toList(),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formatCurrency.format(activeClient.totalBilled),
                            style: TextStyle(
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formatCurrency.format(activeClientTotalPaid),
                            style: TextStyle(
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
                          style: TextStyle(
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
                                  style: TextStyle(
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: tailwindBlue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text(
                                  'settled'.tr,
                                  style: TextStyle(
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: ' ₹ ',
                        prefixStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
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
                              Icon(
                                LucideIcons.checkCircle,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'log_pay'.tr,
                                style: TextStyle(
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
          color: (Theme.of(context).cardTheme.color ?? Colors.white).withOpacity(isDark ? 0.6 : 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
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
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade400,
                letterSpacing: 1.0,
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
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'add_client'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'all_invoices'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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

// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../companies/super_admin_add_company_screen.dart';
import '../companies/super_admin_edit_company_screen.dart';
import '../widgets/super_admin_top_bar.dart';
import 'super_admin_dashboard_controller.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  SuperAdminDashboardScreen({super.key});

  final controller = Get.put(SuperAdminDashboardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light gray background
      body: SafeArea(
        child: Column(
          children: [
            const SuperAdminTopBar(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return _buildDashboardSkeleton(context);
                }
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildMetricsCards(context),
                        ]),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyHeaderDelegate(
                        minHeight:
                            70, // Estimated height of search bar container
                        maxHeight: 70,
                        backgroundColor: const Color(
                          0xFFF8FAFC,
                        ), // Same as scaffold background to cover content behind
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildSearchBar(context),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildCompaniesTableBody(context),
                        ]),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF5B6CF9), Color(0xFF8672F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B6CF9).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  LucideIcons.barChart2,
                  size: isMobile ? 80 : 120,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              Positioned(
                right: isMobile ? 60 : 100,
                bottom: -20,
                child: Icon(
                  LucideIcons.pieChart,
                  size: isMobile ? 50 : 80,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'super_admin'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 18 : 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '👋',
                                style: TextStyle(fontSize: isMobile ? 16 : 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'here_is_whats_happening'.tr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () =>
                          Get.to(() => const SuperAdminAddCompanyScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.plus,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isMobile ? 'New' : 'New Company',
                              style: TextStyle(
                                color: Colors.blue.shade700,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardSkeleton(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Colorful shimmer effect parameters
    final baseColor = Colors.blue.shade50;
    final highlightColor = Colors.white;
    final skeletonBg = Colors.blue.withValues(alpha: 0.1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      width: 200,
                      height: 32,
                      decoration: BoxDecoration(
                        color: skeletonBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      width: 250,
                      height: 16,
                      decoration: BoxDecoration(
                        color: skeletonBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Metrics Grid Skeleton
          GridView.count(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 1.3 : 2.2,
            children: List.generate(
              4,
              (index) => Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: skeletonBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: skeletonBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: skeletonBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // List Skeleton
          Container(
            width: double.infinity,
            decoration: isMobile
                ? null
                : BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: skeletonBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (!isMobile) const Divider(height: 1),
                ...List.generate(
                  4,
                  (index) => Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: skeletonBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 120,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: skeletonBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 80,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: skeletonBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 16,
                                margin: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: skeletonBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 16,
                                margin: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: skeletonBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 16,
                                margin: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: skeletonBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: skeletonBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(BuildContext context) {
    final stats = controller.stats.value;
    final width = MediaQuery.of(context).size.width;

    // Always use at least a 2-column grid to match the image, 4 on desktop
    final int crossAxisCount = width < 800 ? 2 : 4;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: width < 800 ? 12 : 16,
      mainAxisSpacing: width < 800 ? 12 : 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: width < 800 ? 1.6 : 2.5,
      children: [
        _buildNewMetricCard(
          LucideIcons.building,
          'TOTAL COMPANIES',
          stats?.totalTenants.toString() ?? '12',
          Colors.blue,
        ),
        _buildNewMetricCard(
          LucideIcons.checkCircle2,
          'ACTIVE SUBS',
          stats?.activeTenants.toString() ?? '12',
          Colors.green,
        ),
        _buildNewMetricCard(
          LucideIcons.users,
          'TOTAL USERS',
          stats?.totalUsers.toString() ?? '14',
          Colors.purple,
        ),
        _buildNewMetricCard(
          LucideIcons.indianRupee,
          'MONTHLY REV',
          '₹${stats?.estRevenue ?? '3,888'}',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildNewMetricCard(
    IconData icon,
    String title,
    String value,
    MaterialColor color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 50,
              child: CustomPaint(painter: _WavePainter(color)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color.shade600, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      decoration: isMobile
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
                left: BorderSide(color: Colors.grey.shade200),
                right: BorderSide(color: Colors.grey.shade200),
              ),
            ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 10 : 12,
        horizontal: isMobile ? 0 : 20,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isMobile ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: controller.updateSearchQuery,
          decoration: InputDecoration(
            icon: Icon(
              LucideIcons.search,
              color: Colors.grey.shade400,
              size: 20,
            ),
            hintText: 'search_companies'.tr,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCompaniesTableBody(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final companies = controller.filteredTenants;

    return Container(
      decoration: isMobile
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
                left: BorderSide(color: Colors.grey.shade200),
                right: BorderSide(color: Colors.grey.shade200),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const Divider(height: 1),
          if (isMobile)
            Column(
              children: companies.map((t) {
                final isPro = t.subscriptionPlan == 'premium';
                final isBusiness = t.subscriptionPlan == 'enterprise';
                final rate = t.subscriptionPlan == 'enterprise'
                    ? '₹999'
                    : (isPro ? '₹499' : '₹299');
                final planName = isBusiness
                    ? 'BUSINESS'
                    : (isPro ? 'PRO' : 'STARTER');
                final expiryDateStr = t.subscriptionEnd != null
                    ? DateFormat('dd MMM yyyy').format(t.subscriptionEnd!)
                    : 'N/A';
                return _buildMobileCompanyCard(
                  context: context,
                  tenantId: t.id,
                  name: t.name,
                  email: t.email,
                  plan: planName,
                  rate: rate,
                  expiryDate: expiryDateStr,
                  daysLeft: t.daysLeft,
                  isExpired: t.isExpired,
                  isPro: isPro,
                  isBusiness: isBusiness,
                );
              }).toList(),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      width: 800,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'company'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'plan_rate'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'expiry_timeline'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'status'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'manage'.tr,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Table Body
                    ...companies.map((t) {
                      final isPro = t.subscriptionPlan == 'premium';
                      final isBusiness = t.subscriptionPlan == 'enterprise';
                      final rate = t.subscriptionPlan == 'enterprise'
                          ? '₹999'
                          : (isPro ? '₹499' : '₹299');
                      final planName = isBusiness
                          ? 'BUSINESS'
                          : (isPro ? 'PRO' : 'STARTER');
                      final expiryDateStr = t.subscriptionEnd != null
                          ? DateFormat('dd MMM yyyy').format(t.subscriptionEnd!)
                          : 'N/A';
                      return Column(
                        children: [
                          _buildCompanyRow(
                            context: context,
                            tenantId: t.id,
                            name: t.name,
                            email: t.email,
                            plan: planName,
                            rate: rate,
                            expiryDate: expiryDateStr,
                            daysLeft: t.daysLeft,
                            isExpired: t.isExpired,
                            isPro: isPro,
                            isBusiness: isBusiness,
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showUsageDialog(BuildContext context, String tenantId) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    final data = await controller.fetchTenantUsage(tenantId);
    if (Get.isDialogOpen ?? false) Get.back(); // close loading

    if (data == null) {
      Get.snackbar(
        'Error',
        'Failed to fetch usage data',
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'usage'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildUsageCard(
                    'INVOICES',
                    data['invoiceCount'] ?? 0,
                    Colors.blue,
                  ),
                  _buildUsageCard(
                    'QUOTATIONS',
                    data['quotationCount'] ?? 0,
                    Colors.purple,
                  ),
                  _buildUsageCard(
                    'CLIENTS',
                    data['clientCount'] ?? 0,
                    Colors.green,
                  ),
                  _buildUsageCard(
                    'USERS',
                    data['userCount'] ?? 0,
                    Colors.amber,
                  ),
                  _buildUsageCard(
                    'ITEMS (INV)',
                    data['inventoryCount'] ?? 0,
                    Colors.orange,
                  ),
                  _buildUsageCard(
                    'SUPPLIERS',
                    data['supplierCount'] ?? 0,
                    Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B), // Dark slate
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: Text(
                    'close'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard(String title, int count, MaterialColor color) {
    return Container(
      decoration: BoxDecoration(
        color: color.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String tenantId,
    String companyName,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_company'.tr),
        content: Text(
          'Are you sure you want to delete "$companyName"? This action will remove all associated data, users, and invoices, and cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () {
              Get.back();
              controller.deleteCompany(tenantId);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyRow({
    required BuildContext context,
    required String tenantId,
    required String name,
    required String email,
    required String plan,
    required String rate,
    required String expiryDate,
    required int daysLeft,
    required bool isExpired,
    bool isPro = false,
    bool isBusiness = false,
  }) {
    Color planColor = Colors.blue.shade600;
    Color planBg = Colors.blue.shade50;
    if (isPro) {
      planColor = Colors.blue.shade600;
      planBg = Colors.blue.shade50;
    } else if (isBusiness) {
      planColor = Colors.blue.shade700;
      planBg = Colors.blue.shade50;
    }

    return Container(
      width: 800,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Company
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          // Plan & Rate
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: planBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    plan,
                    style: TextStyle(
                      color: planColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rate,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          // Expiry Timeline
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        expiryDate,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        isExpired ? 'Expired' : '$daysLeft days left',
                        style: TextStyle(
                          color: isExpired
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isExpired
                          ? 1.0
                          : (daysLeft / 365.0).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isExpired ? Colors.red.shade500 : Colors.green.shade500,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  isExpired ? LucideIcons.xCircle : LucideIcons.checkCircle2,
                  color: isExpired
                      ? Colors.red.shade500
                      : Colors.green.shade500,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'active'.tr,
                  style: TextStyle(
                    color: isExpired
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Manage
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _showUsageDialog(context, tenantId),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: Icon(
                      LucideIcons.lineChart,
                      size: 14,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Get.to(
                    () => SuperAdminEditCompanyScreen(
                      tenant: controller.filteredTenants.firstWhere(
                        (t) => t.name == name,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.edit,
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'manage'.tr,
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showDeleteDialog(context, tenantId, name),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Icon(
                      LucideIcons.trash2,
                      size: 14,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCompanyCard({
    required BuildContext context,
    required String tenantId,
    required String name,
    required String email,
    required String plan,
    required String rate,
    required String expiryDate,
    required int daysLeft,
    required bool isExpired,
    bool isPro = false,
    bool isBusiness = false,
  }) {
    Color planColor = Colors.blue.shade600;
    Color planBg = Colors.blue.shade50;
    if (isPro) {
      planColor = Colors.purple.shade600;
      planBg = Colors.purple.shade50;
    } else if (isBusiness) {
      planColor = Colors.orange.shade700;
      planBg = Colors.orange.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1st Row: Avatar, Company and Plan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Plan Badge
              Container(
                width: 65, // Smaller width
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                ), // Reduced padding for better top alignment
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: planBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plan,
                  style: TextStyle(
                    color: planColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 2nd Row: Expiry Timeline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpired ? 'Subscription Expired' : 'Expires: $expiryDate',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isExpired ? '0 days' : '$daysLeft days left',
                style: TextStyle(
                  color: isExpired
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isExpired ? 1.0 : (daysLeft / 365.0).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExpired ? Colors.red.shade500 : Colors.green.shade500,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          // 3rd Row: Status and Manage buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired
                          ? LucideIcons.xCircle
                          : LucideIcons.checkCircle2,
                      color: isExpired
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExpired ? 'Inactive' : 'Active',
                      style: TextStyle(
                        color: isExpired
                            ? Colors.red.shade600
                            : Colors.green.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                children: [
                  _buildIconButton(
                    LucideIcons.lineChart,
                    Colors.purple,
                    onTap: () => _showUsageDialog(context, tenantId),
                  ),
                  const SizedBox(width: 12),
                  _buildIconButton(
                    LucideIcons.edit,
                    Colors.blue,
                    onTap: () => Get.to(
                      () => SuperAdminEditCompanyScreen(
                        tenant: controller.filteredTenants.firstWhere(
                          (t) => t.name == name,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildIconButton(
                    LucideIcons.trash2,
                    Colors.red,
                    onTap: () => _showDeleteDialog(context, tenantId, name),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    MaterialColor color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: color.shade100.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, size: 16, color: color.shade600),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;
  final Color backgroundColor;

  _StickyHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
    this.backgroundColor = Colors.transparent,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

class _MiniChartPainter extends CustomPainter {
  final Color color;
  _MiniChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.9);
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.6,
      size.width * 0.2,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width * 0.4,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.3,
      size.width * 0.6,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.5,
      size.width * 0.8,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.1,
      size.width,
      size.height * 0.2,
    );

    // Draw shadow/gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dot at the end
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width, size.height * 0.2), 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
          .withValues(alpha: 0.08) // Subtle wave
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

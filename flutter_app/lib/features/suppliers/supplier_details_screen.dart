import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import 'suppliers_controller.dart';
import '../inventory/inventory_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/add_purchase_bill_bottom_sheet.dart';
import 'widgets/record_payment_bottom_sheet.dart';
class SupplierDetailsScreen extends StatefulWidget {
  final String supplierId;

  const SupplierDetailsScreen({super.key, required this.supplierId});

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen>
    with SingleTickerProviderStateMixin {
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');

  final _suppliersController = Get.find<SuppliersController>();
  final _inventoryController = Get.isRegistered<InventoryController>()
      ? Get.find<InventoryController>()
      : Get.put(InventoryController());

  String _activeTab = 'bills'; // 'bills', 'payments'
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
    _suppliersController.fetchSupplierDetails(widget.supplierId);
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final supplierIndex = _suppliersController.suppliers.indexWhere(
        (s) => s.id == widget.supplierId,
      );
      if (supplierIndex == -1) {
        return Scaffold(
          body: Center(
            child: Text(
              'Supplier not found',
              style: context.typography.emptyStateDescription.copyWith(
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
          ),
        );
      }

      final supplier = _suppliersController.suppliers[supplierIndex];
      final bills = _suppliersController.supplierBills[widget.supplierId];
      final payments = _suppliersController.supplierPayments[widget.supplierId];

      final showSpinner =
          _suppliersController.isLoading.value &&
          (bills == null || payments == null);

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          elevation: 0,
          leading: Center(
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 16.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: SvgPicture.asset(
                  'assets/SVG/backarrow.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).textTheme.displayLarge?.color ?? Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          title: Text(
            'Supplier Details',
            style: context.typography.invoiceTitle.copyWith(
              color: Theme.of(context).textTheme.displayLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: showSpinner
              ? Center(
                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                )
              : RefreshIndicator(
                  onRefresh: () => _suppliersController.fetchSupplierDetails(
                    widget.supplierId,
                  ),
                  color: Theme.of(context).colorScheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Supplier Info Card
                        _buildSupplierHeaderCard(supplier, isDark),
                        const SizedBox(height: 16),

                        // Stats Cards Section
                        _buildStatsGrid(
                          supplier,
                          bills ?? [],
                          payments ?? [],
                          isDark,
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons Row
                        _buildActionsRow(context, supplier.id, isDark),
                        const SizedBox(height: 24),

                        // Tabs Header
                        _buildTabHeader(
                          isDark,
                          (bills ?? []).length,
                          (payments ?? []).length,
                        ),
                        const SizedBox(height: 16),

                        // Tab Content with Animated Switcher
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _activeTab == 'bills'
                              ? _buildBillsTab(supplier, bills ?? [], isDark)
                              : _buildPaymentsTab(payments ?? [], isDark),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildSupplierHeaderCard(Supplier supplier, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                supplier.name.substring(0, 1).toUpperCase(),
                style: context.typography.clientName.copyWith(
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  style: context.typography.clientName.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                _buildHeaderMetaRow(
                  'assets/SVG/phone.svg',
                  supplier.phone.isNotEmpty ? supplier.phone : 'Not added',
                  Colors.teal.shade400,
                  isDark,
                ),
                _buildHeaderMetaRow(
                  'assets/SVG/mail.svg', 
                  supplier.email.isNotEmpty ? supplier.email : 'Not added', 
                  Colors.blue.shade400,
                  isDark,
                ),
                if (supplier.address.isNotEmpty)
                  _buildHeaderMetaRow(
                    'assets/SVG/location.svg',
                    supplier.address,
                    Colors.orange.shade400,
                    isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetaRow(String iconPath, String label, Color iconColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: context.typography.cardSubtitle.copyWith(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    Supplier supplier,
    List<SupplierPurchaseBill> bills,
    List<SupplierPayment> payments,
    bool isDark,
  ) {
    double localTotalPurchased = 0.0;
    for (var b in bills) {
      localTotalPurchased += b.totalAmount;
    }

    double localTotalPaid = 0.0;
    for (var p in payments) {
      localTotalPaid += p.amount;
    }

    final pending = localTotalPurchased - localTotalPaid;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'PURCHASED',
                value: formatCurrency.format(localTotalPurchased),
                subtitle: '${bills.length} bills',
                icon: 'assets/SVG/invoice.svg',
                iconBgColor: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
                iconColor: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                amountColor: Theme.of(context).textTheme.displayLarge?.color,
                bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F5F9),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'PAID',
                value: formatCurrency.format(localTotalPaid),
                subtitle: '${payments.length} payments',
                icon: 'assets/SVG/wallet.svg',
                iconBgColor: isDark ? Colors.green.shade900 : Colors.green.shade50,
                iconColor: isDark ? Colors.green.shade400 : Colors.green.shade600,
                amountColor: isDark ? Colors.green.shade400 : Colors.green.shade600,
                bgColor: isDark ? const Color(0xFF14532D).withValues(alpha: 0.2) : const Color(0xFFF0FDF4),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildStatCard(
            title: 'PENDING BALANCE',
            value: formatCurrency.format(pending),
            subtitle: 'Amount payable to supplier',
            icon: 'assets/SVG/dollar.svg',
            iconBgColor: isDark ? Colors.red.shade900 : Colors.red.shade50,
            iconColor: isDark ? Colors.red.shade400 : Colors.red.shade600,
            amountColor: isDark ? Colors.red.shade400 : Colors.red.shade600,
            bgColor: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : const Color(0xFFFEF2F2),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required Color iconBgColor,
    required Color iconColor,
    Color? amountColor,
    required Color bgColor,
    required bool isDark,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? iconColor.withValues(alpha: 0.25)
                  : iconColor.withValues(alpha: 0.18)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    title,
                    style: context.typography.cardSubtitle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SvgPicture.asset(
                  icon,
                  width: 14,
                  height: 14,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.typography.invoiceAmount.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: amountColor ?? Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.typography.cardDescription.copyWith(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(
    BuildContext context,
    String supplierId,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => showAddPurchaseBillBottomSheet(context, supplierId),
            icon: SvgPicture.asset(
              'assets/SVG/plus.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: const Text('Purchase Bill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C6BC0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showRecordPaymentDialog(context, supplierId),
            icon: SvgPicture.asset(
              'assets/SVG/card.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: const Text('Record Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabHeader(bool isDark, int billsCount, int paymentsCount) {
    return Row(
      children: [
        _buildTabButton('bills', 'Purchase Bills ($billsCount)', isDark),
        const SizedBox(width: 12),
        _buildTabButton('payments', 'Payments ($paymentsCount)', isDark),
      ],
    );
  }

  Widget _buildTabButton(String tabKey, String label, bool isDark) {
    final bool isActive = _activeTab == tabKey;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = tabKey;
        });
      },
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? (isDark ? Colors.indigo.shade400 : Colors.indigo.shade300) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: context.typography.buttonText.copyWith(
            fontSize: 14.0,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive
                ? (isDark ? Colors.indigo.shade300 : Colors.indigo.shade700)
                : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildBillsTab(Supplier supplier, List<SupplierPurchaseBill> bills, bool isDark) {
    if (bills.isEmpty) {
      return Container(
        key: const ValueKey('bills_empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.package,
              size: 40,
              color: isDark ? const Color(0xFF475569) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No purchase bills yet',
              style: context.typography.emptyStateDescription.copyWith(
                fontWeight: FontWeight.bold,
                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('bills_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return _buildBillCard(supplier, bill, isDark);
      },
    );
  }

  Widget _buildBillCard(Supplier supplier, SupplierPurchaseBill bill, bool isDark) {
    final statusColor = _getStatusColor(bill.status);
    final statusBgColor = statusColor.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billNumber,
                      style: context.typography.invoiceNumber.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).textTheme.displayLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _safeFormatDate(bill.date),
                      style: context.typography.dueDate.copyWith(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              bill.createdBy.isNotEmpty ? bill.createdBy.substring(0, 1).toUpperCase() : 'S',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bill.createdBy.isNotEmpty ? bill.createdBy : 'Unknown',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _confirmDeleteBill(bill.id, bill.billNumber),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    'assets/SVG/delete.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(Colors.red.shade400, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height:6),
          Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency.format(bill.totalAmount),
                      style: context.typography.invoiceAmount.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.displayLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paid',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency.format(bill.amountPaid),
                      style: context.typography.invoiceAmount.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bill.status,
                        style: context.typography.invoiceStatus.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(List<SupplierPayment> payments, bool isDark) {
    if (payments.isEmpty) {
      return Container(
        key: const ValueKey('payments_empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.indianRupee,
              size: 40,
              color: isDark ? const Color(0xFF475569) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No payments recorded yet',
              style: context.typography.emptyStateDescription.copyWith(
                fontWeight: FontWeight.bold,
                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('payments_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentCard(payment, isDark);
      },
    );
  }

  Widget _buildPaymentCard(SupplierPayment payment, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _safeFormatDate(payment.paymentDate),
                style: context.typography.dueDate.copyWith(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: () => _confirmDeletePayment(payment.id, payment.amount),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/SVG/delete.svg',
                        width: 12,
                        height: 12,
                        colorFilter: ColorFilter.mode(Colors.red.shade400, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency.format(payment.amount),
                    style: context.typography.invoiceAmount.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: payment.paymentMode.toLowerCase() == 'cash' 
                          ? Colors.green.shade50 
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.paymentMode,
                      style: context.typography.invoiceStatus.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: payment.paymentMode.toLowerCase() == 'cash' 
                            ? Colors.green.shade700 
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      payment.referenceNumber.isNotEmpty
                          ? 'UTR/Ref: ${payment.referenceNumber}'
                          : 'UTR/Ref: —',
                      textAlign: TextAlign.right,
                      style: context.typography.tableCell.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (payment.notes.isNotEmpty)
                      Text(
                        payment.notes,
                        textAlign: TextAlign.right,
                        style: context.typography.cardDescription.copyWith(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmDeleteBill(String billId, String billNo) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/SVG/delete.svg',
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(Colors.red.shade500, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Bill?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete purchase bill "$billNo"? This will update the supplier ledger status and cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      final isDeleting = _suppliersController.isLoading.value;
                      return ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                final success = await _suppliersController
                                    .deletePurchaseBill(widget.supplierId, billId);
                                Get.back();
                                if (success) {
                                  Get.snackbar(
                                    'Success',
                                    'Bill deleted successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                  );
                                } else {
                                  Get.snackbar(
                                    'Error',
                                    'Failed to delete bill',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Delete',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePayment(String paymentId, double amount) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/SVG/delete.svg',
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(Colors.red.shade500, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Payment?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this payment of ${formatCurrency.format(amount)}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      final isDeleting = _suppliersController.isLoading.value;
                      return ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                final success = await _suppliersController.deletePayment(
                                  widget.supplierId,
                                  paymentId,
                                );
                                Get.back();
                                if (success) {
                                  Get.snackbar(
                                    'Success',
                                    'Payment deleted successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                  );
                                } else {
                                  Get.snackbar(
                                    'Error',
                                    'Failed to delete payment',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Delete',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  } // --- Purchase Bill Form Modal ---

  void _showAddBillDialog(BuildContext context, String supplierId) {
    final billNoController = TextEditingController();
    final notesController = TextEditingController();
//     final overrideAmountController = TextEditingController();

    DateTime billDate = DateTime.now();
    DateTime? dueDate;

    // Dynamic items state
    final List<Map<String, dynamic>> selectedItems = [
      {'desc': '', 'qty': 1, 'rate': 0.0, 'inventoryId': null},
    ];

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardTheme.color,
        surfaceTintColor: Colors.transparent, // Prevents material 3 tint
        child: SizedBox(
          width:
              500, // On mobile, this will constrain to available width minus insetPadding
          child: StatefulBuilder(
            builder: (context, setState) {
              final double subTotal = selectedItems.fold(0.0, (sum, item) {
                final double rate = item['rate'] ?? 0.0;
                final int qty = item['qty'] ?? 1;
                return sum + (rate * qty);
              });

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 12,
                      top: 16,
                      bottom: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.package,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'add_purchase_bill'.tr,
                              style: context.typography.invoiceTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            LucideIcons.x,
                            size: 20,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).colorScheme.outline),

                  // CONTENT
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ROW 1
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomTextField(
                                  label: 'BILL / INVOICE NO. *',
                                  hint: 'e.g. BILL-001',
                                  controller: billNoController,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCustomDateField(
                                  label: 'BILL DATE *',
                                  date: billDate,
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: billDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );
                                    if (picked != null) {
                                      setState(() => billDate = picked);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ROW 2
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomDateField(
                                  label: 'DUE DATE',
                                  date: dueDate,
                                  hint: 'dd-mm-yyyy',
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: dueDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );
                                    if (picked != null) {
                                      setState(() => dueDate = picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'total_amount'.tr,
                                      style: context.typography.cardSubtitle.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 40,
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '₹${subTotal.toStringAsFixed(2)}',
                                        style: context.typography.inputText.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ITEMS HEADER
                          Text(
                            'items_materials_purchased'.tr,
                            style: context.typography.categoryHeader.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ITEMS LIST
                          ...List.generate(selectedItems.length, (index) {
                            final item = selectedItems[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'item_name'.tr,
                                              style: context.typography.cardSubtitle.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Autocomplete<InventoryItem>(
                                              optionsBuilder:
                                                  (
                                                    TextEditingValue
                                                    textEditingValue,
                                                  ) {
                                                    if (textEditingValue.text ==
                                                        '') {
                                                      return const Iterable<
                                                        InventoryItem
                                                      >.empty();
                                                    }
                                                    return _inventoryController
                                                        .items
                                                        .where(
                                                          (option) => option
                                                              .itemName
                                                              .toLowerCase()
                                                              .contains(
                                                                textEditingValue
                                                                    .text
                                                                    .toLowerCase(),
                                                              ),
                                                        );
                                                  },
                                              displayStringForOption:
                                                  (option) => option.itemName,
                                              onSelected: (selection) {
                                                setState(() {
                                                  item['desc'] =
                                                      selection.itemName;
                                                  item['rate'] =
                                                      selection.unitPrice;
                                                  item['inventoryId'] =
                                                      selection.id;
                                                });
                                              },
                                              fieldViewBuilder:
                                                  (
                                                    context,
                                                    controller,
                                                    focusNode,
                                                    onFieldSubmitted,
                                                  ) {
                                                    if (controller
                                                            .text
                                                            .isEmpty &&
                                                        item['desc'] != '') {
                                                      controller.text =
                                                          item['desc'];
                                                    }
                                                    return SizedBox(
                                                      height: 40,
                                                      child: TextFormField(
                                                        controller: controller,
                                                        focusNode: focusNode,
                                                        decoration: InputDecoration(
                                                          hintText:
                                                              'e_g_cement_bags'
                                                                  .tr,
                                                          hintStyle: context.typography.searchHint.copyWith(
                                                            color: Colors
                                                                .grey
                                                                .shade400,
                                                            fontSize: 13,
                                                          ),
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                                                ),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                                                ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: AppColors
                                                                      .primary,
                                                                ),
                                                          ),
                                                          fillColor:
                                                              Theme.of(context).scaffoldBackgroundColor,
                                                          filled: true,
                                                        ),
                                                        style: context.typography.inputText.copyWith(
                                                          fontSize: 13,
                                                        ),
                                                        onChanged: (val) {
                                                          item['desc'] = val;
                                                          item['inventoryId'] =
                                                              null;
                                                        },
                                                      ),
                                                    );
                                                  },
                                              optionsViewBuilder: (context, onSelected, options) {
                                                return Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Material(
                                                    elevation: 4,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: SizedBox(
                                                      height: 200,
                                                      width:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.width *
                                                          0.7,
                                                      child: ListView.builder(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        itemCount:
                                                            options.length,
                                                        itemBuilder: (context, index) {
                                                          final option = options
                                                              .elementAt(index);
                                                          return InkWell(
                                                            onTap: () =>
                                                                onSelected(
                                                                  option,
                                                                ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              child: Text(
                                                                '${option.itemName} (${option.sku})',
                                                                style: context.typography.inputText.copyWith(
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          if (selectedItems.length > 1) {
                                            setState(
                                              () =>
                                                  selectedItems.removeAt(index),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          LucideIcons.trash2,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        padding: const EdgeInsets.only(top: 16),
                                        constraints: const BoxConstraints(),
                                        splashRadius: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'qty'.tr,
                                              style: context.typography.cardSubtitle.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              height: 36,
                                              child: TextFormField(
                                                initialValue: item['qty']
                                                    .toString(),
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color:
                                                          Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                      ),
                                                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                                                  filled: true,
                                                ),
                                                style: context.typography.inputText.copyWith(
                                                  fontSize: 13,
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (val) => setState(
                                                  () => item['qty'] =
                                                      int.tryParse(val) ?? 1,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'rate_1'.tr,
                                              style: context.typography.cardSubtitle.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              height: 36,
                                              child: TextFormField(
                                                key: ValueKey(
                                                  'rate_${index}_${item['rate']}',
                                                ),
                                                initialValue: item['rate'] > 0
                                                    ? item['rate'].toString()
                                                    : '0',
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color:
                                                          Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                      ),
                                                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                                                  filled: true,
                                                ),
                                                style: context.typography.inputText.copyWith(
                                                  fontSize: 13,
                                                ),
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                onChanged: (val) => setState(
                                                  () => item['rate'] =
                                                      double.tryParse(val) ??
                                                      0.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'total_1'.tr,
                                              style: context.typography.cardSubtitle.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              height: 36,
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '₹${((item['qty'] as int) * (item['rate'] as double)).toStringAsFixed(2)}',
                                                style: context.typography.inputText.copyWith(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),

                          // ADD ITEM BUTTON
                          InkWell(
                            onTap: () => setState(
                              () => selectedItems.add({
                                'desc': '',
                                'qty': 1,
                                'rate': 0.0,
                                'inventoryId': null,
                              }),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      LucideIcons.plus,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'add_item'.tr,
                                    style: context.typography.buttonText.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // SUBTOTAL
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'subtotal_1'.tr,
                                  style: context.typography.cardSubtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  '₹${subTotal.toStringAsFixed(2)}',
                                  style: context.typography.invoiceAmount.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // NOTES
                          Text(
                            'notes_1'.tr,
                            style: context.typography.cardSubtitle.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'delivery_details_conditions_etc'.tr,
                              hintStyle: context.typography.searchHint.copyWith(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            style: context.typography.inputText.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // FOOTER
                  Divider(height: 1, color: Theme.of(context).colorScheme.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'cancel'.tr,
                            style: context.typography.buttonText.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(() {
                          final isSaving = _suppliersController.isLoading.value;
                          return ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (billNoController.text.trim().isEmpty) {
                                      Get.snackbar(
                                        'Error',
                                        'Bill number / Invoice number is required',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    if (selectedItems.isEmpty) {
                                      Get.snackbar(
                                        'Error',
                                        'Please add at least one item',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    if (selectedItems.any(
                                      (item) => item['desc']
                                          .toString()
                                          .trim()
                                          .isEmpty,
                                    )) {
                                      Get.snackbar(
                                        'Error',
                                        'Item name is required for all items',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    if (selectedItems.any(
                                      (item) => (item['qty'] as int) <= 0,
                                    )) {
                                      Get.snackbar(
                                        'Error',
                                        'Quantity must be greater than 0 for all items',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    if (selectedItems.any(
                                      (item) => (item['rate'] as double) <= 0,
                                    )) {
                                      Get.snackbar(
                                        'Error',
                                        'Rate must be greater than 0 for all items',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    final List<PurchaseBillItem> billItems =
                                        selectedItems.map((item) {
                                          final double rate = item['rate'] ?? 0.0;
                                          final int qty = item['qty'] ?? 1;
                                          return PurchaseBillItem(
                                            description: item['desc'],
                                            quantity: qty,
                                            rate: rate,
                                            amount: rate * qty,
                                            inventoryId: item['inventoryId'],
                                          );
                                        }).toList();

                                    final String dueDateStr = dueDate != null
                                        ? DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(dueDate!)
                                        : '';

                                    final success = await _suppliersController
                                        .addPurchaseBill(
                                          supplierId,
                                          billNoController.text.trim(),
                                          DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(billDate),
                                          dueDateStr,
                                          notesController.text.trim(),
                                          0.0, // No longer passing override amount
                                          billItems,
                                        );

                                    if (success) {
                                      for (var item in billItems) {
                                        if (item.inventoryId != null) {
                                          _inventoryController.restockItem(
                                            item.inventoryId!,
                                            item.quantity,
                                          );
                                        }
                                      }
                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        'Purchase bill added!',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Failed to add purchase bill.',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'save_bill'.tr,
                                    style: context.typography.buttonText.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.cardSubtitle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: context.typography.searchHint.copyWith(color: Colors.grey.shade400, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            style: context.typography.inputText.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDateField({
    required String label,
    DateTime? date,
    String? hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.cardSubtitle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('dd-MM-yyyy').format(date)
                      : (hint ?? 'dd-mm-yyyy'),
                  style: context.typography.inputText.copyWith(
                    fontSize: 13,
                    color: date != null
                        ? (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black)
                        : Colors.grey.shade400,
                  ),
                ),
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade800,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.cardSubtitle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              filled: true,
            ),
            style: context.typography.inputText.copyWith(
              fontSize: 13,
              color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
            ),
            items: items.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(
                  val,
                  style: context.typography.inputText.copyWith(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(LucideIcons.chevronDown, size: 16),
          ),
        ),
      ],
    );
  }

  // --- Record Payment Form Modal ---
  void _showRecordPaymentDialog(BuildContext context, String supplierId) {
    Get.bottomSheet(
      RecordPaymentBottomSheet(supplierId: supplierId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
    );
  }
}

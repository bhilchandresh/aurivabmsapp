import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_input_field.dart';
import 'suppliers_controller.dart';
import '../inventory/inventory_controller.dart';

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
              style: TextStyle(
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
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: Theme.of(context).textTheme.displayLarge?.color,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Supplier Ledger',
            style: TextStyle(
              color: Theme.of(context).textTheme.displayLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: showSpinner
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : RefreshIndicator(
                  onRefresh: () => _suppliersController.fetchSupplierDetails(
                    widget.supplierId,
                  ),
                  color: AppColors.primary,
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
                              ? _buildBillsTab(bills ?? [], isDark)
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                supplier.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                if (supplier.phone.isNotEmpty)
                  _buildHeaderMetaRow(
                    LucideIcons.phone,
                    supplier.phone,
                    isDark,
                  ),
                if (supplier.email.isNotEmpty)
                  _buildHeaderMetaRow(LucideIcons.mail, supplier.email, isDark),
                if (supplier.gstNumber.isNotEmpty)
                  _buildHeaderMetaRow(
                    LucideIcons.hash,
                    'GST: ${supplier.gstNumber}',
                    isDark,
                  ),
                if (supplier.address.isNotEmpty)
                  _buildHeaderMetaRow(
                    LucideIcons.mapPin,
                    supplier.address,
                    isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetaRow(IconData icon, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Color(0xFFCBD5E1) : Colors.grey.shade700,
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
    final pending = supplier.pendingBalance;
    final hasPending = pending > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;

        List<Widget> statsCards = [
          _buildStatCard(
            title: 'Total Purchased',
            value: formatCurrency.format(supplier.totalPurchased),
            subtitle: '${bills.length} bills',
            icon: LucideIcons.trendingDown,
            color: Colors.blue,
            isDark: isDark,
          ),
          _buildStatCard(
            title: 'Total Paid',
            value: formatCurrency.format(supplier.totalPaid),
            subtitle: '${payments.length} payments',
            icon: LucideIcons.checkCircle,
            color: Colors.green,
            isDark: isDark,
          ),
          _buildStatCard(
            title: 'Pending Balance',
            value: hasPending ? formatCurrency.format(pending) : 'Settled',
            subtitle: hasPending ? 'Amount payable' : 'No outstanding dues',
            icon: hasPending ? LucideIcons.clock : LucideIcons.thumbsUp,
            color: hasPending ? Colors.red : Colors.teal,
            isDark: isDark,
            bgColor: hasPending
                ? (isDark
                      ? Colors.red.shade900.withOpacity(0.3)
                      : Colors.red.shade50)
                : (isDark
                      ? Colors.teal.shade900.withOpacity(0.3)
                      : Colors.teal.shade50),
          ),
        ];

        if (isSmallScreen) {
          return Column(
            children: statsCards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SizedBox(width: double.infinity, child: card),
                  ),
                )
                .toList(),
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: statsCards
                .map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: card,
                    ),
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? ((Theme.of(context).cardTheme.color ?? Colors.white)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgColor != null
              ? Colors.transparent
              : (Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color,
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
            onPressed: () => _showAddBillDialog(context, supplierId),
            icon: Icon(LucideIcons.plus, size: 16),
            label: Text('add_purchase_bill'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
            icon: Icon(LucideIcons.creditCard, size: 16),
            label: Text('record_payment'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
              ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            color: isActive
                ? AppColors.primary
                : ((Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildBillsTab(List<SupplierPurchaseBill> bills, bool isDark) {
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
              color: isDark ? Color(0xFF475569) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No purchase bills yet',
              style: TextStyle(
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
        return _buildBillCard(bill, isDark);
      },
    );
  }

  Widget _buildBillCard(SupplierPurchaseBill bill, bool isDark) {
    final statusColor = _getStatusColor(bill.status);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
          collapsedIconColor: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billNumber,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Theme.of(context).textTheme.displayLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _safeFormatDate(bill.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency.format(bill.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bill.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill Details & Items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2.5),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                        ),
                        children: [
                          _buildTableCell(
                            'Item',
                            isHeader: true,
                            isDark: isDark,
                          ),
                          _buildTableCell(
                            'Qty',
                            isHeader: true,
                            isRightAlign: true,
                            isDark: isDark,
                          ),
                          _buildTableCell(
                            'Rate',
                            isHeader: true,
                            isRightAlign: true,
                            isDark: isDark,
                          ),
                          _buildTableCell(
                            'Amount',
                            isHeader: true,
                            isRightAlign: true,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      ...bill.items.map(
                        (item) => TableRow(
                          children: [
                            _buildTableCell(
                              item.description.isNotEmpty
                                  ? item.description
                                  : 'Item',
                              isDark: isDark,
                            ),
                            _buildTableCell(
                              item.quantity.toString(),
                              isRightAlign: true,
                              isDark: isDark,
                            ),
                            _buildTableCell(
                              formatCurrency.format(item.rate),
                              isRightAlign: true,
                              isDark: isDark,
                            ),
                            _buildTableCell(
                              formatCurrency.format(item.amount),
                              isRightAlign: true,
                              isBold: true,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                        ),
                        children: [
                          const SizedBox(),
                          const SizedBox(),
                          _buildTableCell(
                            'Total Bill:',
                            isHeader: true,
                            isRightAlign: true,
                            isDark: isDark,
                          ),
                          _buildTableCell(
                            formatCurrency.format(bill.totalAmount),
                            isRightAlign: true,
                            isBold: true,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (bill.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notes:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.notes,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Paid: ${formatCurrency.format(bill.amountPaid)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _confirmDeleteBill(bill.id, bill.billNumber),
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: Colors.red,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isRightAlign = false,
    bool isBold = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        textAlign: isRightAlign ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: isHeader ? 11.5 : 12,
          fontWeight: isHeader
              ? FontWeight.bold
              : (isBold ? FontWeight.bold : FontWeight.normal),
          color: isHeader
              ? ((Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))
              : ((Theme.of(context).textTheme.displayLarge?.color ?? Colors.black)),
        ),
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
              color: isDark ? Color(0xFF475569) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No payments recorded yet',
              style: TextStyle(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
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
                    _safeFormatDate(payment.paymentDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.paymentMode,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                formatCurrency.format(payment.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (payment.referenceNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'UTR/Ref: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  payment.referenceNumber,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
              ],
            ),
          ],
          if (payment.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              payment.notes,
              style: TextStyle(
                fontSize: 12,
                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    _confirmDeletePayment(payment.id, payment.amount),
                icon: Icon(LucideIcons.trash2, size: 12),
                label: Text('delete'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
      AlertDialog(
        title: Text('delete_bill'.tr),
        content: Text(
          'Are you sure you want to delete purchase bill "$billNo"? This will update the supplier ledger status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: Colors.grey)),
          ),
          Obx(() {
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isDeleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('delete'.tr, style: TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
    );
  }

  void _confirmDeletePayment(String paymentId, double amount) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_payment'.tr),
        content: Text(
          'Are you sure you want to delete this payment of ${formatCurrency.format(amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: Colors.grey)),
          ),
          Obx(() {
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isDeleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('delete'.tr, style: TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
    );
  } // --- Purchase Bill Form Modal ---

  void _showAddBillDialog(BuildContext context, String supplierId) {
    final billNoController = TextEditingController();
    final notesController = TextEditingController();
    final overrideAmountController = TextEditingController();

    DateTime billDate = DateTime.now();
    DateTime? dueDate;

    // Dynamic items state
    List<Map<String, dynamic>> selectedItems = [
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
                double rate = item['rate'] ?? 0.0;
                int qty = item['qty'] ?? 1;
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
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'add_purchase_bill'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
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
                                    if (picked != null)
                                      setState(() => billDate = picked);
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
                                    if (picked != null)
                                      setState(() => dueDate = picked);
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
                                      style: TextStyle(
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
                                        style: TextStyle(
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
                            style: TextStyle(
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
                                              style: TextStyle(
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
                                                        '')
                                                      return const Iterable<
                                                        InventoryItem
                                                      >.empty();
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
                                                        item['desc'] != '')
                                                      controller.text =
                                                          item['desc'];
                                                    return SizedBox(
                                                      height: 40,
                                                      child: TextFormField(
                                                        controller: controller,
                                                        focusNode: focusNode,
                                                        decoration: InputDecoration(
                                                          hintText:
                                                              'e_g_cement_bags'
                                                                  .tr,
                                                          hintStyle: TextStyle(
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
                                                                BorderSide(
                                                                  color: AppColors
                                                                      .primary,
                                                                ),
                                                          ),
                                                          fillColor:
                                                              Theme.of(context).scaffoldBackgroundColor,
                                                          filled: true,
                                                        ),
                                                        style: TextStyle(
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
                                                                style:
                                                                    TextStyle(
                                                                      fontSize:
                                                                          13,
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
                                        icon: Icon(
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
                                              style: TextStyle(
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
                                                            BorderSide(
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                      ),
                                                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                                                  filled: true,
                                                ),
                                                style: TextStyle(
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
                                              style: TextStyle(
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
                                                            BorderSide(
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                      ),
                                                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                                                  filled: true,
                                                ),
                                                style: TextStyle(
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
                                              style: TextStyle(
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
                                                style: TextStyle(
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
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      LucideIcons.plus,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'add_item'.tr,
                                    style: TextStyle(
                                      color: AppColors.primary,
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
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'subtotal_1'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '₹${subTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // NOTES
                          Text(
                            'notes_1'.tr,
                            style: TextStyle(
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
                              hintStyle: TextStyle(
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
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            style: TextStyle(fontSize: 13),
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
                            style: TextStyle(
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

                                    List<PurchaseBillItem> billItems =
                                        selectedItems.map((item) {
                                          double rate = item['rate'] ?? 0.0;
                                          int qty = item['qty'] ?? 1;
                                          return PurchaseBillItem(
                                            description: item['desc'],
                                            quantity: qty,
                                            rate: rate,
                                            amount: rate * qty,
                                            inventoryId: item['inventoryId'],
                                          );
                                        }).toList();

                                    String dueDateStr = dueDate != null
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
                              backgroundColor: AppColors.primary,
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
                                    style: TextStyle(
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
          style: TextStyle(
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
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            style: TextStyle(fontSize: 13),
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
          style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 13,
                    color: date != null
                        ? (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black)
                        : Colors.grey.shade400,
                  ),
                ),
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: Colors.grey.shade800,
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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            value: value,
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
                borderSide: BorderSide(color: AppColors.primary),
              ),
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              filled: true,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
            ),
            items: items.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(
                  val,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: Icon(LucideIcons.chevronDown, size: 16),
          ),
        ),
      ],
    );
  }

  // --- Record Payment Form Modal ---
  void _showRecordPaymentDialog(BuildContext context, String supplierId) {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();

    DateTime paymentDate = DateTime.now();
    String paymentMode = 'Bank Transfer';

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardTheme.color,
        surfaceTintColor: Colors.transparent,
        child: SizedBox(
          width: 500,
          child: StatefulBuilder(
            builder: (context, setState) {
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
                              LucideIcons.creditCard,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'record_payment_to_supplier'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
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
                          _buildCustomTextField(
                            label: 'AMOUNT PAID *',
                            hint: '₹ 0.00',
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomDateField(
                                  label: 'PAYMENT DATE',
                                  date: paymentDate,
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: paymentDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );
                                    if (picked != null) {
                                      setState(() => paymentDate = picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCustomDropdownField(
                                  label: 'MODE',
                                  value: paymentMode,
                                  items: [
                                    'Cash',
                                    'Bank Transfer',
                                    'UPI',
                                    'Cheque',
                                    'Other',
                                  ],
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => paymentMode = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCustomTextField(
                            label: 'REFERENCE / UTR NO.',
                            hint: 'Optional',
                            controller: referenceController,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'notes_1'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'enter_internal_notes_optional'.tr,
                              hintStyle: TextStyle(
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
                                  color: AppColors.primary,
                                ),
                              ),
                              fillColor: Theme.of(context).scaffoldBackgroundColor,
                              filled: true,
                            ),
                            style: TextStyle(fontSize: 13),
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
                            style: TextStyle(
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
                                    double amount =
                                        double.tryParse(
                                          amountController.text,
                                        ) ??
                                        0.0;
                                    if (amount <= 0) {
                                      Get.snackbar(
                                        'Error',
                                        'Please enter a valid amount',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    final success = await _suppliersController
                                        .recordPayment(
                                          supplierId,
                                          amount,
                                          DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(paymentDate),
                                          paymentMode,
                                          referenceController.text.trim(),
                                          notesController.text.trim(),
                                        );

                                    if (success) {
                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        'Payment recorded successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Failed to record payment. Please try again.',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
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
                                    'record_payment'.tr,
                                    style: TextStyle(
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
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import 'inventory_controller.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final InventoryController _controller = Get.put(InventoryController());

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'inventory_management'.tr,
        subtitle: 'manage_products'.tr,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_controller.isLocked) {
                return _buildLockedView();
              }
              return _buildDashboardView();
            }),
          ),
        ],
      ),
    );
  }

  // --- BASIC PLAN LOCK VIEW ---
  Widget _buildLockedView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.lock,
                size: 48,
                color: Colors.amber.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'inventory_pro'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'inventory_pro_desc'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildUpgradePlanCard(
              'pro_plan'.tr,
              'pro_plan_desc'.tr,
              'pro_plan_price'.tr,
            ),
            const SizedBox(height: 12),
            _buildUpgradePlanCard(
              'business_plan'.tr,
              'business_plan_desc'.tr,
              'business_plan_price'.tr,
            ),
            ElevatedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'upgrade_required'.tr,
                  'contact_admin_upgrade'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.primary,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(LucideIcons.lock, size: 16, color: Colors.white),
              label: Text(
                'contact_admin_btn'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePlanCard(String name, String desc, String price) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                ),
              ),
            ],
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // --- REGULAR ACCESS DASHBOARD ---
  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: () => _controller.fetchItems(),
      color: AppColors.primary,
      child: Skeletonizer(
        enabled: _controller.isLoading.value && _controller.items.isEmpty,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header SKU Usage Card (Only for Premium Plan)
                    Obx(() {
                      if (_controller.subscriptionPlan.value == 'premium') {
                        final used = _controller.items.length;
                        final max = _controller.maxItems;
                        final pct = _controller.usagePercentage;
                        final limitReached = _controller.isAtLimit;

                        Color progressColor = AppColors.primary;
                        if (pct >= 1.0) {
                          progressColor = Colors.red;
                        } else if (pct >= 0.8) {
                          progressColor = Colors.amber;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'sku_usage'.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    ),
                                  ),
                                  Text(
                                    '$used / $max',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: limitReached
                                          ? Colors.red
                                          : (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor,
                                  ),
                                ),
                              ),
                              if (limitReached) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.alertTriangle,
                                      size: 12,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'inventory_limit_reached'.tr,
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Selection Bar
                    Obx(() {
                      if (_controller.isSelectionMode.value) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      LucideIcons.x,
                                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    ),
                                    onPressed: _controller.clearSelection,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_controller.selectedItems.length}${'selected'.tr}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _showBulkDeleteConfirmation,
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'delete'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),

            // Search and Action Bar (Floating)
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              toolbarHeight: 65,
              title: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'search_products'.tr,
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: Colors.grey,
                          size: 16,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    final atLimit = _controller.isAtLimit;
                    return ElevatedButton.icon(
                      onPressed: atLimit
                          ? null
                          : () => _showAddEditItemDialog(),
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: Text(
                        'add_item'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Product List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'warehouse_registry'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                          ),
                        ),
                        const Icon(
                          LucideIcons.package,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => _buildProductList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PRODUCT LIST ---
  Widget _buildProductList() {
    final showSkeleton =
        _controller.isLoading.value && _controller.items.isEmpty;

    final list = showSkeleton
        ? List.generate(
            5,
            (index) => InventoryItem(
              id: 'loading_$index',
              itemName: 'Loading Product Name',
              sku: 'SKU-000',
              purchasePrice: 500.0,
              unitPrice: 1000.0,
              currentStock: 10,
              description: 'Loading description details...',
            ),
          )
        : _controller.items.where((item) {
            final query = _searchQuery.toLowerCase();
            return item.itemName.toLowerCase().contains(query) ||
                item.sku.toLowerCase().contains(query);
          }).toList();

    if (list.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.packageOpen,
              size: 36,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'no_inventory_found'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Skeletonizer(
      enabled: showSkeleton,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = list[index];
          final lowStock = item.currentStock <= 5;
          final badgeBg = lowStock
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.green.withValues(alpha: 0.1);
          final badgeText = lowStock
              ? Colors.red.shade400
              : Colors.green.shade400;

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 40)),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 12 * (1.0 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Obx(() {
              final isSelected = _controller.selectedItems.contains(item.id);
              final isSelectionMode = _controller.isSelectionMode.value;

              return GestureDetector(
                onLongPress: () => _controller.toggleSelection(item.id),
                onTap: () {
                  if (isSelectionMode) {
                    _controller.toggleSelection(item.id);
                  } else {
                    _showAddEditItemDialog(item: item);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSelectionMode) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 12),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SKU & Stock badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.sku.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.grey.shade400,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${item.currentStock} ${'units'.tr.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: badgeText,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Name & Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.itemName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Buy: ${formatCurrency.format(item.purchasePrice)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sell: ${formatCurrency.format(item.unitPrice)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              item.description.isNotEmpty ? item.description : 'No description available',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            
                            const SizedBox(height: 16),

                            // Action panel
                            Row(
                              children: [
                                // Restock Button
                                Expanded(
                                  child: _buildCompactAction(
                                    icon: LucideIcons.arrowUpRight,
                                    label: 'restock'.tr,
                                    color: Colors.indigo,
                                    onTap: () => _showRestockDialog(item),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // History Button
                                Expanded(
                                  child: _buildCompactAction(
                                    icon: LucideIcons.history,
                                    label: 'history'.tr,
                                    color: Colors.green,
                                    onTap: () => _showHistoryDialog(item),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Edit Button
                                Expanded(
                                  child: _buildCompactAction(
                                    icon: LucideIcons.edit,
                                    label: 'edit'.tr,
                                    color: Colors.blue,
                                    onTap: () =>
                                        _showAddEditItemDialog(item: item),
                                  ),
                                ),
                                if (!isSelectionMode) ...[
                                  const SizedBox(width: 8),
                                  // Delete Button
                                  Expanded(
                                    child: _buildCompactAction(
                                      icon: LucideIcons.trash2,
                                      label: 'delete'.tr,
                                      color: Colors.red,
                                      onTap: () => _showDeleteConfirmation(item),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ADD / EDIT ITEM DIALOG ---
  void _showAddEditItemDialog({InventoryItem? item}) {
    final nameCtrl = TextEditingController(text: item?.itemName ?? '');
    final skuCtrl = TextEditingController(text: item?.sku ?? '');
    final purchasePriceCtrl = TextEditingController(
      text: item != null && item.purchasePrice > 0 ? item.purchasePrice.toStringAsFixed(0) : '',
    );
    final sellingPriceCtrl = TextEditingController(
      text: item != null && item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(0) : '',
    );
    final stockCtrl = TextEditingController(
      text: item != null ? item.currentStock.toString() : '',
    );
    final descCtrl = TextEditingController(text: item?.description ?? '');

    final formKey = GlobalKey<FormState>();

    // Helper widget for input fields to match requested UI exactly
    Widget buildField({
      required String label,
      bool isRequired = false,
      required String hint,
      required TextEditingController controller,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5A6B87),
                letterSpacing: 1.2,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      );
    }

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.plus, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        item != null ? 'Edit Item' : 'Add New Item',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: Colors.grey),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            
            // Scrollable Form
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      buildField(
                        label: 'Item Name',
                        isRequired: true,
                        hint: 'E.g. Wireless Mouse',
                        controller: nameCtrl,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Item name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // SKU and Stock
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: buildField(
                              label: 'SKU / Code',
                              hint: 'E.g. MS-109X',
                              controller: skuCtrl,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: buildField(
                              label: 'Available Stock',
                              isRequired: item == null,
                              hint: '',
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              validator: item == null ? (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(val) == null || int.parse(val) < 0) {
                                  return 'Invalid';
                                }
                                return null;
                              } : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Purchase and Selling Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: buildField(
                              label: 'Purchase Price (₹)',
                              hint: '₹',
                              controller: purchasePriceCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: buildField(
                              label: 'Selling Price (₹)',
                              isRequired: true,
                              hint: '₹',
                              controller: sellingPriceCtrl,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(val) == null || double.parse(val) < 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ITEM DESCRIPTION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5A6B87),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: descCtrl,
                            maxLines: 3,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Optional notes...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Obx(() {
                              final isSaving = _controller.isLoading.value;
                              return ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          final purchasePrice = double.tryParse(purchasePriceCtrl.text.trim()) ?? 0.0;
                                          final sellingPrice = double.parse(sellingPriceCtrl.text.trim());
                                          
                                          bool success;
                                          if (item == null) {
                                            final stock = int.parse(stockCtrl.text.trim());
                                            success = await _controller.addItem(
                                              nameCtrl.text.trim(),
                                              skuCtrl.text.trim(),
                                              purchasePrice,
                                              sellingPrice,
                                              stock,
                                              descCtrl.text.trim(),
                                            );
                                          } else {
                                            success = await _controller.updateItem(
                                              item.id,
                                              nameCtrl.text.trim(),
                                              skuCtrl.text.trim(),
                                              purchasePrice,
                                              sellingPrice,
                                              descCtrl.text.trim(),
                                            );
                                          }

                                          if (success) {
                                            Get.back();
                                            Get.snackbar(
                                              'success'.tr,
                                              item != null
                                                  ? 'item_updated_success'.tr
                                                  : 'item_added_success'.tr,
                                              snackPosition: SnackPosition.BOTTOM,
                                              backgroundColor: AppColors.success,
                                              colorText: Colors.white,
                                            );
                                          } else {
                                            Get.snackbar(
                                              'error'.tr,
                                              'item_save_failed'.tr,
                                              snackPosition: SnackPosition.BOTTOM,
                                              backgroundColor: AppColors.error,
                                              colorText: Colors.white,
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF2563EB), // Specific blue from image
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Save Item',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Ensures rounded corners show
    );
  }

  // --- RESTOCK DIALOG ---
  void _showRestockDialog(InventoryItem item) {
    final qtyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'restock_inventory_sku'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              Text(
                item.itemName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'current_available_stock'.trParams({
                  'stock': '${item.currentStock}',
                }),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              AppInputField(
                label: 'quantity_to_add_star'.tr,
                hintText: 'e_g_25'.tr,
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'please_enter_qty'.tr;
                  }
                  if (int.tryParse(val) == null || int.parse(val) <= 0) {
                    return 'must_be_greater_than_0'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: Obx(() {
                  final isSaving = _controller.isLoading.value;
                  return ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              final qty = int.parse(qtyCtrl.text.trim());
                              final success = await _controller.restockItem(
                                item.id,
                                qty,
                              );
                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  'restocked_sku'.tr,
                                  'restock_success'.trParams({
                                    'qty': '$qty',
                                    'name': item.itemName,
                                  }),
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.success,
                                  colorText: Colors.white,
                                );
                              } else {
                                Get.snackbar(
                                  'error'.tr,
                                  'restock_failed'.tr,
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.error,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'confirm_restock'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TRANSACTION HISTORY DIALOG ---
  void _showHistoryDialog(InventoryItem item) {
    _controller.fetchTransactions(item.id);

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'stock_ledger_history'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            Flexible(
              child: Obx(() {
                final txList = _controller.transactions[item.id];
                if (txList == null) {
                  return Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (txList.isEmpty) {
                  return Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: Text(
                      'no_ledger_history'.tr,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: txList.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = txList[index];
                    final isSale = tx.type == 'Sale';
                    final badgeColor = isSale ? Colors.amber : Colors.green;

                    // Format date to local/readable format
                    String formattedDate = tx.date;
                    try {
                      final dt = DateTime.parse(tx.date);
                      formattedDate = DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(dt);
                    } catch (e) {
                      // ignore
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tx.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Text(
                              tx.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tx.quantity > 0 ? "+" : ""}${tx.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: tx.quantity > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  void _showDeleteConfirmation(InventoryItem item) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_stock_item'.tr),
        content: Text(
          'delete_item_confirm_desc'.trParams({'name': item.itemName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final success = await _controller.deleteItem(item.id);
                      Get.back(); // close dialog
                      if (success) {
                        Get.snackbar(
                          'removed_item'.tr,
                          'sku_removed_success'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'error'.tr,
                          'sku_remove_failed'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('delete'.tr, style: const TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
    );
  }

  // --- BULK DELETE CONFIRMATION DIALOG ---
  void _showBulkDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text('delete_selected_items'.tr),
        content: Text(
          'delete_items_confirm_desc'.trParams({
            'count': '${_controller.selectedItems.length}',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final success = await _controller.deleteSelectedItems();
                      Get.back(); // close dialog
                      if (success) {
                        Get.snackbar(
                          'removed_items'.tr,
                          'skus_removed_success'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'error'.tr,
                          'skus_remove_failed'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                      'delete_all'.tr,
                      style: const TextStyle(color: Colors.white),
                    ),
            );
          }),
        ],
      ),
    );
  }
}

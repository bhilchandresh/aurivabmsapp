import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:flutter_svg/flutter_svg.dart';

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
        title: 'inventory'.tr,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
        actions: [
          Obx(() {
            return _buildUsageBadge();
          }),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? (Theme.of(context).cardTheme.color ?? Colors.grey.shade900) : Colors.white,
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

  // --- USAGE BADGE ---
  Widget _buildUsageBadge() {
    final used = _controller.items.length;
    final max = _controller.maxItems;
    final limitHit = _controller.isAtLimit;
    final maxText = max >= 99999 ? '∞' : '$max';

    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: limitHit && max < 99999 ? Colors.red.shade50 : Theme.of(context).brightness == Brightness.dark ? const Color(0xFFEFF6FF).withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
          border: Border.all(color: limitHit && max < 99999 ? Colors.red.shade200 : const Color(0xFFDBEAFE)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/SVG/inventory.svg',
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(limitHit && max < 99999 ? Colors.red.shade700 : const Color(0xFF1D4ED8), BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text(
              '$used / $maxText',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: limitHit && max < 99999 ? Colors.red.shade700 : const Color(0xFF1D4ED8), 
              ),
            ),
          ],
        ),
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
                    // Header SKU Usage Card moved to AppTopBar

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
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            'assets/SVG/search.svg',
                            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                          ),
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
                        SvgPicture.asset(
                          'assets/SVG/inventory.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
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
              ? Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFEF2F2).withValues(alpha: 0.1) : const Color(0xFFFEF2F2)
              : Theme.of(context).brightness == Brightness.dark ? const Color(0xFFECFDF5).withValues(alpha: 0.1) : const Color(0xFFECFDF5);
          final badgeText = lowStock
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981);

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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSelectionMode) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Top row: SKU pill & Stock pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.sku.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/SVG/inventory.svg',
                                  width: 12,
                                  height: 12,
                                  colorFilter: ColorFilter.mode(badgeText, BlendMode.srcIn),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.currentStock} UNITS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: badgeText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Name & Prices
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description.isNotEmpty ? item.description : 'No description available',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Buy: ${formatCurrency.format(item.purchasePrice)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 0),
                              Text(
                                'Sell: ${formatCurrency.format(item.unitPrice)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100),
                      const SizedBox(height: 8),

                      // Actions Grid
                      Column(
                        children: [
                          Row(
                            children: [
                              // Restock Button
                              Expanded(
                                child: _buildCompactAction(
                                  svgAsset: 'assets/SVG/restock.svg',
                                  label: 'Restock',
                                  color: const Color(0xFF3B82F6),
                                  bgColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFEFF6FF).withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
                                  onTap: () => _showRestockDialog(item),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // History Button
                              Expanded(
                                child: _buildCompactAction(
                                  svgAsset: 'assets/SVG/history.svg',
                                  label: 'History',
                                  color: const Color(0xFF10B981),
                                  bgColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFECFDF5).withValues(alpha: 0.1) : const Color(0xFFECFDF5),
                                  onTap: () => _showHistoryDialog(item),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Edit Button
                              Expanded(
                                child: _buildCompactAction(
                                  icon: LucideIcons.edit,
                                  label: 'Edit',
                                  color: const Color(0xFF2563EB),
                                  bgColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFEFF6FF).withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
                                  onTap: () => _showAddEditItemDialog(item: item),
                                ),
                              ),
                              if (!isSelectionMode) ...[
                                const SizedBox(width: 8),
                                // Delete Button
                                Expanded(
                                  child: _buildCompactAction(
                                    svgAsset: 'assets/SVG/delete.svg',
                                    label: 'Delete',
                                    color: const Color(0xFFEF4444),
                                    bgColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFEF2F2).withValues(alpha: 0.1) : const Color(0xFFFEF2F2),
                                    onTap: () => _showDeleteConfirmation(item),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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
    IconData? icon,
    String? svgAsset,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? color.withValues(alpha: 0.15) : bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset,
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    Get.bottomSheet(
      Container(
        margin: EdgeInsets.only(top: context.mediaQueryPadding.top + kToolbarHeight),
        decoration: BoxDecoration(
          color: isDark ? (Theme.of(context).cardTheme.color ?? Colors.grey.shade900) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFEFF6FF).withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset('assets/SVG/inventory.svg', height: 20, width: 20, colorFilter: const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcIn)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item != null ? 'Edit Item' : 'Add New Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            item != null ? 'Update product details' : 'Add product details to your inventory',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF64748B)),
                      onPressed: () => Get.back(),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Form
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      AppInputField(
                        label: 'ITEM NAME *',
                        labelFontSize: 10,
                        hintText: 'E.g. Wireless Mouse',
                        controller: nameCtrl,
                        filled: true,
                        fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                        fontSize: 13,
                        contentPaddingVertical: 12,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset('assets/SVG/inventory.svg', height: 16, width: 16, colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Item name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // SKU and Stock
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppInputField(
                              label: 'SKU / CODE',
                              labelFontSize: 10,
                              hintText: 'E.g. MS-109X',
                              controller: skuCtrl,
                              filled: true,
                              fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                              fontSize: 13,
                              contentPaddingVertical: 12,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset('assets/SVG/code.svg', height: 16, width: 16, colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppInputField(
                              label: 'AVAILABLE STOCK ${item == null ? '*' : ''}',
                              labelFontSize: 10,
                              hintText: '0',
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              filled: true,
                              fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                              fontSize: 13,
                              contentPaddingVertical: 12,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset('assets/SVG/stoke.svg', height: 16, width: 16, colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                              ),
                              validator: item == null ? (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                if (int.tryParse(val) == null || int.parse(val) < 0) return 'Invalid';
                                return null;
                              } : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Purchase and Selling Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppInputField(
                              label: 'PURCHASE PRICE (₹)',
                              labelFontSize: 10,
                              hintText: '0.00',
                              controller: purchasePriceCtrl,
                              keyboardType: TextInputType.number,
                              filled: true,
                              fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                              fontSize: 13,
                              contentPaddingVertical: 12,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset('assets/SVG/moneytotal.svg', height: 16, width: 16, colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppInputField(
                              label: 'SELLING PRICE (₹) *',
                              labelFontSize: 10,
                              hintText: '0.00',
                              controller: sellingPriceCtrl,
                              keyboardType: TextInputType.number,
                              filled: true,
                              fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                              fontSize: 13,
                              contentPaddingVertical: 12,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset('assets/SVG/moneytotal.svg', height: 16, width: 16, colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                if (double.tryParse(val) == null || double.parse(val) < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ITEM DESCRIPTION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5A6B87),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: descCtrl,
                            maxLines: 2,
                            maxLength: 500,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Optional notes...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12, top: 12),
                                child: SvgPicture.asset('assets/SVG/note.svg', height: 16, width: 16, colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 12),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: const Color(0xFF2563EB), // Specific blue from image
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
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
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset('assets/SVG/save.svg', height: 16, width: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Save Item',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFEFF6FF).withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgPicture.asset('assets/SVG/inventory.svg', height: 24, width: 24, colorFilter: const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcIn)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restock Inventory SKU',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add stock to this product',
                              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF64748B)),
                          onPressed: () => Get.back(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Item Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? (Theme.of(context).cardTheme.color ?? Colors.grey.shade900) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description.isNotEmpty ? item.description : 'No description available',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.sku.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFECFDF5).withValues(alpha: 0.1) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/SVG/inventory.svg',
                                    width: 12,
                                    height: 12,
                                    colorFilter: const ColorFilter.mode(Color(0xFF10B981), BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.currentStock} UNITS',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Available Stock
                  const Text(
                    'CURRENT AVAILABLE STOCK',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/SVG/stoke.svg', height: 20, width: 20, colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                        const SizedBox(width: 16),
                        Text(
                          '${item.currentStock} Units',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quantity to Add
                  AppInputField(
                    label: 'QUANTITY TO ADD *',
                    labelFontSize: 11,
                    hintText: 'e.g. 25',
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    filled: true,
                    fillColor: isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.white,
                    contentPaddingVertical: 14,
                    fontSize: 14,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(LucideIcons.hash, size: 18, color: Color(0xFF64748B)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'please_enter_qty'.tr;
                      if (int.tryParse(val) == null || int.parse(val) <= 0) return 'must_be_greater_than_0'.tr;
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter the number of units to add to the inventory.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() {
                          final isSaving = _controller.isLoading.value;
                          return ElevatedButton(
                            onPressed: isSaving ? null : () async {
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset('assets/SVG/inventory.svg', height: 18, width: 18, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                      const SizedBox(width: 8),
                                      const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
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
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // --- TRANSACTION HISTORY DIALOG ---
  void _showHistoryDialog(InventoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _controller.fetchTransactions(item.id);

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'stock_ledger_history'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF64748B)),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: isDark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            Flexible(
              child: Obx(() {
                final txList = _controller.transactions[item.id];
                if (txList == null) {
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (txList.isEmpty) {
                  return SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        'no_ledger_history'.tr,
                        style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: txList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = txList[index];
                    final isSale = tx.type.toLowerCase() == 'sale';
                    final typeColor = isSale ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
                    final typeBg = isSale ? Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFFFBEB).withValues(alpha: 0.1) : const Color(0xFFFFFBEB) : Theme.of(context).brightness == Brightness.dark ? const Color(0xFFECFDF5).withValues(alpha: 0.1) : const Color(0xFFECFDF5);
                    final typeIcon = isSale ? LucideIcons.shoppingCart : LucideIcons.settings;
                    
                    final qtyColor = tx.quantity > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                    final qtyBg = tx.quantity > 0 ? Theme.of(context).brightness == Brightness.dark ? const Color(0xFFECFDF5).withValues(alpha: 0.1) : const Color(0xFFECFDF5) : Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFEF2F2).withValues(alpha: 0.1) : const Color(0xFFFEF2F2);

                    String formattedDate = '';
                    String formattedTime = '';
                    try {
                      final dt = DateTime.parse(tx.date);
                      formattedDate = DateFormat('dd MMM yyyy').format(dt);
                      formattedTime = DateFormat('hh:mm a').format(dt);
                    } catch (e) {
                      formattedDate = tx.date;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? (Theme.of(context).cardTheme.color ?? Colors.grey.shade900) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          // Date, Time & Status
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: typeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon, size: 10, color: typeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      tx.type.toUpperCase(),
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(formattedDate, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              Text(formattedTime, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                          
                          // Divider
                          Container(
                            height: 24,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                          ),
                          
                          // Description
                          Expanded(
                            child: Text(
                              tx.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Quantity Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: qtyBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${tx.quantity > 0 ? "+" : ""}${tx.quantity}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: qtyColor),
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
      backgroundColor: Colors.transparent,
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  void _showDeleteConfirmation(InventoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trash Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/SVG/delete.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Delete Stock Item?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                'This will remove "${item.itemName}" from your warehouse catalog. Are you sure you want to proceed?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
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
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFEF4444),
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
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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

  // --- BULK DELETE CONFIRMATION DIALOG ---
  void _showBulkDeleteConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

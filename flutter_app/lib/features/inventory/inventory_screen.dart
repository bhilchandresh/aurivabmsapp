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
  final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final InventoryController _controller = Get.put(InventoryController());

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Inventory Management',
        subtitle: 'Manage all your products, SKUs, and stock levels',
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
            const Text(
              'Inventory — Pro Feature',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Track stock levels, manage SKUs effortlessly, and auto-sync with your invoices.\nUpgrade to Pro or Business to unlock this module.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildUpgradePlanCard('Pro Plan', 'Up to 100 SKU Items', '₹299 / month'),
            const SizedBox(height: 12),
            _buildUpgradePlanCard('Business Plan', 'Unlimited Inventory & Locations', '₹799 / month'),
            ElevatedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'Upgrade Required',
                  'Please contact your Super Admin to upgrade your business plan.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.primary,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(LucideIcons.lock, size: 16, color: Colors.white),
              label: const Text('Contact Admin to Upgrade', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: Colors.black.withOpacity(0.01),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16.0),
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
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SKU Usage Limit',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          Text(
                            '$used / $max',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: limitReached ? Colors.red : AppColors.textPrimary,
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
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      if (limitReached) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, size: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Inventory limits reached. Upgrade to Business for unlimited SKUs.',
                                style: TextStyle(color: Colors.red.shade600, fontSize: 11, fontWeight: FontWeight.bold),
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

            // Search and Action Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by Product Name or SKU...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                      prefixIcon: const Icon(LucideIcons.search, color: Colors.grey, size: 16),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final atLimit = _controller.isAtLimit;
                  return ElevatedButton.icon(
                    onPressed: atLimit ? null : () => _showAddEditItemDialog(),
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Registry List Title
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Warehouse Registry',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Icon(LucideIcons.package, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),

            // Product List
            Obx(() => _buildProductList()),
          ],
        ),
      ),
      ),
    );
  }

  // --- PRODUCT LIST ---
  Widget _buildProductList() {
    final showSkeleton = _controller.isLoading.value && _controller.items.isEmpty;

    final list = showSkeleton
        ? List.generate(5, (index) => InventoryItem(
            id: 'loading_$index',
            itemName: 'Loading Product Name',
            sku: 'SKU-000',
            unitPrice: 1000.0,
            currentStock: 10,
            description: 'Loading description details...',
          ))
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.packageOpen, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No inventory items found.',
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
        final badgeBg = lowStock ? Colors.red.shade50 : Colors.green.shade50;
        final badgeText = lowStock ? Colors.red.shade700 : Colors.green.shade700;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 40)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 12 * (1.0 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SKU & Stock badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.sku.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.currentStock} UNITS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: badgeText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Name & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrency.format(item.unitPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action panel
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Restock Button
                    _buildCompactAction(
                      icon: LucideIcons.arrowUpRight,
                      label: 'Restock',
                      color: Colors.indigo,
                      onTap: () => _showRestockDialog(item),
                    ),
                    const SizedBox(width: 8),

                    // History Button
                    _buildCompactAction(
                      icon: LucideIcons.history,
                      label: 'History',
                      color: Colors.green,
                      onTap: () => _showHistoryDialog(item),
                    ),
                    const SizedBox(width: 8),

                    // Edit Button
                    _buildCompactAction(
                      icon: LucideIcons.edit,
                      label: 'Edit',
                      color: Colors.blue,
                      onTap: () => _showAddEditItemDialog(item: item),
                    ),
                    const SizedBox(width: 8),

                    // Delete Button
                    _buildCompactAction(
                      icon: LucideIcons.trash2,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: () => _showDeleteConfirmation(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
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
    final priceCtrl = TextEditingController(text: item != null ? item.unitPrice.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(text: item != null ? item.currentStock.toString() : '');
    final descCtrl = TextEditingController(text: item?.description ?? '');

    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                      item != null ? 'Edit Product Details' : 'Add New Product SKU',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Item Name
                AppInputField(
                  label: 'Product Name *',
                  hintText: 'e.g. Wireless Mouse',
                  controller: nameCtrl,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter product name';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // SKU & Available stock row
                Row(
                  children: [
                    Expanded(
                      child: AppInputField(
                        label: 'SKU / Code',
                        hintText: 'e.g. MS-109X',
                        controller: skuCtrl,
                      ),
                    ),
                    if (item == null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppInputField(
                          label: 'Initial Stock *',
                          hintText: 'e.g. 50',
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Required';
                            if (int.tryParse(val) == null || int.parse(val) < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Unit Price
                AppInputField(
                  label: 'Unit Price (₹) *',
                  hintText: 'e.g. 1500',
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter price';
                    if (double.tryParse(val) == null || double.parse(val) < 0) return 'Invalid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                AppInputField(
                  label: 'Product Description',
                  hintText: 'Optional details...',
                  controller: descCtrl,
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Obx(() {
                    final isSaving = _controller.isLoading.value;
                    return ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (formKey.currentState!.validate()) {
                          final price = double.parse(priceCtrl.text.trim());
                          bool success;
                          if (item == null) {
                            final stock = int.parse(stockCtrl.text.trim());
                            success = await _controller.addItem(
                              nameCtrl.text.trim(),
                              skuCtrl.text.trim(),
                              price,
                              stock,
                              descCtrl.text.trim(),
                            );
                          } else {
                            success = await _controller.updateItem(
                              item.id,
                              nameCtrl.text.trim(),
                              skuCtrl.text.trim(),
                              price,
                              descCtrl.text.trim(),
                            );
                          }

                          if (success) {
                            Get.back();
                            Get.snackbar(
                              'Success',
                              item != null ? 'Item updated successfully!' : 'Item added successfully!',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.success,
                              colorText: Colors.white,
                            );
                          } else {
                            Get.snackbar(
                              'Error',
                              'Failed to save product details. Please try again.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.error,
                              colorText: Colors.white,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              item != null ? 'Save Changes' : 'Add Product SKU',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // --- RESTOCK DIALOG ---
  void _showRestockDialog(InventoryItem item) {
    final qtyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  const Text(
                    'Restock Inventory SKU',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Current Available Stock: ${item.currentStock} Units',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              AppInputField(
                label: 'Quantity to Add *',
                hintText: 'e.g. 25',
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter quantity';
                  if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Must be greater than 0';
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
                    onPressed: isSaving ? null : () async {
                      if (formKey.currentState!.validate()) {
                        final qty = int.parse(qtyCtrl.text.trim());
                        final success = await _controller.restockItem(item.id, qty);
                        if (success) {
                          Get.back();
                          Get.snackbar(
                            'Restocked SKU',
                            'Successfully added $qty units of ${item.itemName}!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.success,
                            colorText: Colors.white,
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            'Failed to restock item. Please try again.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.error,
                            colorText: Colors.white,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirm Restock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    const Text(
                      'Stock Ledger History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.itemName,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
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
                    child: const CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (txList.isEmpty) {
                  return Container(
                    height: 150,
                    alignment: Alignment.center,
                    child: Text(
                      'No ledger history found.',
                      style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: txList.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = txList[index];
                    final isSale = tx.type == 'Sale';
                    final badgeColor = isSale ? Colors.amber : Colors.green;

                    // Format date to local/readable format
                    String formattedDate = tx.date;
                    try {
                      final dt = DateTime.parse(tx.date);
                      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
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
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tx.quantity > 0 ? "+" : ""}${tx.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: tx.quantity > 0 ? Colors.green : Colors.red,
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
        title: const Text('Delete Stock Item?'),
        content: Text('This will remove "${item.itemName}" from your warehouse catalog. Are you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            final isSaving = _controller.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving ? null : () async {
                final success = await _controller.deleteItem(item.id);
                Get.back(); // close dialog
                if (success) {
                  Get.snackbar(
                    'Removed Item',
                    'Product SKU removed successfully.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.error,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to delete item. Please try again.',
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Delete', style: TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
    );
  }
}

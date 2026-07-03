import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import 'suppliers_controller.dart';
import 'supplier_details_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final SuppliersController _suppliersController = Get.put(
    SuppliersController(),
  );
  String _searchQuery = '';
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _suppliersController.fetchSuppliers();
  }

  List<Supplier> get _filteredSuppliers {
    return _suppliersController.suppliers.where((sup) {
      final query = _searchQuery.toLowerCase();
      return sup.name.toLowerCase().contains(query) ||
          sup.email.toLowerCase().contains(query) ||
          sup.phone.toLowerCase().contains(query) ||
          sup.gstNumber.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'suppliers'.tr,
        subtitle: 'manage_vendors'.tr,
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _suppliersController.fetchSuppliers(),
        color: Theme.of(context).colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Actions Header Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'search_vendors'.tr,
                        hintStyle: context.typography.searchHint.copyWith(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: Colors.grey,
                          size: 18,
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
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSupplierDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text('add_vendor'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'vendors_registry'.tr,
                    style: context.typography.categoryHeader.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                    ),
                  ),
                  const Icon(
                    LucideIcons.slidersHorizontal,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Vendor list
              Obx(() {
                final showSkeleton =
                    _suppliersController.isLoading.value &&
                    _suppliersController.suppliers.isEmpty;

                final listItems = showSkeleton
                    ? List.generate(
                        5,
                        (index) => Supplier(
                          id: 'loading_$index',
                          name: 'Loading Supplier Name',
                          email: 'supplier@loading.com',
                          phone: '+91 9876543210',
                          gstNumber: '29ABCDE1234F1Z1',
                          address: '123 Loading Street, Bangalore',
                          totalPurchased: 0.0,
                          totalPaid: 0.0,
                        ),
                      )
                    : _filteredSuppliers;

                if (listItems.isEmpty) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.truck,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'no_suppliers_found'.tr,
                          style: context.typography.emptyStateDescription.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Skeletonizer(
                  enabled: showSkeleton,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final supplier = listItems[index];
                      final isHovered = _hoveredIndex == index;

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 200 + (index * 40)),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 15 * (1.0 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: InkWell(
                          onTap: () {
                            Get.to(
                              () => SupplierDetailsScreen(
                                supplierId: supplier.id,
                              ),
                            );
                          },
                          onHover: (hovering) {
                            setState(() {
                              _hoveredIndex = hovering ? index : null;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHovered
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isHovered
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.01),
                                  blurRadius: isHovered ? 12 : 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(
                                          alpha: 0.05,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          supplier.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: context.typography.clientName.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            supplier.name,
                                            style: context.typography.clientName.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                LucideIcons.phone,
                                                size: 12,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                supplier.phone.isNotEmpty
                                                    ? supplier.phone
                                                    : 'N/A',
                                                style: context.typography.cardSubtitle.copyWith(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                LucideIcons.mail,
                                                size: 12,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  supplier.email.isNotEmpty
                                                      ? supplier.email
                                                      : 'N/A',
                                                  style: context.typography.cardSubtitle.copyWith(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (supplier
                                              .gstNumber
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  LucideIcons.hash,
                                                  size: 12,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'GST: ${supplier.gstNumber}',
                                                  style: context.typography.cardSubtitle.copyWith(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Get.to(
                                          () => SupplierDetailsScreen(
                                            supplierId: supplier.id,
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        LucideIcons.arrowRight,
                                        size: 12,
                                      ),
                                      label: Text('view_ledger'.tr),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _confirmDeleteSupplier(
                                        supplier.id,
                                        supplier.name,
                                      ),
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final gstController = TextEditingController();
    final addressController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.truck, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('add_supplier'.tr),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppInputField(
                label: 'supplier_name_star'.tr,
                controller: nameController,
                hintText: 'eg_supplier_name'.tr,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'email'.tr,
                controller: emailController,
                hintText: 'eg_email'.tr,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'phone'.tr,
                controller: phoneController,
                hintText: 'eg_phone'.tr,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'gst_number'.tr,
                controller: gstController,
                hintText: 'eg_gst'.tr,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'address'.tr,
                controller: addressController,
                hintText: 'eg_address'.tr,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: context.typography.buttonText.copyWith(color: Colors.grey),
            ),
          ),
          Obx(() {
            final isSaving = _suppliersController.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        Get.snackbar(
                          'Error',
                          'supplier_name_req'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      final success = await _suppliersController.addSupplier(
                        nameController.text.trim(),
                        emailController.text.trim(),
                        phoneController.text.trim(),
                        gstController.text.trim(),
                        addressController.text.trim(),
                      );

                      if (success) {
                        Get.back();
                        Get.snackbar(
                          'Success',
                          'supplier_added_success'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'supplier_add_error'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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
                      'save_supplier'.tr,
                      style: context.typography.buttonText.copyWith(color: Colors.white),
                    ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(String id, String name) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_supplier'.tr),
        content: Text('delete_supplier_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: context.typography.buttonText.copyWith(color: Colors.grey),
            ),
          ),
          Obx(() {
            final isDeleting = _suppliersController.isLoading.value;
            return ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      final success = await _suppliersController.deleteSupplier(
                        id,
                      );
                      Get.back();
                      if (success) {
                        Get.snackbar(
                          'Success',
                          'supplier_deleted'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'supplier_delete_error'.tr,
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
                  : Text(
                      'delete_vendor'.tr,
                      style: context.typography.buttonText.copyWith(color: Colors.white),
                    ),
            );
          }),
        ],
      ),
    );
  }
}

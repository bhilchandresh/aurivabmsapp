import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/constants/app_colors.dart';
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
  final SuppliersController _suppliersController = Get.put(SuppliersController());
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
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Suppliers',
        subtitle: 'Manage your vendors and purchase history',
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _suppliersController.fetchSuppliers(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                        hintText: 'Search vendors by name, email or GST...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(LucideIcons.search, color: Colors.grey, size: 18),
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
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSupplierDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Vendor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section Label
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vendors & Supply Registers',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Icon(LucideIcons.slidersHorizontal, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),

              // Vendor list
              Obx(() {
                final showSkeleton = _suppliersController.isLoading.value && _suppliersController.suppliers.isEmpty;
                
                final listItems = showSkeleton
                    ? List.generate(5, (index) => Supplier(
                        id: 'loading_$index',
                        name: 'Loading Supplier Name',
                        email: 'supplier@loading.com',
                        phone: '+91 9876543210',
                        gstNumber: '29ABCDE1234F1Z1',
                        address: '123 Loading Street, Bangalore',
                        totalPurchased: 0.0,
                        totalPaid: 0.0,
                      ))
                    : _filteredSuppliers;

                if (listItems.isEmpty) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.truck, size: 40, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No suppliers matching search',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final supplier = listItems[index];
                    final isHovered = _hoveredIndex == index;

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 200 + (index * 40)),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 15 * (1.0 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () {
                          Get.to(() => SupplierDetailsScreen(supplierId: supplier.id));
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHovered ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isHovered
                                    ? AppColors.primary.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.01),
                                blurRadius: isHovered ? 12 : 6,
                                offset: const Offset(0, 4),
                              )
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
                                      color: AppColors.primary.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        supplier.name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          supplier.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.phone, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              supplier.phone.isNotEmpty ? supplier.phone : 'N/A',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(LucideIcons.mail, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                supplier.email.isNotEmpty ? supplier.email : 'N/A',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (supplier.gstNumber.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.hash, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'GST: ${supplier.gstNumber}',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                                      Get.to(() => SupplierDetailsScreen(supplierId: supplier.id));
                                    },
                                    icon: const Icon(LucideIcons.arrowRight, size: 12),
                                    label: const Text('View Ledger'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _confirmDeleteSupplier(supplier.id, supplier.name),
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.withOpacity(0.1),
                                      padding: const EdgeInsets.all(8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        title: const Row(
          children: [
            Icon(LucideIcons.truck, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Supplier'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppInputField(
                label: 'Supplier Name *',
                controller: nameController,
                hintText: 'e.g. Apex Technologies',
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'Email',
                controller: emailController,
                hintText: 'e.g. sales@apextech.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'Phone',
                controller: phoneController,
                hintText: 'e.g. +91 98765 43210',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'GST Number',
                controller: gstController,
                hintText: 'e.g. 29ABCDE1234F1Z1',
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'Address',
                controller: addressController,
                hintText: 'e.g. 22, Industrial Area, Bangalore',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            final isSaving = _suppliersController.isLoading.value;
            return ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  Get.snackbar('Error', 'Supplier name is required', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
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
                  Get.snackbar('Success', 'Supplier added successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                } else {
                  Get.snackbar('Error', 'Failed to add supplier. Please try again.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Supplier', style: TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(String id, String name) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete supplier "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            final isDeleting = _suppliersController.isLoading.value;
            return ElevatedButton(
              onPressed: isDeleting ? null : () async {
                final success = await _suppliersController.deleteSupplier(id);
                Get.back();
                if (success) {
                  Get.snackbar('Success', 'Supplier deleted successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                } else {
                  Get.snackbar('Error', 'Failed to delete supplier', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isDeleting
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

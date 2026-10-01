import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        showProfile: false,
        showBadge: false,
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _suppliersController.fetchSuppliers(),
        color: Theme.of(context).colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              floating: true,
              snap: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 0, // no title
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(166), 
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Vendors',
                        hintStyle: context.typography.searchHint.copyWith(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            'assets/SVG/search.svg',
                            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
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
                    const SizedBox(height: 16),
                    
                    // Progress Bar and Add Vendor Button
                    Obx(() {
                      final int current = _suppliersController.suppliers.length;
                      final int max = _suppliersController.maxSuppliers;
                      final bool limitHit = _suppliersController.isAtLimit;
                      final double progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
                      
                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Supplier',
                                        style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        max == 99999 ? '$current/∞' : '$current/$max',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: limitHit ? Colors.red : (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: max == 99999 ? 0.0 : progress,
                                      backgroundColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        limitHit ? Colors.red : const Color(0xFF3B82F6),
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: limitHit ? null : () => _showAddSupplierDialog(context),
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: Text('add_vendor'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'vendors_registry'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.displayLarge?.color ?? Colors.black,
                      ),
                    ),
                    const Icon(
                      LucideIcons.slidersHorizontal,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverToBoxAdapter(
                child: Obx(() {
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
                          createdBy: 'Admin',
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
                        SvgPicture.asset(
                          'assets/SVG/supplier.svg',
                          height: 48,
                          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
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
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color ?? Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHovered
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isHovered
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.02),
                                  blurRadius: isHovered ? 12 : 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TOP SECTION: Avatar, Name, Pill, and More Vert
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFEFF6FF).withValues(alpha: 0.1) : const Color(0xFFEFF6FF)), // light blue
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          supplier.name.isNotEmpty ? supplier.name.substring(0, 1).toUpperCase() : 'S',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), // blue text
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Name and Pill
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            supplier.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9)),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              supplier.createdBy,
                                              style: TextStyle(fontSize: 9, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // MIDDLE SECTION: Email and Phone
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/SVG/mail.svg', 
                                      width: 13, 
                                      height: 13, 
                                      colorFilter: const ColorFilter.mode(Color(0xFF3B82F6), BlendMode.srcIn)
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      supplier.email.isNotEmpty ? supplier.email : 'No email added',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/SVG/call.svg', 
                                      width: 13, 
                                      height: 13, 
                                      colorFilter: const ColorFilter.mode(Color(0xFF10B981), BlendMode.srcIn)
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      supplier.phone.isNotEmpty ? supplier.phone : 'No phone added',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                Divider(color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9)), height: 1),
                                const SizedBox(height: 12),
                                
                                // FINANCIAL SECTION: Total Bought and Pending Due
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TOTAL BOUGHT',
                                            style: TextStyle(fontSize: 9, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${supplier.totalPurchased.toStringAsFixed(0)}',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : const Color(0xFFE2E8F0)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PENDING DUE',
                                            style: TextStyle(fontSize: 9, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${supplier.pendingBalance.toStringAsFixed(0)}',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF87171) : const Color(0xFFEF4444)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // ACTIONS SECTION: View Full Ledger & Delete
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Get.to(() => SupplierDetailsScreen(supplierId: supplier.id));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFEFF6FF).withValues(alpha: 0.1) : const Color(0xFFEFF6FF)), // Light blue
                                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), // Blue text
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/SVG/supplier.svg', 
                                              width: 14, 
                                              height: 14, 
                                              colorFilter: const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcIn)
                                            ),
                                            const SizedBox(width: 6),
                                            const Text('View Full Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () => _confirmDeleteSupplier(supplier.id, supplier.name),
                                      icon: SvgPicture.asset(
                                        'assets/SVG/delete.svg', 
                                        width: 13, 
                                        height: 13, 
                                        colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF87171) : const Color(0xFFEF4444), BlendMode.srcIn)
                                      ),
                                      label: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF87171) : const Color(0xFFEF4444))),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFEF2F2).withValues(alpha: 0.1) : const Color(0xFFFEF2F2)), // Light red
                                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
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
            ),
          ),
          const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          ],
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

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          top: 12,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardTheme.color : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF8FAFC).withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF1F5F9).withValues(alpha: 0.1) : const Color(0xFFF1F5F9))),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/SVG/supplier.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Supplier',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter supplier details to add to your registry',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(LucideIcons.x, size: 20, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : const Color(0xFFE2E8F0))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Form Fields
              AppInputField(
                label: 'SUPPLIER NAME *',
                controller: nameController,
                hintText: 'Apex Technologies',
                prefixIcon: SvgPicture.asset('assets/SVG/profile.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), BlendMode.srcIn)),
                filled: true,
                fillColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF8FAFC).withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
                fontSize: 14,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'EMAIL',
                controller: emailController,
                hintText: 'sales@apextech.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: SvgPicture.asset('assets/SVG/mail.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), BlendMode.srcIn)),
                filled: true,
                fillColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF8FAFC).withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
                fontSize: 14,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'PHONE',
                controller: phoneController,
                hintText: '+91 98765 43210',
                keyboardType: TextInputType.phone,
                prefixIcon: SvgPicture.asset('assets/SVG/mobile.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), BlendMode.srcIn)),
                filled: true,
                fillColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF8FAFC).withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
                fontSize: 14,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'GST NUMBER',
                controller: gstController,
                hintText: '29ABCDE1234F1Z1',
                prefixIcon: SvgPicture.asset('assets/SVG/gst.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), BlendMode.srcIn)),
                filled: true,
                fillColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF8FAFC).withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
                fontSize: 14,
              ),
              const SizedBox(height: 12),
              AppInputField(
                label: 'ADDRESS',
                controller: addressController,
                hintText: '22, Industrial Area, Ahmedabad, Gujarat',
                prefixIcon: SvgPicture.asset('assets/SVG/location.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), BlendMode.srcIn)),
                filled: true,
                fillColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF8FAFC).withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
                fontSize: 14,
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : const Color(0xFFE2E8F0))),
                        foregroundColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      final isSaving = _suppliersController.isLoading.value;
                      return ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (nameController.text.trim().isEmpty) {
                                  Get.snackbar('Error', 'supplier_name_req'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
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
                                  Get.snackbar('Success', 'supplier_added_success'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                                } else {
                                  Get.snackbar('Error', 'supplier_add_error'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset('assets/SVG/save.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                  const SizedBox(width: 8),
                                  const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _confirmDeleteSupplier(String id, String name) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardTheme.color : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFEF2F2).withValues(alpha: 0.1) : const Color(0xFFFEF2F2)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/SVG/delete.svg',
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF87171) : const Color(0xFFEF4444), BlendMode.srcIn)
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Delete Supplier?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Are you sure you want to delete this supplier? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
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
                        side: BorderSide(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : const Color(0xFFE2E8F0))),
                        foregroundColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                                final success = await _suppliersController.deleteSupplier(id);
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/SVG/delete.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
    );
  }
}

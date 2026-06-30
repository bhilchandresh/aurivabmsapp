import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/tenant_model.dart';
import 'super_admin_edit_company_controller.dart';

class SuperAdminEditCompanyScreen extends StatelessWidget {
  final TenantModel tenant;

  const SuperAdminEditCompanyScreen({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    // Inject the controller when screen builds
    final controller = Get.put(SuperAdminEditCompanyController(tenant: tenant));
    final activeThemeTab = 'Invoice'.obs;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'manage_edit'.tr,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Get.back(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Name + Badge)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        tenant.name,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ADMIN PANEL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mail,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tenant.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 1. COMPANY DETAILS
                _buildCardSection(
                  icon: LucideIcons.building,
                  title: 'COMPANY PROFILE',
                  child: Column(
                    children: [
                      // Modern grid-like layout for larger screens, or wrap for smaller
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 500;
                          if (isMobile) {
                            return Column(
                              children: [
                                _buildModernTextField(
                                  controller.companyNameController,
                                  'COMPANY NAME',
                                  LucideIcons.building2,
                                ),
                                const SizedBox(height: 16),
                                _buildModernTextField(
                                  controller.adminEmailController,
                                  'ADMIN EMAIL',
                                  LucideIcons.mail,
                                ),
                                const SizedBox(height: 16),
                                _buildModernTextField(
                                  controller.phoneController,
                                  'PHONE NUMBER',
                                  LucideIcons.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildModernTextField(
                                  controller.websiteController,
                                  'WEBSITE',
                                  LucideIcons.globe,
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller.companyNameController,
                                      'COMPANY NAME',
                                      LucideIcons.building2,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller.adminEmailController,
                                      'ADMIN EMAIL',
                                      LucideIcons.mail,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller.phoneController,
                                      'PHONE NUMBER',
                                      LucideIcons.phone,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller.websiteController,
                                      'WEBSITE',
                                      LucideIcons.globe,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller.addressController,
                        'FULL ADDRESS',
                        LucideIcons.mapPin,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 32),

                      // Beautiful GST Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.fileText,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'tax_billing'.tr,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      Text(
                                        'configure_gst_settings_for_this_company'
                                            .tr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Obx(
                                  () => Switch(
                                    value: controller.gstEnabled.value,
                                    onChanged: (val) =>
                                        controller.gstEnabled.value = val,
                                    activeColor: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Obx(() {
                              if (!controller.gstEnabled.value)
                                return const SizedBox.shrink();
                              return Column(
                                children: [
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: controller.gstinController,
                                    decoration: InputDecoration(
                                      hintText: 'enter_15_digit_gstin'.tr,
                                      labelText: 'gstin_number'.tr,
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: Icon(
                                        LucideIcons.hash,
                                        color: Colors.blue.shade400,
                                        size: 18,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.blue.shade600,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. SECURITY
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.lock,
                            size: 18,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'security'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.orange.shade800,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: controller.resetAdminPassword,
                          icon: Icon(
                            LucideIcons.rotateCcw,
                            color: Colors.orange.shade800,
                            size: 18,
                          ),
                          label: Text(
                            'reset_admin_password'.tr,
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.orange.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This will override the current admin\'s password.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. ACCOUNT STATUS
                _buildCardSection(
                  icon: LucideIcons.checkCircle2,
                  iconColor: Colors.blue.shade600,
                  title: 'ACCOUNT STATUS',
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('STATUS'),
                            const SizedBox(height: 8),
                            Obx(
                              () => DropdownButtonFormField<String>(
                                value: controller.accountStatus.value,
                                decoration: _inputDecoration(),
                                icon: Icon(LucideIcons.chevronDown, size: 16),
                                items: [
                                  DropdownMenuItem(
                                    value: 'Active',
                                    child: Text('active'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Inactive',
                                    child: Text('inactive'.tr),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    controller.accountStatus.value = val;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('PLAN'),
                            const SizedBox(height: 8),
                            Obx(
                              () => DropdownButtonFormField<String>(
                                value: controller.subscriptionPlan.value,
                                decoration: _inputDecoration(),
                                icon: Icon(LucideIcons.chevronDown, size: 16),
                                items: [
                                  DropdownMenuItem(
                                    value: 'Starter',
                                    child: Text('starter'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Pro',
                                    child: Text('pro'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Business',
                                    child: Text('business'.tr),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    controller.subscriptionPlan.value = val;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. SUBSCRIPTION VALIDITY
                _buildCardSection(
                  icon: LucideIcons.calendar,
                  iconColor: Colors.blue.shade600,
                  title: 'SUBSCRIPTION VALIDITY',
                  headerAction: TextButton.icon(
                    onPressed: controller.resetDefaultValidity,
                    icon: Icon(
                      LucideIcons.rotateCcw,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    label: Text(
                      'reset_default'.tr,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  borderColor: Colors.blue.shade200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('VALID UNTIL'),
                      const SizedBox(height: 8),
                      Obx(
                        () => InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  controller.validUntil.value ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2050),
                            );
                            if (date != null) {
                              controller.validUntil.value = date;
                              controller.selectedDuration.value = 0;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  controller.validityDateString,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                Icon(
                                  LucideIcons.calendarDays,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Obx(
                          () => Text(
                            controller.daysRemainingString,
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Obx(
                              () => _buildSegmentedBtn(
                                '1 Month',
                                () => controller.setSubscriptionDuration(1),
                                isPrimary:
                                    controller.selectedDuration.value == 1,
                              ),
                            ),
                            Obx(
                              () => _buildSegmentedBtn(
                                '1 Year',
                                () => controller.setSubscriptionDuration(12),
                                isPrimary:
                                    controller.selectedDuration.value == 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. THEME DESIGNER
                _buildCardSection(
                  icon: LucideIcons.palette,
                  iconColor: Colors.purple.shade600,
                  title: 'THEME DESIGNER',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1st Row: Toggles
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(
                          () => Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => activeThemeTab.value = 'Invoice',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activeThemeTab.value == 'Invoice'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow:
                                          activeThemeTab.value == 'Invoice'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'invoice_layout'.tr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: activeThemeTab.value == 'Invoice'
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      activeThemeTab.value = 'Quotation',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activeThemeTab.value == 'Quotation'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow:
                                          activeThemeTab.value == 'Quotation'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'quotation_layout'.tr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            activeThemeTab.value == 'Quotation'
                                            ? Colors.purple.shade700
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2nd Row & 3rd Row inside a container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Obx(() {
                          final isInvoice = activeThemeTab.value == 'Invoice';
                          final selectedValue = isInvoice
                              ? controller.invoiceTemplate
                              : controller.quotationTemplate;
                          final color = isInvoice ? Colors.blue : Colors.purple;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'current_template'.tr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedValue.value.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: color.shade700,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isInvoice
                                          ? LucideIcons.fileText
                                          : LucideIcons.fileSpreadsheet,
                                      color: color.shade600,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showDesignPicker(context, selectedValue),
                                  icon: Icon(
                                    LucideIcons.palette,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'change_layout'.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.globe,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'instant_cloud_sync'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your design selections are synchronized across all device nodes and client-facing portals in real-time.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.applySystemChanges,
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(LucideIcons.save, size: 18),
                        label: Text(
                          controller.isLoading.value
                              ? 'Saving...'
                              : 'Apply System Changes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required IconData icon,
    Color? iconColor,
    required String title,
    Widget? headerAction,
    Color? borderColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              Icon(icon, size: 18, color: iconColor ?? Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: iconColor ?? Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 40.0 : 0),
              child: Icon(icon, color: Colors.blue.shade600, size: 18),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2563EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF2563EB)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _showDesignPicker(BuildContext context, RxString targetValue) {
    final themes = [
      {
        'value': 'standard',
        'title': 'STANDARD',
        'subtitle': 'Professional B&W',
        'header': Color(0xFF1E293B),
        'bg': Colors.grey.shade100,
        'accent': Colors.grey.shade300,
      },
      {
        'value': 'modern',
        'title': 'MODERN',
        'subtitle': 'Clean Gray & Blue',
        'header': Color(0xFF475569),
        'bg': Colors.blueGrey.shade50,
        'accent': Colors.blueGrey.shade200,
      },
      {
        'value': 'modern_blue',
        'title': 'MODERN BLUE',
        'subtitle': 'Deep Blue Theme',
        'header': Colors.blue.shade700,
        'bg': Colors.blue.shade50,
        'accent': Colors.blue.shade300,
      },
      {
        'value': 'classic',
        'title': 'CLASSIC',
        'subtitle': 'Warm Serif',
        'header': Color(0xFF92400E),
        'bg': Colors.amber.shade50,
        'accent': Colors.amber.shade200,
      },
      {
        'value': 'minimalist',
        'title': 'MINIMALIST',
        'subtitle': 'Simple & Clean',
        'header': Colors.white,
        'bg': Colors.white,
        'accent': Colors.grey.shade200,
      },
      {
        'value': 'elegant',
        'title': 'ELEGANT',
        'subtitle': 'Premium Gold & Dark',
        'header': Color(0xFF1C1917),
        'bg': Color(0xFFFAFAF9),
        'accent': Colors.orange.shade700,
      },
      {
        'value': 'vibrant',
        'title': 'VIBRANT',
        'subtitle': 'Colorful Gradient UI',
        'header': Colors.purple.shade500,
        'bg': Colors.purple.shade50,
        'accent': Colors.purple.shade200,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'select_theme_layout'.tr,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'choose_a_professional_design_for_your_do'.tr,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.x, color: Colors.grey.shade400),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade100),
              Container(
                color: Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: themes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final t = themes[index];
                      return SizedBox(
                        width: 170,
                        child: _buildThemeCard(
                          t['value'] as String,
                          t['title'] as String,
                          t['subtitle'] as String,
                          targetValue,
                          context,
                          t['header'] as Color,
                          t['bg'] as Color,
                          t['accent'] as Color,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentedBtn(
    String text,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
            border: Border.all(
              color: isPrimary ? Colors.grey.shade200 : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Color(0xFF2563EB) : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    String value,
    String title,
    String subtitle,
    RxString targetValue,
    BuildContext context,
    Color headerColor,
    Color bgColor,
    Color accentColor,
  ) {
    return Obx(() {
      final isSelected = targetValue.value == value;
      return GestureDetector(
        onTap: () {
          targetValue.value = value;
          Navigator.pop(context);
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.blue.shade500 : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: bgColor,
                        child: Column(
                          children: [
                            Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: headerColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 6,
                                        width: 40,
                                        color: accentColor.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 4,
                                        width: double.infinity,
                                        color: accentColor.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 4,
                                        width: 60,
                                        color: accentColor.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade500,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

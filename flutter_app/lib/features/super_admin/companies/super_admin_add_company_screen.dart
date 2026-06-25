import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'super_admin_add_company_controller.dart';

class SuperAdminAddCompanyScreen extends StatelessWidget {
  const SuperAdminAddCompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuperAdminAddCompanyController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Onboard New Client', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Get.back(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SECTION 1: COMPANY & ADMIN DETAILS
                    _buildSectionTitle('1. COMPANY & ADMIN DETAILS'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildTextField(controller.companyNameController, 'COMPANY NAME', 'Acme Inc', LucideIcons.building),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller.slugController, 
                            'SLUG (UNIQUE URL)', 
                            'acme', 
                            LucideIcons.globe,
                            onChanged: (val) => controller.onSlugChangedManually(),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(controller.adminNameController, 'ADMIN NAME', 'John Doe', LucideIcons.userCheck),
                          const SizedBox(height: 16),
                          _buildTextField(controller.adminEmailController, 'ADMIN EMAIL', 'admin@acme.com', LucideIcons.mail, isEmail: true),
                          const SizedBox(height: 16),
                          _buildTextField(controller.passwordController, 'PASSWORD', 'Min 6 chars', LucideIcons.lock, isPassword: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // SECTION 2: SUBSCRIPTION PLAN
                    _buildSectionTitle('2. SUBSCRIPTION PLAN'),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('SELECT PLAN'),
                          const SizedBox(height: 8),
                          Obx(() => DropdownButtonFormField<String>(
                            value: controller.selectedPlan.value,
                            decoration: _inputDecoration(),
                            icon: const Icon(LucideIcons.chevronDown, size: 16),
                            items: const [
                              DropdownMenuItem(value: 'basic', child: Text('Freelancer (₹199)')),
                              DropdownMenuItem(value: 'premium', child: Text('Pro (Popular)')),
                              DropdownMenuItem(value: 'enterprise', child: Text('Business')),
                            ],
                            onChanged: (val) { if (val != null) controller.selectedPlan.value = val; },
                          )),
                          
                          const SizedBox(height: 24),
                          
                          _buildInputLabel('VALID UNTIL'),
                          const SizedBox(height: 8),
                          Obx(() => InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: controller.validUntil.value,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2050),
                              );
                              if (date != null) {
                                controller.validUntil.value = date;
                                controller.selectedDuration.value = 0;
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.calendar, size: 20, color: Colors.grey.shade400),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('dd-MM-yyyy').format(controller.validUntil.value),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                  ),
                                  const Spacer(),
                                  Icon(LucideIcons.calendarDays, size: 20, color: Colors.grey.shade800),
                                ],
                              ),
                            ),
                          )),
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
                                Obx(() => _buildSegmentedBtn('1 Month', () => controller.setSubscriptionDuration(1), isPrimary: controller.selectedDuration.value == 1)),
                                Obx(() => _buildSegmentedBtn('1 Year', () => controller.setSubscriptionDuration(12), isPrimary: controller.selectedDuration.value == 12)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // SECTION 3: DEFAULT VISUAL SETTINGS
                    _buildSectionTitle('3. DEFAULT VISUAL SETTINGS'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildVisualSettingCard(
                            'INVOICE DESIGN', 
                            controller.invoiceDesign, 
                            () => _showDesignPicker(context, controller.invoiceDesign)
                          ),
                          const SizedBox(height: 16),
                          _buildVisualSettingCard(
                            'QUOTATION DESIGN', 
                            controller.quotationDesign, 
                            () => _showDesignPicker(context, controller.quotationDesign)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Inline Submit Button
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: controller.isLoading.value
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text('Create Company & Allocate System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2563EB), letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Container(height: 1, width: double.infinity, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildInputLabel(String label, [IconData? icon]) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: Colors.grey.shade500), const SizedBox(width: 6)],
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {bool isEmail = false, bool isPassword = false, void Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label, icon),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          decoration: _inputDecoration(hint),
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration([String? hint]) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
    );
  }

  Widget _buildSegmentedBtn(String text, VoidCallback onTap, {bool isPrimary = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isPrimary ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
            border: Border.all(color: isPrimary ? Colors.grey.shade200 : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isPrimary ? const Color(0xFF2563EB) : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualSettingCard(String label, RxString value, VoidCallback onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Obx(() => Text(
                value.value.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF4338CA)),
              )),
            ],
          ),
          OutlinedButton.icon(
            onPressed: onChange,
            icon: const Icon(LucideIcons.edit, size: 14, color: Color(0xFF374151)),
            label: const Text('Change', style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        ],
      ),
    );
  }

  void _showDesignPicker(BuildContext context, RxString targetValue) {
    final themes = [
      {'value': 'standard', 'title': 'STANDARD', 'subtitle': 'Professional B&W', 'header': const Color(0xFF1E293B), 'bg': Colors.grey.shade100, 'accent': Colors.grey.shade300},
      {'value': 'modern', 'title': 'MODERN', 'subtitle': 'Clean Gray & Blue', 'header': const Color(0xFF475569), 'bg': Colors.blueGrey.shade50, 'accent': Colors.blueGrey.shade200},
      {'value': 'modern_blue', 'title': 'MODERN BLUE', 'subtitle': 'Deep Blue Theme', 'header': Colors.blue.shade700, 'bg': Colors.blue.shade50, 'accent': Colors.blue.shade300},
      {'value': 'classic', 'title': 'CLASSIC', 'subtitle': 'Warm Serif', 'header': const Color(0xFF92400E), 'bg': Colors.amber.shade50, 'accent': Colors.amber.shade200},
      {'value': 'minimalist', 'title': 'MINIMALIST', 'subtitle': 'Simple & Clean', 'header': Colors.white, 'bg': Colors.white, 'accent': Colors.grey.shade200},
      {'value': 'elegant', 'title': 'ELEGANT', 'subtitle': 'Premium Gold & Dark', 'header': const Color(0xFF1C1917), 'bg': const Color(0xFFFAFAF9), 'accent': Colors.orange.shade700},
      {'value': 'vibrant', 'title': 'VIBRANT', 'subtitle': 'Colorful Gradient UI', 'header': Colors.purple.shade500, 'bg': Colors.purple.shade50, 'accent': Colors.purple.shade200},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Theme Layout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                          const SizedBox(height: 4),
                          Text('Choose a professional design for your documents.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.x, color: Colors.grey.shade400),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey.shade50, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200))),
                    )
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade100),
              
              // Horizontal Scroll View for Templates
              Container(
                color: const Color(0xFFF8FAFC),
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
                         child: _buildThemeCard(t['value'] as String, t['title'] as String, t['subtitle'] as String, targetValue, context, t['header'] as Color, t['bg'] as Color, t['accent'] as Color)
                       );
                    }
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildThemeCard(String value, String title, String subtitle, RxString targetValue, BuildContext context, Color headerColor, Color bgColor, Color accentColor) {
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
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    // Card preview
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: bgColor,
                        child: Column(
                          children: [
                            // Fake header
                            Container(
                              height: 18,
                              decoration: BoxDecoration(color: headerColor, borderRadius: BorderRadius.circular(4)),
                              child: Row(
                                children: [
                                   const SizedBox(width: 8),
                                   Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Fake content
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(width: 36, height: 44, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(6))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(width: double.infinity, height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                                      const SizedBox(height: 8),
                                      Container(width: 40, height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(width: 30, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    // Footer
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        color: isSelected ? Colors.blue.shade600 : Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isSelected ? Colors.white : const Color(0xFF1E293B), letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(subtitle, style: TextStyle(fontSize: 11, color: isSelected ? Colors.blue.shade100 : Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.check_circle, color: Colors.blue.shade600, size: 24),
                ),
              )
          ],
        ),
      );
    });
  }
}

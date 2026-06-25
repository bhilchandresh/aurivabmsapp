import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/super_admin_top_bar.dart';
import 'super_admin_broadcast_controller.dart';

class SuperAdminBroadcastScreen extends StatelessWidget {
  final int initialIndex;
  const SuperAdminBroadcastScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuperAdminBroadcastController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SuperAdminTopBar(),
            Expanded(
              child: DefaultTabController(
                length: 2,
                initialIndex: initialIndex,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        margin: const EdgeInsets.only(top: 16.0, bottom: 0.0, left: 16, right: 16),
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: const Color(0xFF111827),
                          unselectedLabelColor: Colors.grey.shade600,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          tabs: const [
                            Tab(text: 'Broadcast Notification'),
                            Tab(text: 'Email Config (SMTP)'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildBroadcastTab(controller),
                          _buildEmailConfigTab(controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastTab(SuperAdminBroadcastController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Broadcast Notification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send a popup message to all admins.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              // Form
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message Content
                    Text(
                      'MESSAGE CONTENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.messageController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Type your message here...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Dropdowns Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 500;
                        final children = [
                          // Notification Type
                          Expanded(
                            flex: isMobile ? 0 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOTIFICATION TYPE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(() => DropdownButtonFormField<String>(
                                  value: controller.selectedType.value,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  icon: const Icon(LucideIcons.chevronDown, size: 16),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                    fontSize: 14,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'info', child: Text('Information (Blue)')),
                                    DropdownMenuItem(value: 'success', child: Text('Success (Green)')),
                                    DropdownMenuItem(value: 'warning', child: Text('Warning (Amber)')),
                                    DropdownMenuItem(value: 'error', child: Text('Urgent (Red)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) controller.selectedType.value = val;
                                  },
                                )),
                              ],
                            ),
                          ),
                          SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
                          // Target Audience
                          Expanded(
                            flex: isMobile ? 0 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TARGET AUDIENCE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: 'all_admins',
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  icon: const Icon(LucideIcons.chevronDown, size: 16),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'all_admins', child: Text('All Admins')),
                                  ],
                                  onChanged: null, // Disabled
                                ),
                              ],
                            ),
                          ),
                        ];

                        if (isMobile) {
                          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
                        }
                        return Row(children: children);
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.sendBroadcast,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.6),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.shieldCheck, size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    'Push Notification',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailConfigTab(SuperAdminBroadcastController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Config (SMTP)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure global outgoing email server.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              // Form
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Obx(() {
                  if (controller.isSmtpLoading.value) {
                    return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.blue)));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(label: 'SMTP HOST', controller: controller.smtpHostController),
                      const SizedBox(height: 16),
                      _buildTextField(label: 'SMTP PORT', controller: controller.smtpPortController),
                      const SizedBox(height: 16),
                      _buildTextField(label: 'SMTP USERNAME', controller: controller.smtpUserController),
                      const SizedBox(height: 16),
                      _buildTextField(label: 'SMTP PASSWORD', controller: controller.smtpPassController, obscureText: true),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: controller.isSmtpSaving.value ? null : controller.saveSmtpConfig,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.6),
                          ),
                          child: controller.isSmtpSaving.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.save, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Save Configuration',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
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
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

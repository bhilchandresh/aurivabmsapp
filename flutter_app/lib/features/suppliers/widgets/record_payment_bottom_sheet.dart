import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../suppliers_controller.dart';

class RecordPaymentBottomSheet extends StatefulWidget {
  final String supplierId;

  const RecordPaymentBottomSheet({
    Key? key,
    required this.supplierId,
  }) : super(key: key);

  @override
  State<RecordPaymentBottomSheet> createState() => _RecordPaymentBottomSheetState();
}

class _RecordPaymentBottomSheetState extends State<RecordPaymentBottomSheet> {
  final SuppliersController _suppliersController = Get.find<SuppliersController>();
  
  final TextEditingController amountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  DateTime paymentDate = DateTime.now();
  String paymentMode = 'Bank Transfer';

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.green; // Payment color
    final bgColor = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    'assets/SVG/wallet.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Colors.green,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record Payment to Supplier',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add payment details for this supplier',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : const Color(0xFFF0F4F8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.x, size: 18, color: subtitleColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AMOUNT PAID
                  _buildTextField(
                    label: 'AMOUNT PAID *',
                    hint: '₹ 0.00',
                    controller: amountController,
                    svgIcon: 'assets/SVG/moneytotal.svg',
                    borderColor: borderColor,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  
                  // PAYMENT DATE & REFERENCE
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'PAYMENT DATE *',
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
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          label: 'REFERENCE / UTR NO.',
                          hint: 'e.g. 329184721',
                          controller: referenceController,
                          svgIcon: 'assets/SVG/invoice.svg',
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // PAYMENT MODE
                  Text(
                    'MODE *',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildModeChips(borderColor, primaryColor),
                  const SizedBox(height: 12),
                  
                  // Notes
                  _buildTextField(
                    label: 'NOTES',
                    hint: 'Enter internal notes (Optional)',
                    controller: notesController,
                    svgIcon: 'assets/SVG/note.svg',
                    borderColor: borderColor,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() {
                      final isSaving = _suppliersController.isLoading.value;
                      return ElevatedButton.icon(
                        onPressed: isSaving ? null : _savePayment,
                        icon: isSaving 
                          ? const SizedBox.shrink() 
                          : SvgPicture.asset('assets/SVG/save.svg', width: 18, height: 18, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                        label: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Record',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    String? svgIcon,
    required Color borderColor,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: maxLines > 1 ? null : 40,
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 9),
              prefixIcon: svgIcon != null 
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: SvgPicture.asset(svgIcon, width: 18, height: 18, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
                  ) 
                : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: maxLines > 1 ? 12 : 10,
              ),
              isDense: true,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green),
              ),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    DateTime? date,
    required VoidCallback onTap,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/SVG/calendernormal.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? DateFormat('dd-MM-yyyy').format(date) : '',
                    style: TextStyle(
                      fontSize: 11,
                      color: date != null ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeChips(Color borderColor, Color primaryColor) {
    final modes = [
      {'name': 'Bank', 'icon': LucideIcons.landmark},
      {'name': 'Cash', 'icon': LucideIcons.wallet},
      {'name': 'UPI', 'icon': LucideIcons.smartphone},
      {'name': 'Cheque', 'icon': LucideIcons.penTool},
    ];
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: modes.map((mode) {
        final isSelected = paymentMode == mode['name'];
        final color = isSelected ? primaryColor : Colors.grey.shade400;
        final bgColor = isSelected 
            ? primaryColor.withValues(alpha: 0.1) 
            : (isDark ? const Color(0xFF1E1E2C) : Colors.white);
        final borderCol = isSelected ? primaryColor : borderColor;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: mode == modes.last ? 0 : 8),
            child: InkWell(
              onTap: () => setState(() => paymentMode = mode['name'] as String),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderCol, width: isSelected ? 1.5 : 1),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(mode['icon'] as IconData, size: 16, color: color),
                          const SizedBox(height: 4),
                          Text(
                            mode['name'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? primaryColor : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.check_circle, size: 10, color: primaryColor),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _savePayment() async {
    final amountStr = amountController.text.trim();
    if (amountStr.isEmpty) {
      Get.snackbar('Error', 'Amount is required', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    final double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final success = await _suppliersController.recordPayment(
      widget.supplierId,
      amount,
      DateFormat('yyyy-MM-dd').format(paymentDate),
      paymentMode,
      referenceController.text.trim(),
      notesController.text.trim(),
    );

    if (success) {
      Get.back();
      Get.snackbar('Success', 'Payment recorded successfully', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to record payment', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}

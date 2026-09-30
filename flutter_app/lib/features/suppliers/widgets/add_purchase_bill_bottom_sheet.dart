import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../suppliers_controller.dart';
import '../../inventory/inventory_controller.dart';

void showAddPurchaseBillBottomSheet(BuildContext context, String supplierId) {
  Get.bottomSheet(
    AddPurchaseBillBottomSheet(supplierId: supplierId),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    ignoreSafeArea: false,
  );
}

class AddPurchaseBillBottomSheet extends StatefulWidget {
  final String supplierId;
  const AddPurchaseBillBottomSheet({super.key, required this.supplierId});

  @override
  State<AddPurchaseBillBottomSheet> createState() => _AddPurchaseBillBottomSheetState();
}

class _AddPurchaseBillBottomSheetState extends State<AddPurchaseBillBottomSheet> {
  final _suppliersController = Get.find<SuppliersController>();
  final _inventoryController = Get.find<InventoryController>();

  final billNoController = TextEditingController();
  final notesController = TextEditingController();

  DateTime billDate = DateTime.now();
  DateTime? dueDate;

  // Dynamic items state
  final List<Map<String, dynamic>> selectedItems = [
    {'desc': '', 'qty': 1, 'rate': 0.0, 'inventoryId': null},
  ];

  @override
  Widget build(BuildContext context) {
    final double subTotal = selectedItems.fold(0.0, (sum, item) {
      final double rate = item['rate'] ?? 0.0;
      final int qty = item['qty'] ?? 1;
      return sum + (rate * qty);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final primaryColor = const Color(0xFF5C6BC0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
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
                  child: SvgPicture.asset('assets/SVG/invoice.svg', width: 24, height: 24, colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Purchase Bill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enter purchase details and items',
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Fields Row 1
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'BILL / INVOICE NO. *',
                          hint: 'e.g. BILL-001',
                          controller: billNoController,
                          svgIcon: 'assets/SVG/invoice.svg',
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDateField(
                          label: 'BILL DATE *',
                          date: billDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: billDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) setState(() => billDate = picked);
                          },
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Form Fields Row 2
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'DUE DATE',
                          date: dueDate,
                          hint: 'dd-mm-yyyy',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) setState(() => dueDate = picked);
                          },
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildReadOnlyField(
                          label: 'TOTAL AMOUNT',
                          value: '₹${subTotal.toStringAsFixed(2)}',
                          svgIcon: 'assets/SVG/moneytotal.svg',
                          borderColor: borderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Items Section
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252538) : const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/SVG/inventory.svg', width: 16, height: 16, colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn)),
                            const SizedBox(width: 8),
                            Text(
                              'Items / Materials Purchased',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(selectedItems.length, (index) {
                          return _buildItemCard(index, borderColor, primaryColor);
                        }),
                        const SizedBox(height: 12),
                        // Add Item Button
                        InkWell(
                          onTap: () => setState(() => selectedItems.add({
                            'desc': '',
                            'qty': 1,
                            'rate': 0.0,
                            'inventoryId': null,
                          })),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? primaryColor.withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset('assets/SVG/plus.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn)),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Item',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtotal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.asset('assets/SVG/calculator.svg', width: 20, height: 20, colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Total amount of all items',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${subTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Notes
                  _buildTextField(
                    label: 'NOTES',
                    hint: 'Delivery details, conditions etc.',
                    controller: notesController,
                    svgIcon: 'assets/SVG/note.svg',
                    borderColor: borderColor,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
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
                      onPressed: isSaving ? null : _saveBill,
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
                              'Save Bill',
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

  Widget _buildItemCard(int index, Color borderColor, Color primaryColor) {
    final item = selectedItems[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252538) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildItemSearchField(item, borderColor),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  if (selectedItems.length > 1) {
                    setState(() => selectedItems.removeAt(index));
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  width: 32,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    'assets/SVG/delete.svg',
                    colorFilter: ColorFilter.mode(isDark ? Colors.red.shade300 : Colors.red.shade400, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  label: 'QTY',
                  hint: '1',
                  borderColor: borderColor,
                  initialValue: item['qty'].toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() => item['qty'] = int.tryParse(val) ?? 1),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _buildTextField(
                  label: 'RATE (₹)',
                  hint: '0.00',
                  borderColor: borderColor,
                  initialValue: item['rate'] > 0 ? item['rate'].toString() : '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => setState(() => item['rate'] = double.tryParse(val) ?? 0.0),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${((item['qty'] as int) * (item['rate'] as double)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemSearchField(Map<String, dynamic> item, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ITEM NAME *',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Autocomplete<InventoryItem>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') return const Iterable<InventoryItem>.empty();
            return _inventoryController.items.where(
              (option) => option.itemName.toLowerCase().contains(textEditingValue.text.toLowerCase()),
            );
          },
          displayStringForOption: (option) => option.itemName,
          onSelected: (selection) {
            setState(() {
              item['desc'] = selection.itemName;
              item['rate'] = selection.unitPrice;
              item['inventoryId'] = selection.id;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            if (controller.text.isEmpty && item['desc'] != '') {
              controller.text = item['desc'];
            }
            return SizedBox(
              height: 40,
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'e.g. Cement Bags',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: SvgPicture.asset('assets/SVG/search.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF252538) : const Color(0xFFF9FAFB),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.green.shade400 : Colors.green, width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 11),
                onChanged: (val) {
                  item['desc'] = val;
                  item['inventoryId'] = null;
                },
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: isDark ? const Color(0xFF252538) : Colors.white,
                child: SizedBox(
                  height: 200,
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '${option.itemName} (${option.sku})',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    String? svgIcon,
    required Color borderColor,
    int maxLines = 1,
    String? initialValue,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    TextAlign textAlign = TextAlign.start,
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
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: maxLines > 1 ? null : 40,
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            textAlign: textAlign,
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
              fillColor: isDark ? const Color(0xFF252538) : const Color(0xFFF9FAFB),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? Colors.green.shade400 : Colors.green, width: 1.5),
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
    String? hint,
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
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
              color: isDark ? const Color(0xFF252538) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                SvgPicture.asset('assets/SVG/calendernormal.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date != null ? DateFormat('dd-MM-yyyy').format(date) : (hint ?? ''),
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required String svgIcon,
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
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252538) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              SvgPicture.asset(svgIcon, width: 18, height: 18, colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveBill() async {
    if (billNoController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Bill number is required', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (selectedItems.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (selectedItems.any((item) => item['desc'].toString().trim().isEmpty)) {
      Get.snackbar('Error', 'Item name is required for all items', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (selectedItems.any((item) => (item['qty'] as int) <= 0)) {
      Get.snackbar('Error', 'Quantity must be > 0', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (selectedItems.any((item) => (item['rate'] as double) <= 0)) {
      Get.snackbar('Error', 'Rate must be > 0', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final List<PurchaseBillItem> billItems = selectedItems.map((item) {
      final double rate = item['rate'] ?? 0.0;
      final int qty = item['qty'] ?? 1;
      return PurchaseBillItem(
        description: item['desc'],
        quantity: qty,
        rate: rate,
        amount: rate * qty,
        inventoryId: item['inventoryId'],
      );
    }).toList();

    final String dueDateStr = dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate!) : '';

    final success = await _suppliersController.addPurchaseBill(
      widget.supplierId,
      billNoController.text.trim(),
      DateFormat('yyyy-MM-dd').format(billDate),
      dueDateStr,
      notesController.text.trim(),
      0.0,
      billItems,
    );

    if (success) {
      for (var item in billItems) {
        if (item.inventoryId != null) {
          _inventoryController.restockItem(item.inventoryId!, item.quantity);
        }
      }
      Get.back();
      Get.snackbar('Success', 'Purchase bill added!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to add purchase bill.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}

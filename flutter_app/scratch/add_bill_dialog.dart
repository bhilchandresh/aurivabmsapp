  void _showAddBillDialog(BuildContext context, String supplierId) {
    final billNoController = TextEditingController();
    final notesController = TextEditingController();

    DateTime billDate = DateTime.now();
    DateTime? dueDate;

    final List<Map<String, dynamic>> selectedItems = [
      {'desc': '', 'qty': 1, 'rate': 0.0, 'inventoryId': null},
    ];

    Widget _buildLabeledField(
        {required String label,
        bool isRequired = false,
        required Widget child}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              children: isRequired
                  ? [
                      const TextSpan(
                          text: ' *', style: TextStyle(color: Color(0xFFEF4444)))
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      );
    }

    InputDecoration _buildInputDeco(
        {required String hint, Widget? prefixIcon}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        prefixIcon: prefixIcon,
        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
      );
    }

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.85,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            final double subTotal = selectedItems.fold(0.0, (sum, item) {
              final double rate = item['rate'] ?? 0.0;
              final int qty = item['qty'] ?? 1;
              return sum + (rate * qty);
            });

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SvgPicture.asset('assets/SVG/invoice.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Color(0xFF3B82F6), BlendMode.srcIn)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add Purchase Bill',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Enter purchase details and items',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2, right: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(LucideIcons.x,
                              size: 14, color: Color(0xFF64748B)),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          splashRadius: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENT
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        // ROW 1
                        Row(
                          children: [
                            Expanded(
                              child: _buildLabeledField(
                                label: 'BILL / INVOICE NO.',
                                isRequired: true,
                                child: SizedBox(
                                  height: 36,
                                  child: TextFormField(
                                    controller: billNoController,
                                    style: const TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w600),
                                    decoration: _buildInputDeco(
                                      hint: 'e.g. BILL-001',
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: SvgPicture.asset('assets/SVG/invoice.svg', colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLabeledField(
                                label: 'BILL DATE',
                                isRequired: true,
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: billDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );
                                    if (picked != null) {
                                      setState(() => billDate = picked);
                                    }
                                  },
                                  child: IgnorePointer(
                                    child: SizedBox(
                                      height: 36,
                                      child: TextFormField(
                                        key: ValueKey(billDate.toString()),
                                        initialValue: DateFormat('dd-MM-yyyy')
                                            .format(billDate),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                        decoration: _buildInputDeco(
                                          hint: 'dd-mm-yyyy',
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: SvgPicture.asset('assets/SVG/calendernormal.svg', colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ROW 2
                        Row(
                          children: [
                            Expanded(
                              child: _buildLabeledField(
                                label: 'DUE DATE',
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: dueDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );
                                    if (picked != null) {
                                      setState(() => dueDate = picked);
                                    }
                                  },
                                  child: IgnorePointer(
                                    child: SizedBox(
                                      height: 36,
                                      child: TextFormField(
                                        key: ValueKey(dueDate?.toString() ?? 'null'),
                                        initialValue: dueDate != null
                                            ? DateFormat('dd-MM-yyyy')
                                                .format(dueDate!)
                                            : '',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                        decoration: _buildInputDeco(
                                          hint: 'dd-mm-yyyy',
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: SvgPicture.asset('assets/SVG/calendernormal.svg', colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildLabeledField(
                                label: 'TOTAL AMOUNT',
                                child: Container(
                                  height: 36,
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset('assets/SVG/moneytotal.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                                      const SizedBox(width: 8),
                                      Text(
                                        subTotal.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ITEMS SECTION
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.box,
                                      color: Color(0xFF4F46E5), size: 14),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Items / Materials Purchased',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(selectedItems.length, (index) {
                                final item = selectedItems[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: _buildLabeledField(
                                              label: 'ITEM NAME',
                                              isRequired: true,
                                              child: Autocomplete<InventoryItem>(
                                                optionsBuilder: (textEditingValue) {
                                                  if (textEditingValue.text == '') {
                                                    return const Iterable<InventoryItem>.empty();
                                                  }
                                                  return _inventoryController.items.where((option) => option.itemName
                                                      .toLowerCase()
                                                      .contains(textEditingValue.text.toLowerCase()));
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
                                                    height: 36,
                                                    child: TextFormField(
                                                      controller: controller,
                                                      focusNode: focusNode,
                                                      decoration: _buildInputDeco(
                                                        hint: 'e.g. Cement Bags',
                                                        prefixIcon: Padding(
                                                          padding: const EdgeInsets.all(10),
                                                          child: SvgPicture.asset('assets/SVG/search.svg', colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn)),
                                                        ),
                                                      ),
                                                      style: const TextStyle(
                                                          fontSize: 11, fontWeight: FontWeight.w500),
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
                                                                  style: const TextStyle(fontSize: 11),
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
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                if (selectedItems.length > 1) {
                                                  setState(() => selectedItems.removeAt(index));
                                                }
                                              },
                                              icon: SvgPicture.asset('assets/SVG/delete.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn)),
                                              splashRadius: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: _buildLabeledField(
                                              label: 'QTY',
                                              child: SizedBox(
                                                height: 32,
                                                child: TextFormField(
                                                  initialValue: item['qty'].toString(),
                                                  textAlign: TextAlign.center,
                                                  decoration: _buildInputDeco(hint: ''),
                                                  style: const TextStyle(
                                                      fontSize: 11, fontWeight: FontWeight.w600),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (val) => setState(() =>
                                                      item['qty'] = int.tryParse(val) ?? 1),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: _buildLabeledField(
                                              label: 'RATE (₹)',
                                              child: SizedBox(
                                                height: 32,
                                                child: TextFormField(
                                                  key: ValueKey('rate_${index}_${item['rate']}'),
                                                  initialValue: item['rate'] > 0
                                                      ? item['rate'].toString()
                                                      : '0.00',
                                                  textAlign: TextAlign.center,
                                                  decoration: _buildInputDeco(hint: ''),
                                                  style: const TextStyle(
                                                      fontSize: 11, fontWeight: FontWeight.w600),
                                                  keyboardType: const TextInputType.numberWithOptions(
                                                      decimal: true),
                                                  onChanged: (val) => setState(() =>
                                                      item['rate'] = double.tryParse(val) ?? 0.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: _buildLabeledField(
                                              label: 'TOTAL',
                                              child: Container(
                                                height: 32,
                                                alignment: Alignment.centerLeft,
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEEF2FF),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '₹${((item['qty'] as int) * (item['rate'] as double)).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF4338CA),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // ADD ITEM BUTTON
                              InkWell(
                                onTap: () => setState(() => selectedItems.add({
                                  'desc': '',
                                  'qty': 1,
                                  'rate': 0.0,
                                  'inventoryId': null,
                                })),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4F46E5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(LucideIcons.plus,
                                            size: 12, color: Colors.white),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Add Item',
                                        style: TextStyle(
                                          color: Color(0xFF4F46E5),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
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

                        // SUBTOTAL
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E7FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SvgPicture.asset('assets/SVG/calculator.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Color(0xFF4F46E5), BlendMode.srcIn)),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Total amount of all items',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 9,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                '₹${subTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // NOTES
                        _buildLabeledField(
                          label: 'NOTES',
                          child: SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: notesController,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              decoration: _buildInputDeco(
                                hint: 'Delivery details, conditions etc.',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 24, left: 10, right: 10, top: 10),
                                  child: SvgPicture.asset('assets/SVG/note.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.srcIn)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Obx(() {
                          final isSaving = _suppliersController.isLoading.value;
                          return ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (billNoController.text.trim().isEmpty) {
                                      Get.snackbar(
                                        'Error',
                                        'Bill number / Invoice number is required',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    if (selectedItems.isEmpty) {
                                      Get.snackbar(
                                        'Error',
                                        'Please add at least one item',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    if (selectedItems.any(
                                      (item) => item['desc'].toString().trim().isEmpty,
                                    )) {
                                      Get.snackbar(
                                        'Error',
                                        'Item name is required for all items',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    if (selectedItems.any((item) => (item['qty'] as int) <= 0)) {
                                      Get.snackbar(
                                        'Error',
                                        'Quantity must be greater than 0 for all items',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }
                                    if (selectedItems.any((item) => (item['rate'] as double) <= 0)) {
                                      Get.snackbar(
                                        'Error',
                                        'Rate must be greater than 0 for all items',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    final List<PurchaseBillItem> billItems =
                                        selectedItems.map((item) {
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

                                    final String dueDateStr = dueDate != null
                                        ? DateFormat('yyyy-MM-dd').format(dueDate!)
                                        : '';

                                    final success = await _suppliersController
                                        .addPurchaseBill(
                                      supplierId,
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
                                          _inventoryController.restockItem(
                                            item.inventoryId!,
                                            item.quantity,
                                          );
                                        }
                                      }
                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        'Purchase bill added!',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Failed to add purchase bill.',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            icon: isSaving
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : SvgPicture.asset('assets/SVG/save.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                            label: const Text(
                              'Save Bill',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.transparent,
    );
  }

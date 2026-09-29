  void _showRecordPaymentDialog(BuildContext context, String supplierId) {
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();

    DateTime paymentDate = DateTime.now();
    String paymentMode = 'Bank'; // changed from 'Bank Transfer'

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
                fontWeight: FontWeight.w800,
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
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF22C55E)),
        ),
      );
    }

    Widget _buildModeCard(String mode, String svgPath, StateSetter setState) {
      final isSelected = paymentMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => paymentMode = mode),
          child: Container(
            height: 52,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFF1F5F9),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        svgPath,
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                            isSelected ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                            BlendMode.srcIn),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Get.bottomSheet(
      Container(
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.creditCard, color: Color(0xFF22C55E), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Record Payment to Supplier',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Add payment details for this supplier',
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

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // CONTENT
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AMOUNT PAID
                        _buildLabeledField(
                          label: 'AMOUNT PAID',
                          isRequired: true,
                          child: SizedBox(
                            height: 40,
                            child: TextFormField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              decoration: _buildInputDeco(
                                hint: '0.00',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SvgPicture.asset('assets/SVG/moneytotal.svg', colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ROW 2
                        Row(
                          children: [
                            Expanded(
                              child: _buildLabeledField(
                                label: 'PAYMENT DATE',
                                isRequired: true,
                                child: InkWell(
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
                                  child: IgnorePointer(
                                    child: SizedBox(
                                      height: 40,
                                      child: TextFormField(
                                        key: ValueKey(paymentDate.toString()),
                                        initialValue: DateFormat('dd-MM-yyyy')
                                            .format(paymentDate),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500),
                                        decoration: _buildInputDeco(
                                          hint: 'dd-mm-yyyy',
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: SvgPicture.asset('assets/SVG/calendernormal.svg', colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
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
                                label: 'REFERENCE / UTR NO.',
                                child: SizedBox(
                                  height: 40,
                                  child: TextFormField(
                                    controller: referenceController,
                                    style: const TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w500),
                                    decoration: _buildInputDeco(
                                      hint: 'e.g. 329184721',
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: SvgPicture.asset('assets/SVG/note.svg', colorFilter: const ColorFilter.mode(Color(0xFF64748B), BlendMode.srcIn)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // MODE
                        _buildLabeledField(
                          label: 'MODE',
                          isRequired: true,
                          child: Row(
                            children: [
                              _buildModeCard('Bank', 'assets/SVG/bank.svg', setState),
                              _buildModeCard('Cash', 'assets/SVG/cash.svg', setState),
                              _buildModeCard('UPI', 'assets/SVG/upi.svg', setState),
                              _buildModeCard('Cheque', 'assets/SVG/cheque.svg', setState),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // NOTES
                        _buildLabeledField(
                          label: 'NOTES',
                          child: SizedBox(
                            height: 80,
                            child: TextFormField(
                              controller: notesController,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              decoration: _buildInputDeco(
                                hint: 'Enter internal notes (Optional)',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 42, left: 10, right: 10, top: 12),
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
                                    final amount = double.tryParse(amountController.text) ?? 0.0;
                                    if (amount <= 0) {
                                      Get.snackbar(
                                        'Error',
                                        'Please enter a valid amount',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    // if 'Bank', maybe keep it 'Bank Transfer' for the backend or 'Bank'?
                                    // I will just use paymentMode directly since user said change to 'Bank'.
                                    final success = await _suppliersController.recordPayment(
                                      supplierId,
                                      amount,
                                      DateFormat('yyyy-MM-dd').format(paymentDate),
                                      paymentMode == 'Bank' ? 'Bank Transfer' : paymentMode, // Maintain original format for the backend if needed, or pass it as 'Bank' directly
                                      referenceController.text.trim(),
                                      notesController.text.trim(),
                                    );

                                    if (success) {
                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        'Payment recorded successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'Failed to record payment. Please try again.',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
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
                              'Record',
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

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.cardSubtitle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: context.typography.searchHint.copyWith(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              filled: true,
            ),
            style: context.typography.inputText.copyWith(
              fontSize: 13,
              color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.cardSubtitle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('dd-MM-yyyy').format(date)
                      : (hint ?? 'dd-mm-yyyy'),
                  style: context.typography.inputText.copyWith(
                    fontSize: 13,
                    color: date != null
                        ? (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black)
                        : Colors.grey.shade400,
                  ),
                ),
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: Colors.grey.shade800,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.cardSubtitle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              filled: true,
            ),
            style: context.typography.inputText.copyWith(
              fontSize: 13,
              color: (Theme.of(context).textTheme.displayLarge?.color ?? Colors.black),
            ),
            items: items.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(
                  val,
                  style: context.typography.inputText.copyWith(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(LucideIcons.chevronDown, size: 16),
          ),
        ),
      ],
    );
  }

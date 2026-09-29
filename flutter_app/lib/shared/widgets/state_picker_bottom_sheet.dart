import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class StatePickerBottomSheet extends StatefulWidget {
  final String? initialSelectedState;
  final ValueChanged<String> onStateSelected;

  const StatePickerBottomSheet({
    super.key,
    this.initialSelectedState,
    required this.onStateSelected,
  });

  static void show(BuildContext context, {
    String? initialSelectedState,
    required ValueChanged<String> onStateSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatePickerBottomSheet(
        initialSelectedState: initialSelectedState,
        onStateSelected: onStateSelected,
      ),
    );
  }

  @override
  State<StatePickerBottomSheet> createState() => _StatePickerBottomSheetState();
}

class _StatePickerBottomSheetState extends State<StatePickerBottomSheet> {
  final List<String> _allStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  List<String> _filteredStates = [];
  String? _selectedState;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredStates = _allStates;
    _selectedState = widget.initialSelectedState;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStates = _allStates.where((state) => state.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select State',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose the state for place of supply',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search state...',
                  hintStyle: GoogleFonts.inter(color: subtitleColor, fontSize: 14),
                  prefixIcon: Icon(LucideIcons.search, size: 18, color: Colors.blue.shade600),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // State List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filteredStates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final state = _filteredStates[index];
                final isSelected = _selectedState == state;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedState = state;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade600 : borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            state,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.blue.shade700 : textColor,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 14, color: Colors.white),
                          )
                        else
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom Done Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedState != null) {
                    widget.onStateSelected(_selectedState!);
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

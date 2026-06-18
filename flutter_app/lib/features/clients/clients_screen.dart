import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import 'clients_controller.dart';
import 'client_details_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Initialize or find controller
  final ClientsController _clientsController = Get.put(ClientsController());

  String _searchQuery = '';
  String _sortBy = 'newest'; // 'newest', 'oldest', 'alpha_asc', 'dues_high'
  int? _hoveredIndex;

  final List<String> _indianStates = [
    "Andaman and Nicobar Islands",
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chandigarh",
    "Chhattisgarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jammu and Kashmir",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Ladakh",
    "Lakshadweep",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Puducherry",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal"
  ];

  // Helper to filter and sort clients reactively
  List<Client> _getFilteredAndSortedClients(List<Client> allClients) {
    // 1. Filter
    List<Client> filtered = allClients.where((client) {
      final term = _searchQuery.toLowerCase();
      return client.name.toLowerCase().contains(term) ||
          client.email.toLowerCase().contains(term) ||
          client.phone.contains(term);
    }).toList();

    // 2. Sort
    if (_sortBy == 'newest') {
      filtered.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        // Fallback to ID sorting if dates are identical (e.g. both null/0)
        if (dateA == dateB) return b.id.compareTo(a.id);
        return dateB.compareTo(dateA);
      });
    } else if (_sortBy == 'oldest') {
      filtered.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (dateA == dateB) return a.id.compareTo(b.id);
        return dateA.compareTo(dateB);
      });
    } else if (_sortBy == 'alpha_asc') {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'dues_high') {
      filtered.sort((a, b) => b.balance.compareTo(a.balance));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
      appBar: const AppTopBar(
        title: 'Clients Directory',
        subtitle: 'Manage active customer relationships & ledgers',
        showProfile: false,
        showBadge: false,
      ),
      body: Obx(() {
        final listItems = _getFilteredAndSortedClients(_clientsController.clients);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Actions Header Row (Search, Sort, and Add Button)
              _buildFilterHeader(context),
              const SizedBox(height: 20),

              // Register Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer Registers (${listItems.length})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const Icon(LucideIcons.slidersHorizontal, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),

              // Client Cards Grid/List
              if (listItems.isEmpty)
                _buildEmptyState()
              else
                _buildClientsList(listItems),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget searchBar = TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search name, email or phone...',
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: const Icon(LucideIcons.search, color: Colors.grey, size: 18),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );

    Widget sortDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
          items: [
            DropdownMenuItem(value: 'newest', child: Text('Newest First', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest First', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
            DropdownMenuItem(value: 'alpha_asc', child: Text('A-Z Name', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
            DropdownMenuItem(value: 'dues_high', child: Text('Highest Dues ⚠️', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _sortBy = val;
              });
            }
          },
        ),
      ),
    );

    Widget addButton = ElevatedButton.icon(
      onPressed: _showAddClientDialog,
      icon: const Icon(LucideIcons.plus, size: 16),
      label: const Text('Add Client', style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          searchBar,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: sortDropdown),
              const SizedBox(width: 10),
              addButton,
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: searchBar),
          const SizedBox(width: 12),
          sortDropdown,
          const SizedBox(width: 12),
          addButton,
        ],
      );
    }
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 40, color: isDark ? const Color(0xFF475569) : Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No clients matching search',
            style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList(List<Client> clientsList) {
    // Determine screen width for responsive grids
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 600 ? 2 : 1);

    if (crossAxisCount > 1) {
      // Desktop Grid layout
      const double cardHeight = 270.0;
      final double cardWidth = (screenWidth - 32.0 - (crossAxisCount - 1) * 16.0) / crossAxisCount;
      final double computedAspectRatio = cardWidth / cardHeight;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: computedAspectRatio,
        ),
        itemCount: clientsList.length,
        itemBuilder: (context, index) {
          final client = clientsList[index];
          return _buildClientCard(client, index);
        },
      );
    }

    // Standard Mobile List view
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: clientsList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final client = clientsList[index];
        return _buildClientCard(client, index);
      },
    );
  }

  Widget _buildClientCard(Client client, int index) {
    final isHovered = _hoveredIndex == index;
    final balance = client.balance;
    final isAdvance = balance < 0;
    final isClear = balance == 0;
    final hasGstin = client.gstin.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorderColor = isHovered 
        ? AppColors.primary.withOpacity(0.5) 
        : (isDark ? const Color(0xFF334155) : AppColors.border);
    final cardTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;
    final panelBgColor = isDark ? const Color(0xFF0F172A) : AppColors.background.withOpacity(0.5);
    final panelBorderColor = isDark ? const Color(0xFF334155) : AppColors.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: InkWell(
        onTap: () {
          Get.to(() => ClientDetailsScreen(clientId: client.id));
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardBorderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? AppColors.primary.withOpacity(0.08)
                    : Colors.black.withOpacity(0.01),
                blurRadius: isHovered ? 12 : 6,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              client.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: cardTextColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (hasGstin) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.purple.shade900.withOpacity(0.15) : Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade100),
                                  ),
                                  child: Text(
                                    'GST REG',
                                    style: TextStyle(
                                      color: isDark ? Colors.purple.shade300 : Colors.purple.shade700,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(LucideIcons.mail, size: 12, color: secondaryTextColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            client.email.isNotEmpty ? client.email : 'No email added',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.phone, size: 12, color: secondaryTextColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            client.phone.isNotEmpty ? client.phone : 'No phone added',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Financial Quick View Panel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: panelBgColor,
                  border: Border(
                    top: BorderSide(color: panelBorderColor),
                    bottom: BorderSide(color: panelBorderColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL BILLED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency.format(client.totalBilled),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: cardTextColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isAdvance ? 'ADVANCE (JAMA)' : isClear ? 'STATUS' : 'PENDING DUE',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (isClear)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.checkCircle, size: 12, color: isDark ? Colors.green.shade400 : AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Settled',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.green.shade400 : AppColors.success,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            formatCurrency.format(balance.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: isAdvance 
                                  ? (isDark ? Colors.blue.shade400 : Colors.blue) 
                                  : (isDark ? Colors.red.shade400 : AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // View Ledger Link
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'View Customer Ledger',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ADD CLIENT DIALOG ---
  void _showAddClientDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final gstinController = TextEditingController();
    final addressController = TextEditingController();
    String selectedState = '';

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'New Client',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9 > 400
                    ? 400
                    : MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppInputField(
                        label: 'Business Name *',
                        hintText: 'e.g. Acme Corp',
                        controller: nameController,
                        prefixIcon: const Icon(LucideIcons.briefcase, size: 18),
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'Email Address',
                        hintText: 'name@company.com',
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        prefixIcon: const Icon(LucideIcons.mail, size: 18),
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'Phone',
                        hintText: '+91...',
                        keyboardType: TextInputType.phone,
                        controller: phoneController,
                        prefixIcon: const Icon(LucideIcons.phone, size: 18),
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'GSTIN (GST Number)',
                        hintText: 'e.g. 22AAAAA0000A1Z5',
                        controller: gstinController,
                        prefixIcon: const Icon(LucideIcons.percent, size: 18),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              'STATE / UT',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                              ),
                            ),
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14),
                            items: _indianStates.map((state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(state, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedState = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'Billing Address',
                        hintText: 'Full billing address...',
                        controller: addressController,
                        prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar('Error', 'Business Name is required');
                      return;
                    }
                    _clientsController.addClient(
                      name,
                      emailController.text.trim(),
                      phoneController.text.trim(),
                      gstinController.text.trim(),
                      selectedState,
                      addressController.text.trim(),
                    );
                    Navigator.pop(context);
                    Get.snackbar(
                      'Client Saved',
                      'Client has been added successfully!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success.withOpacity(0.1),
                      colorText: AppColors.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Client', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

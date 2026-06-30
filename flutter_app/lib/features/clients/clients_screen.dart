import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/app_input_field.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'clients_controller.dart';
import 'client_details_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final formatCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

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
    "West Bengal",
  ];

  String _capitalizeName(String name) {
    if (name.trim().isEmpty) return name;
    return name
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

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
      filtered.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (_sortBy == 'dues_high') {
      filtered.sort((a, b) => b.balance.compareTo(a.balance));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'clients'.tr,
        subtitle: 'manage_customers'.tr,
        showProfile: false,
        showBadge: false,
      ),
      body: Obx(() {
        final listItems = _getFilteredAndSortedClients(
          _clientsController.clients,
        );

        final isMobile = MediaQuery.of(context).size.width < 700;
        final double headerHeight = isMobile ? 130.0 : 80.0;
        final isLoading = _clientsController.isLoading.value && listItems.isEmpty;

        return Skeletonizer(
          enabled: isLoading,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: headerHeight,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildFilterHeader(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Register Label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${'clients'.tr} (${listItems.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.displayLarge?.color,
                            ),
                          ),
                          Icon(
                            LucideIcons.slidersHorizontal,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Client Cards Grid/List
                      if (isLoading)
                        _buildClientsList(List.generate(5, (index) => Client(
                          id: 'loading_$index',
                          name: 'Loading Client Name',
                          email: 'loading@email.com',
                          phone: '9876543210',
                          address: '',
                          state: '',
                          gstin: '',
                          totalBilled: 0.0,
                          balance: 0.0,
                        )))
                      else if (listItems.isEmpty)
                        _buildEmptyState()
                      else
                        _buildClientsList(listItems),
                    ],
                  ),
                ),
              ),
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
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'search_clients'.tr,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(
          LucideIcons.search,
          color: Colors.grey,
          size: 18,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );

    Widget sortDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          dropdownColor: Theme.of(context).cardTheme.color,
          icon: Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: Colors.grey,
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          items: [
            DropdownMenuItem(
              value: 'newest',
              child: Text(
                'newest_first'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'oldest',
              child: Text(
                'oldest_first'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'alpha_asc',
              child: Text(
                'a_z_name'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'dues_high',
              child: Text(
                'highest_dues'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
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
      icon: Icon(LucideIcons.plus, size: 16),
      label: Text(
        'add_client'.tr,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
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
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 40,
            color: isDark ? Color(0xFF475569) : Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            'no_clients_matching_search'.tr,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
            ),
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
      final double cardWidth =
          (screenWidth - 32.0 - (crossAxisCount - 1) * 16.0) / crossAxisCount;
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

    final cardBgColor = Theme.of(context).cardTheme.color;
    final cardBorderColor = isHovered
        ? AppColors.primary.withOpacity(0.5)
        : Theme.of(context).colorScheme.outline;
    final cardTextColor = Theme.of(context).textTheme.displayLarge?.color;
    final secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    final panelBgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final panelBorderColor = Theme.of(context).colorScheme.outline;

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
            border: Border.all(color: cardBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? AppColors.primary.withOpacity(0.08)
                    : Colors.black.withOpacity(0.01),
                blurRadius: isHovered ? 12 : 6,
                offset: const Offset(0, 4),
              ),
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
                              client.name.trim().isNotEmpty
                                  ? client.name.trim()[0].toUpperCase()
                                  : 'C',
                              style: TextStyle(
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
                                _capitalizeName(client.name),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.purple.shade900.withOpacity(
                                            0.15,
                                          )
                                        : Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.purple.shade900.withOpacity(
                                              0.3,
                                            )
                                          : Colors.purple.shade100,
                                    ),
                                  ),
                                  child: Text(
                                    'gst_reg'.tr.toUpperCase(),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.purple.shade300
                                          : Colors.purple.shade700,
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
                        Icon(
                          LucideIcons.mail,
                          size: 12,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            client.email.isNotEmpty
                                ? client.email
                                : 'no_email_added'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.phone,
                          size: 12,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            client.phone.isNotEmpty
                                ? client.phone
                                : 'no_phone_added'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Financial Quick View Panel
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                        Text(
                          'total_billed'.tr.toUpperCase(),
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
                          isAdvance
                              ? 'advance_jama'.tr.toUpperCase()
                              : isClear
                              ? 'status'.tr.toUpperCase()
                              : 'balance_due'.tr,
                          style: TextStyle(
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
                              Icon(
                                LucideIcons.checkCircle,
                                size: 12,
                                color: isDark
                                    ? Colors.green.shade400
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'settled'.tr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.green.shade400
                                      : AppColors.success,
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
                                  ? (isDark
                                        ? Colors.blue.shade400
                                        : Colors.blue)
                                  : (isDark
                                        ? Colors.red.shade400
                                        : AppColors.error),
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
                  children: [
                    Text(
                      'view_customer_ledger'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      LucideIcons.arrowRight,
                      size: 14,
                      color: AppColors.primary,
                    ),
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
              backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'add_client'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.displayLarge?.color,
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
                        label: 'business_name_star'.tr,
                        hintText: 'e_g_acme_corp'.tr,
                        controller: nameController,
                        prefixIcon: Icon(LucideIcons.briefcase, size: 18),
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'email_address'.tr,
                        hintText: 'name_company_com'.tr,
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        prefixIcon: Icon(LucideIcons.mail, size: 18),
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'phone'.tr,
                        hintText: '+91...',
                        keyboardType: TextInputType.phone,
                        controller: phoneController,
                        prefixIcon: Icon(LucideIcons.phone, size: 18),
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'gstin'.tr,
                        hintText: 'e_g_22aaaaa0000a1z5'.tr,
                        controller: gstinController,
                        prefixIcon: Icon(LucideIcons.percent, size: 18),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              'state_ut'.tr.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            hint: Text(
                              'select_state'.tr,
                              style: TextStyle(
                                color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                            dropdownColor: Theme.of(context).cardTheme.color,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.displayLarge?.color,
                              fontSize: 14,
                            ),
                            items: _indianStates.map((state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(
                                  state,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.displayLarge?.color,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
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
                        label: 'billing_address'.tr,
                        hintText: 'full_billing_address'.tr,
                        controller: addressController,
                        prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar('error'.tr, 'business_name_required'.tr);
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
                      'client_saved'.tr,
                      'client_added_successfully'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success.withOpacity(0.1),
                      colorText: AppColors.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'save_client'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

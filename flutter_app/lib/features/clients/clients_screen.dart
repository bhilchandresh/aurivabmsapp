import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../core/theme/app_extensions.dart';
import '../../shared/widgets/app_input_field.dart';
import '../../shared/widgets/state_picker_bottom_sheet.dart';
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
    final List<Client> filtered = allClients.where((client) {
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
    //     final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: 'clients'.tr,
        showProfile: false,
        showBadge: false,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/SVG/refresh.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).textTheme.displayLarge?.color ?? Colors.black,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              _clientsController.fetchClients();
            },
          ),
        ],
      ),
      body: Obx(() {
        final listItems = _getFilteredAndSortedClients(
          _clientsController.clients,
        );


        final isLoading =
            _clientsController.isLoading.value && listItems.isEmpty;

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
                toolbarHeight: 145,
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
                            'Client Register',
                            style: context.typography.cardTitle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  (Theme.of(
                                    context,
                                  ).textTheme.displayLarge?.color ??
                                  Colors.black),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Total: ${listItems.length}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // View toggle (static for now to match UI exactly)
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      // Client Cards Grid/List
                      if (isLoading)
                        _buildClientsList(
                          List.generate(
                            5,
                            (index) => Client(
                              id: 'loading_$index',
                              name: 'Loading Client Name',
                              email: 'loading@email.com',
                              phone: '9876543210',
                              address: '',
                              state: '',
                              gstin: '',
                              totalBilled: 0.0,
                              balance: 0.0,
                            ),
                          ),
                        )
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: context.typography.inputText.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'search_clients'.tr,
                    hintStyle: context.typography.searchHint.copyWith(
                      fontSize: 13,
                    ),
                    prefixIcon: UnconstrainedBox(
                      child: SvgPicture.asset(
                        'assets/SVG/search.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: context.colorScheme.outline.withValues(
                          alpha: 0.5,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomSortDropdown(
                  selectedValue: _sortBy,
                  onChanged: (val) {
                    setState(() {
                      _sortBy = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddClientDialog,
                  icon: const Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    'add_client'.tr,
                    style: context.typography.buttonText.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/SVG/client01.svg',
            height: 48,
            colorFilter: ColorFilter.mode(
              isDark ? const Color(0xFF475569) : Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No clients found',
            style: context.typography.emptyStateDescription.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF475569) : Colors.grey,
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
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = Theme.of(context).cardTheme.color ?? Colors.white;
    final cardBorderColor = isHovered
        ? AppColors.primary.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1);
    final cardTextColor = Theme.of(context).textTheme.displayLarge?.color;
    final secondaryTextColor = Colors.grey.shade600;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: InkWell(
        onTap: () {
          Get.to(() => ClientDetailsScreen(clientId: client.id));
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section (Row: Avatar/Badge + Info)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side (Avatar and Badge)
                  Column(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            client.name.trim().isNotEmpty
                                ? client.name.trim()[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/SVG/setting.svg',
                              height: 8,
                              width: 8,
                              colorFilter: const ColorFilter.mode(
                                Colors.grey,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'By: ${client.addedBy?.isNotEmpty == true ? client.addedBy : 'System'}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Right side (Details)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          _capitalizeName(client.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: cardTextColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Email
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: SvgPicture.asset(
                                'assets/SVG/mail.svg',
                                height: 10,
                                width: 10,
                                colorFilter: const ColorFilter.mode(
                                  Colors.blue,
                                  BlendMode.srcIn,
                                ),
                              ),
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
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Phone
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: SvgPicture.asset(
                                'assets/SVG/phone.svg',
                                height: 10,
                                width: 10,
                                colorFilter: const ColorFilter.mode(
                                  Colors.green,
                                  BlendMode.srcIn,
                                ),
                              ),
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
                                  fontSize: 11,
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
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Section (Financials)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.withValues(alpha: 0.1)
                      : Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Total Billed
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SvgPicture.asset(
                              'assets/SVG/invoice.svg',
                              height: 14,
                              width: 14,
                              colorFilter: const ColorFilter.mode(
                                Colors.green,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Billed',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatCurrency.format(client.totalBilled),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: cardTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    // Pending Due
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: balance > 0
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : (balance < 0
                                        ? Colors.blue.withValues(alpha: 0.1)
                                        : Colors.green.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: balance > 0
                                ? SvgPicture.asset(
                                    'assets/SVG/time.svg',
                                    height: 14,
                                    width: 14,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.red,
                                      BlendMode.srcIn,
                                    ),
                                  )
                                : (balance < 0
                                      ? SvgPicture.asset(
                                          'assets/SVG/invoice.svg',
                                          height: 14,
                                          width: 14,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.blue,
                                            BlendMode.srcIn,
                                          ),
                                        )
                                      : SvgPicture.asset(
                                          'assets/SVG/accepted.svg',
                                          height: 14,
                                          width: 14,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.green,
                                            BlendMode.srcIn,
                                          ),
                                        )),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  balance > 0
                                      ? 'Pending Due'
                                      : (balance < 0 ? 'Advance' : 'Status'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  balance == 0
                                      ? 'Settled'
                                      : formatCurrency.format(balance.abs()),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: balance > 0
                                        ? Colors.red
                                        : (balance < 0
                                              ? Colors.blue
                                              : Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final Color bgColor =
                Theme.of(context).cardTheme.color ??
                Theme.of(context).scaffoldBackgroundColor;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grabber
                    const SizedBox(height: 12),
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
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
                                  'Add Client',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.displayLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add a new client to your business',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              color: isDark ? Colors.white : Colors.black87,
                              onPressed: () => Navigator.pop(context),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppInputField(
                              label: 'BUSINESS NAME *',
                              hintText: 'Acme Corp',
                              controller: nameController,
                              prefixIcon: SvgPicture.asset(
                                'assets/SVG/building.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.srcIn,
                                ),
                              ),
                              fontSize: 14,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : Colors.white,
                              contentPaddingVertical: 12.0,
                            ),
                            const SizedBox(height: 16),
                            AppInputField(
                              label: 'EMAIL ADDRESS',
                              hintText: 'name@company.com',
                              keyboardType: TextInputType.emailAddress,
                              controller: emailController,
                              prefixIcon: SvgPicture.asset(
                                'assets/SVG/mail.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.srcIn,
                                ),
                              ),
                              fontSize: 14,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : Colors.white,
                              contentPaddingVertical: 12.0,
                            ),
                            const SizedBox(height: 16),
                            AppInputField(
                              label: 'PHONE',
                              hintText: '9898989898',
                              keyboardType: TextInputType.phone,
                              controller: phoneController,
                              prefixIcon: SvgPicture.asset(
                                'assets/SVG/call.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.srcIn,
                                ),
                              ),
                              fontSize: 14,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : Colors.white,
                              contentPaddingVertical: 12.0,
                            ),
                            const SizedBox(height: 16),
                            AppInputField(
                              label: 'GSTIN',
                              hintText: '22AAAAA0000A1Z5',
                              controller: gstinController,
                              prefixIcon: SvgPicture.asset(
                                'assets/SVG/gst.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.srcIn,
                                ),
                              ),
                              fontSize: 14,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : Colors.white,
                              contentPaddingVertical: 12.0,
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'STATE / UT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    StatePickerBottomSheet.show(
                                      context,
                                      initialSelectedState: selectedState,
                                      onStateSelected: (val) {
                                        setSheetState(() {
                                          selectedState = val;
                                        });
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey.withValues(alpha: 0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/SVG/location.svg',
                                          width: 18,
                                          height: 18,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.grey,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            selectedState.isEmpty
                                                ? 'Select State'
                                                : selectedState,
                                            style: TextStyle(
                                              color: selectedState.isEmpty
                                                  ? Colors.grey.shade500
                                                  : Theme.of(context)
                                                        .textTheme
                                                        .displayLarge
                                                        ?.color,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          LucideIcons.chevronDown,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppInputField(
                              label: 'BILLING ADDRESS',
                              hintText: 'Full billing address...',
                              controller: addressController,
                              prefixIcon: SvgPicture.asset(
                                'assets/SVG/location.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.srcIn,
                                ),
                              ),
                              maxLines: 3,
                              fontSize: 14,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : Colors.white,
                              contentPaddingVertical: 12.0,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Footer Buttons
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'cancel'.tr,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.displayLarge?.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final phone = phoneController.text.trim();
                                final address = addressController.text.trim();

                                if (name.isEmpty ||
                                    email.isEmpty ||
                                    phone.isEmpty ||
                                    selectedState.isEmpty ||
                                    address.isEmpty) {
                                  Get.snackbar(
                                    'error'.tr,
                                    'Please fill all fields except GSTIN',
                                    backgroundColor: Colors.red.withValues(
                                      alpha: 0.1,
                                    ),
                                    colorText: Colors.red,
                                  );
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
                                  backgroundColor: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  colorText: AppColors.success,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF2563EB,
                                ), // Blue color from image
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'save_client'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DropdownArrowPainter extends CustomPainter {
  final Color color;
  DropdownArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomSortDropdown extends StatefulWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const CustomSortDropdown({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  State<CustomSortDropdown> createState() => _CustomSortDropdownState();
}

class _CustomSortDropdownState extends State<CustomSortDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  void _openDropdown() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 8),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: size.width + 120, // wider than button
                child: Material(
                  color: Colors.transparent,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.1 * value),
                        alignment: Alignment.topLeft,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: CustomPaint(
                            size: const Size(14, 7),
                            painter: DropdownArrowPainter(
                              color:
                                  Theme.of(context).cardTheme.color ??
                                  Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).cardTheme.color ??
                                Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDropdownItem(
                                'newest',
                                'newest_first'.tr,
                                LucideIcons.arrowDownUp,
                                Colors.blue,
                              ),
                              _buildDropdownItem(
                                'oldest',
                                'oldest_first'.tr,
                                LucideIcons.arrowDownUp,
                                Colors.grey,
                              ),
                              _buildDropdownItem(
                                'alpha_asc',
                                'a_z_name'.tr,
                                LucideIcons.arrowDownAZ,
                                Colors.purple,
                              ),
                              _buildDropdownItem(
                                'dues_high',
                                'highest_dues'.tr,
                                LucideIcons.database,
                                Colors.teal,
                                hasWarning: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  Widget _buildDropdownItem(
    String value,
    String label,
    IconData iconData,
    MaterialColor iconColor, {
    bool hasWarning = false,
  }) {
    final isSelected = widget.selectedValue == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        widget.onChanged(value);
        _closeDropdown();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.shade50.withValues(alpha: 0.5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withValues(alpha: 0.1)
                    : iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconData,
                size: 16,
                color: isSelected ? Colors.blue : iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (hasWarning) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  LucideIcons.check,
                  size: 12,
                  color: Colors.white,
                ),
              )
            else
              const Icon(LucideIcons.circle, size: 20, color: Colors.black12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String label = '';
    switch (widget.selectedValue) {
      case 'newest':
        label = 'Newest';
        break;
      case 'oldest':
        label = 'Old';
        break;
      case 'alpha_asc':
        label = 'A-Z';
        break;
      case 'dues_high':
        label = 'Dues';
        break;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.withValues(alpha: 0.1)
                : Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.arrowDownUp,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

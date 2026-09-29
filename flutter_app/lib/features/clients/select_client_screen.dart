import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_extensions.dart';
import 'clients_controller.dart';

enum ClientSortOption { aToZ, zToA, newestFirst, oldestFirst }

class SelectClientScreen extends StatefulWidget {
  const SelectClientScreen({super.key});

  @override
  State<SelectClientScreen> createState() => _SelectClientScreenState();
}

class _SelectClientScreenState extends State<SelectClientScreen> {
  final ClientsController controller = Get.find<ClientsController>();
  final TextEditingController _searchController = TextEditingController();
  
  List<Client> _filteredClients = [];
  ClientSortOption _currentSort = ClientSortOption.newestFirst;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    _worker = ever(controller.clients, (_) {
      if (mounted) _filterClients();
    });
    _filterClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _worker.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = controller.clients.where((client) {
        return client.name.toLowerCase().contains(query) ||
               client.phone.contains(query) ||
               client.email.toLowerCase().contains(query);
      }).toList();
      _applySort();
    });
  }

  void _applySort() {
    switch (_currentSort) {
      case ClientSortOption.aToZ:
        _filteredClients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ClientSortOption.zToA:
        _filteredClients.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ClientSortOption.newestFirst:
        _filteredClients.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
        break;
      case ClientSortOption.oldestFirst:
        _filteredClients.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aDate.compareTo(bDate);
        });
        break;
    }
  }

  String _getSortOptionText(ClientSortOption option) {
    switch (option) {
      case ClientSortOption.aToZ: return 'A to Z';
      case ClientSortOption.zToA: return 'Z to A';
      case ClientSortOption.newestFirst: return 'Newest First';
      case ClientSortOption.oldestFirst: return 'Oldest First';
    }
  }

  String _getSortOptionSvgPath(ClientSortOption option) {
    switch (option) {
      case ClientSortOption.aToZ: return 'assets/SVG/atoz.svg';
      case ClientSortOption.zToA: return 'assets/SVG/ztoa.svg';
      case ClientSortOption.newestFirst: return 'assets/SVG/newfirst.svg';
      case ClientSortOption.oldestFirst: return 'assets/SVG/oldfirst.svg';
    }
  }

  Color _getAvatarBgColor(String name, bool isDark) {
    if (name.isEmpty) return isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50;
    final colors = isDark 
      ? [
          Colors.blue.withValues(alpha: 0.15),
          Colors.green.withValues(alpha: 0.15),
          Colors.pink.withValues(alpha: 0.15),
          Colors.purple.withValues(alpha: 0.15),
          Colors.orange.withValues(alpha: 0.15),
          Colors.teal.withValues(alpha: 0.15),
        ]
      : [
          Colors.blue.shade50,
          Colors.green.shade50,
          Colors.pink.shade50,
          Colors.purple.shade50,
          Colors.orange.shade50,
          Colors.teal.shade50,
        ];
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  Color _getAvatarTextColor(String name, bool isDark) {
    if (name.isEmpty) return isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    final colors = isDark
      ? [
          Colors.blue.shade300,
          Colors.green.shade300,
          Colors.pink.shade300,
          Colors.purple.shade300,
          Colors.orange.shade300,
          Colors.teal.shade300,
        ]
      : [
          Colors.blue.shade700,
          Colors.green.shade700,
          Colors.pink.shade700,
          Colors.purple.shade700,
          Colors.orange.shade700,
          Colors.teal.shade700,
        ];
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/SVG/backarrow.svg',
            colorFilter: ColorFilter.mode(Theme.of(context).textTheme.displayLarge?.color ?? Colors.black, BlendMode.srcIn),
            width: 24,
            height: 24,
          ),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Client',
              style: context.typography.screenTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: context.typography.inputText.copyWith(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.displayLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or phone...',
                        hintStyle: context.typography.searchHint.copyWith(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: SvgPicture.asset(
                            'assets/SVG/search.svg',
                            colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn),
                            width: 18,
                            height: 18,
                          ),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<ClientSortOption>(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  elevation: 4,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 8),
                  onSelected: (ClientSortOption option) {
                    setState(() {
                      _currentSort = option;
                      _applySort();
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return ClientSortOption.values.map((option) {
                      final isSelected = _currentSort == option;
                      return PopupMenuItem<ClientSortOption>(
                        value: option,
                        padding: EdgeInsets.zero,
                        height: 48,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                _getSortOptionSvgPath(option),
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(
                                  isSelected ? Colors.blue.shade700 : Colors.grey.shade700, 
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getSortOptionText(option),
                                  style: TextStyle(
                                    color: isSelected ? Colors.blue.shade700 : Theme.of(context).textTheme.bodyLarge?.color,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, size: 20, color: Colors.blue.shade600),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.slidersHorizontal,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.clients.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_filteredClients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.users,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No clients found',
                  style: context.typography.emptyStateDescription.copyWith(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.50,
          ),
          itemCount: _filteredClients.length,
          itemBuilder: (context, index) {
            final client = _filteredClients[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.back(result: client.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _getAvatarBgColor(client.name, isDark),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getAvatarTextColor(client.name, isDark),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.withValues(alpha: 0.15) : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.chevronRight,
                              size: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name.toTitleCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.typography.clientName.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.displayLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/SVG/phone.svg',
                                width: 13,
                                height: 13,
                                colorFilter: ColorFilter.mode(Colors.grey.shade400, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  client.phone.isNotEmpty ? client.phone : 'No phone',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: client.phone.isNotEmpty ? Colors.grey.shade600 : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
            ),
          ],
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_extensions.dart';
import 'clients_controller.dart';

class SelectClientScreen extends StatefulWidget {
  const SelectClientScreen({super.key});

  @override
  State<SelectClientScreen> createState() => _SelectClientScreenState();
}

class _SelectClientScreenState extends State<SelectClientScreen> {
  final ClientsController controller = Get.find<ClientsController>();
  final TextEditingController _searchController = TextEditingController();
  
  List<Client> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _filteredClients = controller.clients;
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
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
    });
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
          icon: Icon(
            LucideIcons.arrowLeft,
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'select_client'.tr,
          style: context.typography.screenTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: Colors.grey.shade400,
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

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filteredClients.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final client = _filteredClients[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.back(result: client.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (Theme.of(context).cardTheme.color ?? Colors.white).withValues(alpha: isDark ? 0.6 : 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                            style: context.typography.buttonText.copyWith(
                              fontSize: 18,
                              color: context.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.typography.clientName.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).textTheme.displayLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(LucideIcons.phone, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  client.phone.isNotEmpty ? client.phone : 'No phone',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'import_data_controller.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImportDataController _controller = Get.put(ImportDataController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    final tabs = ['clients', 'inventory', 'invoices'];
    final selectedTab = tabs[_tabController.index];
    if (_controller.activeTab.value != selectedTab) {
      _controller.setActiveTab(selectedTab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.background,
      appBar: AppTopBar(
        title: 'import_legacy_data'.tr,
        subtitle: 'migrate_data_desc'.tr,
        showProfile: false,
        showBadge: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
          ),
          child: Column(
            children: [
              _buildTabBar(isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTabContent(isDark),
                    _buildTabContent(isDark),
                    _buildTabContent(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildActionCards(isDark),
          _buildPreviewSection(isDark),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerColor: Colors.transparent, // Disable native divider as we have container border
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.users, size: 18),
                SizedBox(width: 8),
                Text('clients'.tr),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.package, size: 18),
                SizedBox(width: 8),
                Text('inventory'.tr),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.fileText, size: 18),
                SizedBox(width: 8),
                Text('invoices'.tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final widgets = [
            _buildActionCard(
              title: 'download_template'.tr,
              subtitle: 'download_excel_desc'.tr,
              icon: LucideIcons.download,
              iconColor: Colors.blue,
              bgColor: isDark ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
              borderColor: isDark ? Colors.blue.shade900.withOpacity(0.5) : Colors.blue.shade100,
              buttonText: 'download_excel_btn'.tr,
              onTap: _controller.downloadTemplate,
              isDark: isDark,
            ),
            if (!isMobile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(LucideIcons.chevronRight, size: 32, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
            if (isMobile) const SizedBox(height: 16),
            _buildActionCard(
              title: 'upload_filled_excel'.tr,
              subtitle: 'upload_excel_desc'.tr,
              icon: LucideIcons.upload,
              iconColor: Colors.purple,
              bgColor: isDark ? Colors.purple.shade900.withOpacity(0.2) : Colors.purple.shade50,
              borderColor: isDark ? Colors.purple.shade900.withOpacity(0.5) : Colors.purple.shade100,
              buttonText: 'upload_excel_btn'.tr,
              onTap: _controller.pickFile,
              isDark: isDark,
              isUpload: true,
            ),
          ];

          return isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widgets)
              : Row(children: widgets.map((w) => w is Expanded ? w : (w is Padding ? w : Expanded(child: w))).toList());
        },
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String buttonText,
    required VoidCallback onTap,
    required bool isDark,
    bool isUpload = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Builder(builder: (context) {
            Widget buildButton(String label, bool isBusy) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isBusy ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    elevation: 0,
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: isBusy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            }

            if (isUpload) {
              return Obx(() {
                final btnLabel = _controller.selectedFileName.isNotEmpty
                    ? _controller.selectedFileName.value
                    : buttonText;
                final isBusy = _controller.isParsing.value;
                return buildButton(btnLabel, isBusy);
              });
            } else {
              return buildButton(buttonText, false);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    return Obx(() {
      if (_controller.parsedData.isEmpty) return const SizedBox.shrink();
      
      final data = _controller.parsedData.take(50).toList();
      final headers = data.isEmpty ? <String>[] : data.first.keys.toList();

      return Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_controller.parsedData.length} ' + 'parsed_rows_ready'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _controller.isImporting.value ? null : _controller.importData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: _controller.isImporting.value
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('start_import'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: data.isEmpty ? const SizedBox.shrink() : DataTable(
                headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1E293B) : Colors.white),
                dataRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : Colors.white),
                dividerThickness: 1,
                columns: headers
                    .map((h) => DataColumn(
                          label: Text(
                            h.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
                              letterSpacing: 1,
                            ),
                          ),
                        ))
                    .toList(),
                rows: data.map((row) {
                  return DataRow(
                    cells: headers.map((h) {
                      final val = row[h]?.toString() ?? '-';
                      return DataCell(
                        Text(
                          val.isEmpty ? '-' : val,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            if (_controller.parsedData.length > 50)
              Container(
                padding: const EdgeInsets.all(16),
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                alignment: Alignment.center,
                child: Text(
                  'showing_first_50_rows'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

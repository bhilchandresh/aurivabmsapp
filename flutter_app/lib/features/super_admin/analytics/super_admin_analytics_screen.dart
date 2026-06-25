import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/super_admin_top_bar.dart';
import 'super_admin_analytics_controller.dart';

class SuperAdminAnalyticsScreen extends StatelessWidget {
  const SuperAdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuperAdminAnalyticsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SuperAdminTopBar(),
            Expanded(
              child: Obx(() {
                return RefreshIndicator(
                  onRefresh: () => controller.fetchAnalytics(isRefresh: true),
                  color: Colors.blue.shade600,
                  backgroundColor: Colors.white,
                  child: controller.isLoading.value
                    ? _buildSkeletonUI(context)
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(context, controller),
                            const SizedBox(height: 24),
                            _buildCharts(context, controller),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, SuperAdminAnalyticsController controller) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final cards = [
      _buildStatCard(
        title: 'PLATFORM GMV',
        value: formatCurrency.format(controller.platformGMV.value),
        icon: Icons.currency_rupee,
        iconBgColor: Colors.blue.shade50,
        iconColor: Colors.blue.shade600,
      ),
      _buildStatCard(
        title: 'INVOICES PROCESSED',
        value: controller.invoicesProcessed.value.toString(),
        icon: LucideIcons.fileText,
        iconBgColor: Colors.green.shade50,
        iconColor: Colors.green.shade600,
      ),
      _buildStatCard(
        title: 'END CLIENTS MANAGED',
        value: controller.endClientsManaged.value.toString(),
        icon: LucideIcons.users,
        iconBgColor: Colors.purple.shade50,
        iconColor: Colors.purple.shade600,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
      );
    } else {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList(),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(BuildContext context, SuperAdminAnalyticsController controller) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Calculate Max Y for Bar Chart
    double maxTenants = 0;
    for (var item in controller.growthData) {
      double count = (item['newTenants'] ?? 0).toDouble();
      if (count > maxTenants) maxTenants = count;
    }
    maxTenants = (maxTenants * 1.5).ceilToDouble();
    if (maxTenants < 5) maxTenants = 5;

    final barChart = _buildChartContainer(
      title: 'NEW COMPANIES GROWTH',
      child: controller.growthData.isEmpty 
        ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
        : BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxTenants,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      if (idx >= 0 && idx < controller.growthData.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            controller.growthData[idx]['month'] ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value % (maxTenants / 4).ceil() != 0) return const SizedBox.shrink();
                      return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                    },
                    reservedSize: 28,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxTenants / 4).ceilToDouble(),
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5]);
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: controller.growthData.asMap().entries.map((entry) {
                int idx = entry.key;
                double count = (entry.value['newTenants'] ?? 0).toDouble();
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: count,
                      color: Colors.blue.shade500,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                );
              }).toList(),
            ),
          ),
    );

    // Calculate Max Y for Line Chart
    double maxMrr = 0;
    for (var item in controller.growthData) {
      double mrr = (item['mrr'] ?? 0).toDouble();
      if (mrr > maxMrr) maxMrr = mrr;
    }
    maxMrr = (maxMrr * 1.3).ceilToDouble();
    if (maxMrr < 1000) maxMrr = 1000;

    final lineChart = _buildChartContainer(
      title: 'ESTIMATED MRR (₹)',
      child: controller.growthData.isEmpty 
        ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
        : LineChart(
            LineChartData(
              minX: 0,
              maxX: (controller.growthData.length - 1).toDouble().clamp(0, double.infinity),
              minY: 0,
              maxY: maxMrr,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      if (idx >= 0 && idx < controller.growthData.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            controller.growthData[idx]['month'] ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                    },
                    reservedSize: 40,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5]);
                },
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: controller.growthData.asMap().entries.map((entry) {
                    int idx = entry.key;
                    double mrr = (entry.value['mrr'] ?? 0).toDouble();
                    return FlSpot(idx.toDouble(), mrr);
                  }).toList(),
                  isCurved: true,
                  color: Colors.green.shade500,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(radius: 4, color: Colors.green.shade500, strokeWidth: 2, strokeColor: Colors.white);
                  }),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.shade500.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
    );

    // Plan Distribution
    bool hasPlanData = controller.planDistribution.any((item) => (item['value'] ?? 0) > 0);
    
    final donutChartContainer = _buildChartContainer(
      title: 'PLAN DISTRIBUTION',
      child: !hasPlanData 
        ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
        : Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: controller.planDistribution.map<PieChartSectionData>((item) {
                      String name = item['name'] ?? '';
                      double val = (item['value'] ?? 0).toDouble();
                      Color c = Colors.grey;
                      if (name == 'Business') c = const Color(0xFFA855F7);
                      else if (name == 'Freelancer') c = const Color(0xFFCBD5E1);
                      else if (name == 'Pro') c = const Color(0xFF3B82F6);
                      
                      return PieChartSectionData(
                        color: c,
                        value: val,
                        title: val > 0 ? val.toInt().toString() : '',
                        radius: 30,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(const Color(0xFFA855F7), 'Business'),
                  const SizedBox(width: 16),
                  _buildLegendItem(const Color(0xFFCBD5E1), 'Freelancer'),
                  const SizedBox(width: 16),
                  _buildLegendItem(const Color(0xFF3B82F6), 'Pro'),
                ],
              ),
            ],
          ),
    );

    // Feature Adoption Max calculation
    double maxAdoption = 0;
    for (var item in controller.featureAdoption) {
      double val = (item['users'] ?? 0).toDouble();
      if (val > maxAdoption) maxAdoption = val;
    }
    if (maxAdoption == 0) maxAdoption = 1;

    final horizontalBarChartContainer = _buildChartContainer(
      title: 'FEATURE ADOPTION',
      child: controller.featureAdoption.isEmpty 
        ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
        : Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: controller.featureAdoption.map<Widget>((item) {
                          return Text(item['name'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold));
                        }).toList(),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(5, (index) {
                              return Container(width: 1, color: Colors.grey.shade200);
                            }),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: controller.featureAdoption.map<Widget>((item) {
                              double val = (item['users'] ?? 0).toDouble();
                              double factor = (val / maxAdoption).clamp(0.0, 1.0);
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: factor,
                                child: Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade500,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        val > 0 ? val.toInt().toString() : '',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 80, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('0', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text((maxAdoption * 0.25).toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    Text((maxAdoption * 0.50).toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    Text((maxAdoption * 0.75).toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    Text(maxAdoption.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
    );

    if (isDesktop) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: barChart),
              const SizedBox(width: 24),
              Expanded(child: lineChart),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: donutChartContainer),
              const SizedBox(width: 24),
              Expanded(child: horizontalBarChartContainer),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          barChart,
          const SizedBox(height: 24),
          lineChart,
          const SizedBox(height: 24),
          donutChartContainer,
          const SizedBox(height: 24),
          horizontalBarChartContainer,
        ],
      );
    }
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonUI(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SkeletonLoader(width: double.infinity, height: 80, borderRadius: BorderRadius.circular(12)),
                ),
              )),
            )
          else
            Column(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SkeletonLoader(width: double.infinity, height: 80, borderRadius: BorderRadius.circular(12)),
              )),
            ),
          const SizedBox(height: 24),
          if (isDesktop) ...[
            Row(
              children: [
                Expanded(child: SkeletonLoader(width: double.infinity, height: 320, borderRadius: BorderRadius.circular(16))),
                const SizedBox(width: 24),
                Expanded(child: SkeletonLoader(width: double.infinity, height: 320, borderRadius: BorderRadius.circular(16))),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: SkeletonLoader(width: double.infinity, height: 320, borderRadius: BorderRadius.circular(16))),
                const SizedBox(width: 24),
                Expanded(child: SkeletonLoader(width: double.infinity, height: 320, borderRadius: BorderRadius.circular(16))),
              ],
            ),
          ] else ...[
            SkeletonLoader(width: double.infinity, height: 320, borderRadius: BorderRadius.circular(16)),
            const SizedBox(height: 24),
            SkeletonLoader(width: double.infinity, height: 320, borderRadius: BorderRadius.circular(16)),
            const SizedBox(height: 24),
            SkeletonLoader(width: double.infinity, height: 320, borderRadius: BorderRadius.circular(16)),
            const SizedBox(height: 24),
            SkeletonLoader(width: double.infinity, height: 320, borderRadius: BorderRadius.circular(16)),
          ],
        ],
      ),
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const SkeletonLoader({super.key, required this.width, required this.height, this.borderRadius});

  @override
  _SkeletonLoaderState createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

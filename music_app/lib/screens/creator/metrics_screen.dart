import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/analytics_provider.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final data = provider.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error al cargar métricas',
                          style: TextStyle(color: Colors.red[400])),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => provider.loadMetrics(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : data == null
                  ? const Center(child: Text('No hay datos disponibles'))
                  : RefreshIndicator(
                      onRefresh: () => provider.loadMetrics(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSummaryCards(data),
                          const SizedBox(height: 24),
                          _buildDailyChart(data),
                          const SizedBox(height: 24),
                          _buildTopSongs(data),
                          const SizedBox(height: 24),
                          _buildSongPercentageChart(data),
                          const SizedBox(height: 24),
                          _buildHourlyChart(data),
                          const SizedBox(height: 24),
                          _buildWeekdayChart(data),
                          const SizedBox(height: 24),
                          _buildCountriesTable(data),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSummaryCards(AnalyticsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen (últimos 30 días)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Total Streams',
                '${data.summary.totalStreamsLast30}',
                Icons.play_circle_fill,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                'Promedio Diario',
                '${data.summary.avgDaily}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Canciones',
                '${data.totalSongs}',
                Icons.music_note,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                'Total Plays',
                '${data.totalPlays}',
                Icons.bar_chart,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.summary.bestDayDate.isNotEmpty
                      ? 'Mejor día: ${data.summary.bestDayDate} (${data.summary.bestDayViews} streams)'
                      : 'Aún no hay datos de streams',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDailyChart(AnalyticsData data) {
    if (data.dailyChart.isEmpty) return const SizedBox.shrink();

    final maxY = data.dailyChart.fold<int>(0, (max, d) => d.views > max ? d.views : max);
    final adjustedMaxY = maxY > 0 ? (maxY * 1.3).ceilToDouble() : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vistas diarias (30 días)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: adjustedMaxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${data.dailyChart[groupIndex].date}\n${rod.toY.toInt()} vistas',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.dailyChart.length) return const SizedBox.shrink();
                      // Mostrar solo cada 3 días
                      if (idx % 3 != 0) return const SizedBox.shrink();
                      final parts = data.dailyChart[idx].date.split('-');
                      final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : '';
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(label, style: const TextStyle(fontSize: 9)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ((adjustedMaxY > 0 ? adjustedMaxY : 1) / 4).ceilToDouble(),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.dailyChart.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.views.toDouble(),
                      color: Theme.of(context).colorScheme.primary,
                      width: 6,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongPercentageChart(AnalyticsData data) {
    if (data.songsWithPercentage.isEmpty) return const SizedBox.shrink();

    // Tomar top 5 para el gráfico de pastel
    final topSongs = data.songsWithPercentage.take(5).toList();
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('% de vistas por canción',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: topSongs.asMap().entries.map((entry) {
                      final sp = entry.value;
                      return PieChartSectionData(
                        color: colors[entry.key % colors.length],
                        value: sp.percentage,
                        title: '${sp.percentage}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topSongs.asMap().entries.map((entry) {
                    final sp = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: colors[entry.key % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sp.title,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${sp.percentage}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopSongs(AnalyticsData data) {
    if (data.topSongs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🏆 Top Canciones',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...data.topSongs.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text('#${s.rank}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: s.rank <= 3 ? Colors.amber : Colors.grey,
                      )),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.title, overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.play_arrow, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${s.plays} plays',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildHourlyChart(AnalyticsData data) {
    if (data.hourlyChart.isEmpty) return const SizedBox.shrink();

    final maxY = data.hourlyChart.fold<int>(0, (max, d) => d.views > max ? d.views : max);
    final adjustedMaxY = maxY > 0 ? (maxY * 1.3).ceilToDouble() : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🕐 Streams por hora (30 días)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: adjustedMaxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                        '${spot.x.toInt()}:00\n${spot.y.toInt()} streams',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 3,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}h',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ((adjustedMaxY > 0 ? adjustedMaxY : 1) / 4).ceilToDouble(),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.hourlyChart.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.views.toDouble());
                  }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayChart(AnalyticsData data) {
    if (data.weekdayChart.isEmpty) return const SizedBox.shrink();

    final maxY = data.weekdayChart.fold<int>(0, (max, d) => d.views > max ? d.views : max);
    final adjustedMaxY = maxY > 0 ? (maxY * 1.3).ceilToDouble() : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📅 Streams por día de la semana (30 días)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: adjustedMaxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${data.weekdayChart[groupIndex].day}\n${rod.toY.toInt()} streams',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.weekdayChart.length) return const SizedBox.shrink();
                      return Text(data.weekdayChart[idx].day,
                          style: const TextStyle(fontSize: 11));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ((adjustedMaxY > 0 ? adjustedMaxY : 1) / 4).ceilToDouble(),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.weekdayChart.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.views.toDouble(),
                      color: Colors.orange,
                      width: 18,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountriesTable(AnalyticsData data) {
    if (data.countries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🌎 Oyentes por país (30 días)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: data.countries.asMap().entries.map((entry) {
              final c = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: entry.key < data.countries.length - 1
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                        ),
                      )
                    : null,
                child: Row(
                  children: [
                    Text('#${entry.key + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(c.country),
                    ),
                    Text('${c.count} streams',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text('${c.percentage}%',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
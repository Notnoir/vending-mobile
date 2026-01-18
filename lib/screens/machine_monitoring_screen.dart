import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/machine_data_service.dart';

class MachineMonitoringScreen extends StatefulWidget {
  final String? machineId;

  const MachineMonitoringScreen({super.key, this.machineId});

  @override
  State<MachineMonitoringScreen> createState() =>
      _MachineMonitoringScreenState();
}

class _MachineMonitoringScreenState extends State<MachineMonitoringScreen> {
  String _selectedMachine = 'VM01';
  String _selectedTimeSlot = 'all';
  List<Map<String, dynamic>> _monitoringData = [];
  bool _isLoading = true;
  String _selectedPeriod = 'today';
  final _machineDataService = MachineDataService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.machineId != null) {
      _selectedMachine = widget.machineId!;
    }
    _loadMonitoringData();
  }

  Future<void> _loadMonitoringData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Calculate date range based on selected period
      final now = DateTime.now();
      String? fromDate;
      String? toDate = now.toIso8601String();

      switch (_selectedPeriod) {
        case 'today':
          fromDate = DateTime(now.year, now.month, now.day).toIso8601String();
          break;
        case 'week':
          fromDate = now.subtract(const Duration(days: 7)).toIso8601String();
          break;
        case 'month':
          fromDate = now.subtract(const Duration(days: 30)).toIso8601String();
          break;
      }

      // Fetch real data from API
      final response = await _machineDataService.getMachineHistory(
        machineId: _selectedMachine,
        from: fromDate,
        to: toDate,
        limit: 100,
      );

      if (response['success'] == true) {
        final List<dynamic> rawData = response['data'] ?? [];

        setState(() {
          _monitoringData = rawData.map((item) {
            return {
              'recorded_at': DateTime.parse(
                item['recorded_at'] ?? DateTime.now().toIso8601String(),
              ),
              'temperature': (item['temperature'] as num?)?.toDouble() ?? 0.0,
              'humidity': (item['humidity'] as num?)?.toDouble() ?? 0.0,
              'door_status': item['door_status'] ?? 'unknown',
              'power_status': item['power_status'] ?? 'unknown',
              'status': item['status'] ?? 'unknown',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load data';
          _monitoringData = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading monitoring data: $e');
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _monitoringData = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredData() {
    if (_selectedTimeSlot == 'all') return _monitoringData;
    final targetHour = int.parse(_selectedTimeSlot);
    return _monitoringData
        .where((data) => (data['recorded_at'] as DateTime).hour == targetHour)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF102220)
          : const Color(0xFFF6F8F8),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          'Machine Monitoring',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMonitoringData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState(isDark)
          : RefreshIndicator(
              onRefresh: _loadMonitoringData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMachineSelector(isDark),
                    const SizedBox(height: 16),
                    _buildPeriodSelector(isDark),
                    const SizedBox(height: 16),
                    _buildTimeSlotTabs(isDark),
                    const SizedBox(height: 24),

                    // Show charts only if data available
                    if (_monitoringData.isNotEmpty) ...[
                      _buildChartCard(
                        'Temperature (°C)',
                        Icons.thermostat_outlined,
                        Colors.orange,
                        isDark,
                        _buildTemperatureChart(),
                      ),
                      const SizedBox(height: 16),
                      _buildChartCard(
                        'Humidity (%)',
                        Icons.water_drop_outlined,
                        Colors.blue,
                        isDark,
                        _buildHumidityChart(),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusCards(isDark),
                    ] else
                      _buildNoDataState(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMonitoringData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF13ECDA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No monitoring data found for the selected period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMachine,
          isExpanded: true,
          items: ['VM01', 'VM02', 'VM03'].map((machine) {
            return DropdownMenuItem(
              value: machine,
              child: Row(
                children: [
                  Icon(
                    Icons.local_convenience_store,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Machine $machine',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMachine = value;
                _loadMonitoringData();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildPeriodChip('Today', 'today', isDark)),
        const SizedBox(width: 8),
        Expanded(child: _buildPeriodChip('This Week', 'week', isDark)),
        const SizedBox(width: 8),
        Expanded(child: _buildPeriodChip('This Month', 'month', isDark)),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value, bool isDark) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () => setState(() {
        _selectedPeriod = value;
        _loadMonitoringData();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF13ECDA)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF13ECDA)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTimeSlotTab('All', 'all', isDark),
          const SizedBox(width: 8),
          _buildTimeSlotTab('10:00', '10', isDark),
          const SizedBox(width: 8),
          _buildTimeSlotTab('12:00', '12', isDark),
          const SizedBox(width: 8),
          _buildTimeSlotTab('14:00', '14', isDark),
        ],
      ),
    );
  }

  Widget _buildTimeSlotTab(String label, String value, bool isDark) {
    final isSelected = _selectedTimeSlot == value;
    return InkWell(
      onTap: () => setState(() => _selectedTimeSlot = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF13ECDA)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF13ECDA)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(
    String title,
    IconData icon,
    Color color,
    bool isDark,
    Widget chart,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(height: 200, child: chart),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    final filteredData = _getFilteredData();
    if (filteredData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final spots = filteredData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['temperature'] as num).toDouble(),
      );
    }).toList();

    // Calculate dynamic Y-axis range
    final temps = filteredData
        .map((e) => (e['temperature'] as num).toDouble())
        .toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final tempRange = maxTemp - minTemp;
    final minY = (minTemp - tempRange * 0.2).floorToDouble();
    final maxY = (maxTemp + tempRange * 0.2).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 8),
      child: LineChart(
        LineChartData(
          clipData: FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: filteredData.length > 5
                    ? (filteredData.length / 5).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= filteredData.length)
                    return const SizedBox.shrink();
                  final date =
                      filteredData[value.toInt()]['recorded_at'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM\nHH:mm').format(date),
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: ((maxY - minY) / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}°C',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (filteredData.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.orange,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.3),
                    Colors.orange.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHumidityChart() {
    final filteredData = _getFilteredData();
    if (filteredData.isEmpty)
      return const Center(child: Text('No data available'));

    final spots = filteredData
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            (entry.value['humidity'] as num).toDouble(),
          ),
        )
        .toList();

    // Calculate dynamic Y-axis range
    final humidities = filteredData
        .map((e) => (e['humidity'] as num).toDouble())
        .toList();
    final minHum = humidities.reduce((a, b) => a < b ? a : b);
    final maxHum = humidities.reduce((a, b) => a > b ? a : b);
    final humRange = maxHum - minHum;
    final minY = (minHum - humRange * 0.2).floorToDouble();
    final maxY = (maxHum + humRange * 0.2).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 8),
      child: LineChart(
        LineChartData(
          clipData: FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: filteredData.length > 5
                    ? (filteredData.length / 5).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= filteredData.length)
                    return const SizedBox.shrink();
                  final date =
                      filteredData[value.toInt()]['recorded_at'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM\nHH:mm').format(date),
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: ((maxY - minY) / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (filteredData.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.blue,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards(bool isDark) {
    if (_monitoringData.isEmpty) return const SizedBox.shrink();
    final latestData = _monitoringData.last;

    final doorStatus = latestData['door_status'] ?? 'unknown';
    final powerStatus = latestData['power_status'] ?? 'unknown';
    final status = latestData['status'] ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                Icons.door_front_door_outlined,
                'Door Status',
                doorStatus,
                _getStatusColor(doorStatus),
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                Icons.power_outlined,
                'Power Status',
                powerStatus,
                _getStatusColor(powerStatus),
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatusCard(
          Icons.monitor_heart_outlined,
          'Machine Status',
          status,
          _getStatusColor(status),
          isDark,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
      case 'closed':
        return Colors.green;
      case 'warning':
      case 'open':
        return Colors.orange;
      case 'error':
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusCard(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

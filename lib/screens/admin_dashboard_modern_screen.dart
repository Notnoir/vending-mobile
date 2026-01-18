import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'admin_features_screen.dart';
import 'machine_monitoring_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_users_screen.dart';
import 'admin_finance_screen.dart';

class AdminDashboardModernScreen extends StatefulWidget {
  const AdminDashboardModernScreen({super.key});

  @override
  State<AdminDashboardModernScreen> createState() =>
      _AdminDashboardModernScreenState();
}

class _AdminDashboardModernScreenState
    extends State<AdminDashboardModernScreen> {
  final _authService = AuthService();
  final _orderService = OrderService();
  int _selectedIndex = 0;

  // Dashboard data
  Map<String, dynamic> _dashboardStats = {
    'activeMachines': '0/0',
    'todayRevenue': 'Rp 0',
    'lowStockItems': '0',
    'alerts': '0',
  };

  List<Map<String, dynamic>> _machineAlerts = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _weeklySalesData = [];
  double _totalWeeklySales = 0;
  bool _isLoadingWeeklySales = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load data from API
      await Future.wait([
        _loadStats(),
        _loadMachineAlerts(),
        _loadRecentTransactions(),
        _loadWeeklySales(),
      ]);
    } catch (e) {
      print('Error loading dashboard: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final apiService = ApiService();
      final machineId = 'VM01'; // Or get from config

      double todayRevenue = 0;
      int lowStockCount = 0;
      int emptySlots = 0;
      int activeMachines = 0;
      int totalMachines = 1;

      // Get today's revenue from orders
      try {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final orders = await _orderService.getOrdersByDateRange(
          machineId: machineId,
          startDate: startOfDay,
          endDate: now.add(const Duration(days: 1)),
        );

        for (var order in orders) {
          if (order['status'] == 'COMPLETED' || order['status'] == 'PAID') {
            todayRevenue += (order['total_amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } catch (e) {
        print('Error loading revenue: $e');
      }

      // Get stock levels from products/available (alternative endpoint)
      try {
        final products = await apiService.get('/products/available');
        if (products is List) {
          for (var product in products) {
            final currentStock = product['currentStock'] ?? 0;
            final capacity = product['capacity'] ?? 1;
            final stockPercentage = (currentStock / capacity) * 100;

            if (currentStock == 0) {
              emptySlots++;
            } else if (stockPercentage <= 20) {
              lowStockCount++;
            }
          }
        }
      } catch (e) {
        print('Error loading stock: $e');
      }

      // Get machine data for status
      try {
        final machineData = await apiService.get('/machine-data/latest');
        final machines = machineData['data'] ?? [];
        activeMachines = machines.where((m) => m['status'] == 'ONLINE').length;
        totalMachines = machines.length > 0 ? machines.length : 1;
      } catch (e) {
        print('Error loading machine data: $e');
      }

      // Calculate alerts (low stock + empty slots)
      final alertCount = lowStockCount + emptySlots;

      setState(() {
        _dashboardStats = {
          'activeMachines': '$activeMachines/$totalMachines',
          'todayRevenue':
              'Rp ${NumberFormat('#,###', 'id_ID').format(todayRevenue)}',
          'lowStockItems': '$lowStockCount',
          'alerts': '$alertCount',
        };
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadMachineAlerts() async {
    try {
      final apiService = ApiService();
      final machineId = 'VM01';

      List<Map<String, dynamic>> alerts = [];

      // Get stock alerts from products/available
      try {
        final products = await apiService.get('/products/available');
        if (products is List) {
          for (var product in products) {
            final currentStock = product['currentStock'] ?? 0;
            final capacity = product['capacity'] ?? 1;
            final stockPercentage = (currentStock / capacity) * 100;

            if (currentStock == 0) {
              alerts.add({
                'id': machineId,
                'title': 'Machine $machineId - Out of Stock',
                'subtitle': '${product['name']} (${currentStock}/${capacity})',
                'icon': Icons.inventory_2_outlined,
                'iconColor': Colors.red,
                'iconBg': Colors.red.withOpacity(0.15),
              });
            } else if (stockPercentage <= 20) {
              alerts.add({
                'id': machineId,
                'title': 'Machine $machineId - Low Stock',
                'subtitle': '${product['name']} (${currentStock}/${capacity})',
                'icon': Icons.inventory_2_outlined,
                'iconColor': Colors.orange,
                'iconBg': Colors.orange.withOpacity(0.15),
              });
            }
          }
        }
      } catch (e) {
        print('Error loading stock alerts: $e');
      }

      // Get machine telemetry alerts
      try {
        final machineData = await apiService.get(
          '/machine-data/machine/$machineId?limit=1',
        );
        final data = machineData['data'] ?? [];
        if (data.isNotEmpty) {
          final latest = data[0];
          final temp = latest['temperature'];

          // Temperature alert (if too high or too low)
          if (temp != null) {
            if (temp > 30 || temp < 2) {
              alerts.add({
                'id': machineId,
                'title': 'Machine $machineId - Temperature Alert',
                'subtitle': 'Temperature: ${temp.toStringAsFixed(1)}°C',
                'icon': Icons.thermostat_outlined,
                'iconColor': Colors.amber,
                'iconBg': Colors.amber.withOpacity(0.15),
              });
            }
          }
        }
      } catch (e) {
        print('Error loading telemetry alerts: $e');
      }

      setState(() {
        _machineAlerts = alerts.take(5).toList(); // Limit to 5 alerts
      });
    } catch (e) {
      print('Error loading alerts: $e');
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final apiService = ApiService();
      final machineId = 'VM01';

      // Get recent orders
      final response = await apiService.get(
        '/orders/machine/$machineId?limit=5',
      );
      final orders = response['orders'] ?? [];

      List<Map<String, dynamic>> transactions = [];
      for (var order in orders) {
        final createdAt = DateTime.parse(order['created_at']);
        final timeStr = DateFormat('HH:mm').format(createdAt);

        transactions.add({
          'product': order['product_name'] ?? 'Unknown Product',
          'machine': 'Machine $machineId',
          'time': timeStr,
          'amount':
              'Rp ${NumberFormat('#,###', 'id_ID').format(order['total_amount'] ?? 0)}',
          'status': order['status'],
        });
      }

      setState(() {
        _recentTransactions = transactions;
      });
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> _loadWeeklySales() async {
    setState(() => _isLoadingWeeklySales = true);
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Initialize daily sales map
      Map<String, double> dailySales = {};
      List<Map<String, dynamic>> salesData = [];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(date);
        dailySales[key] = 0;
        salesData.add({
          'date': date,
          'dayName': DateFormat('EEE').format(date),
          'amount': 0.0,
        });
      }

      // Fetch orders from API
      try {
        final orders = await _orderService.getOrdersByDateRange(
          machineId: 'VM01', // or get from config
          startDate: sevenDaysAgo,
          endDate: now.add(const Duration(days: 1)),
        );

        // Aggregate by day
        for (var order in orders) {
          if (order['status'] == 'COMPLETED' || order['status'] == 'PAID') {
            final createdAt = DateTime.parse(order['created_at']);
            final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
            final amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

            if (dailySales.containsKey(dateKey)) {
              dailySales[dateKey] = (dailySales[dateKey] ?? 0) + amount;
            }
          }
        }

        // Update salesData with actual amounts
        for (int i = 0; i < salesData.length; i++) {
          final dateKey = DateFormat('yyyy-MM-dd').format(salesData[i]['date']);
          salesData[i]['amount'] = dailySales[dateKey] ?? 0.0;
        }
      } catch (e) {
        print('Error fetching orders for weekly sales: $e');
        // Keep zeros if API fails
      }

      double total = salesData.fold(
        0,
        (sum, item) => sum + (item['amount'] as double),
      );

      setState(() {
        _weeklySalesData = salesData;
        _totalWeeklySales = total;
        _isLoadingWeeklySales = false;
      });
    } catch (e) {
      print('Error loading weekly sales: $e');
      setState(() {
        _isLoadingWeeklySales = false;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = _authService.userData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF102220)
          : const Color(0xFFF6F8F8),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardView(isDark, userData),
            const AdminFeaturesScreen(),
            const AdminInventoryScreen(),
            const AdminUsersScreen(),
            const AdminFinanceScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  Widget _buildDashboardView(bool isDark, Map<String, dynamic>? userData) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar
            _buildTopAppBar(isDark, userData),

            // Stats Cards
            _buildStatsCards(isDark),

            // Weekly Sales Chart
            _buildWeeklySalesSection(isDark),

            // Machine Monitoring Menu
            _buildMonitoringMenuSection(isDark),

            // Machine Status
            _buildMachineStatusSection(isDark),

            // Latest Transactions
            _buildLatestTransactionsSection(isDark),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(bool isDark, Map<String, dynamic>? userData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: _handleLogout,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF13ECDA).withOpacity(0.1),
              ),
              child: Icon(
                Icons.account_circle,
                size: 32,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    final stats = [
      {
        'label': 'Active Machines',
        'value': _dashboardStats['activeMachines'],
        'color': Colors.blue,
      },
      {
        'label': "Today's Revenue",
        'value': _dashboardStats['todayRevenue'],
        'color': Colors.green,
      },
      {
        'label': 'Low Stock Items',
        'value': _dashboardStats['lowStockItems'],
        'color': Colors.orange,
      },
      {
        'label': 'Alerts',
        'value': _dashboardStats['alerts'],
        'color': Colors.red,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat, isDark)).toList(),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isDark) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
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
          Text(
            stat['label'],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stat['value'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: stat['label'] == 'Alerts'
                  ? Colors.red
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySalesSection(bool isDark) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Weekly Sales',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: _isLoadingWeeklySales
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatCurrency.format(_totalWeeklySales),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Last 7 Days',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+5.2%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_weeklySalesData.isNotEmpty)
                        SizedBox(
                          height: 150,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY:
                                    _weeklySalesData
                                        .map((e) => e['amount'] as double)
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.2,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                          return BarTooltipItem(
                                            formatCurrency.format(rod.toY),
                                            TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >=
                                            _weeklySalesData.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            _weeklySalesData[value
                                                .toInt()]['dayName'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                barGroups: _weeklySalesData.asMap().entries.map(
                                  (entry) {
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value['amount'] as double,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF13ECDA),
                                              Color(0xFF0D9B8A),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          width: 20,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(6),
                                            topRight: Radius.circular(6),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: Text(
                            'No sales data available',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonitoringMenuSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
          child: Text(
            'Machine Monitoring',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildMonitoringCard(
                icon: Icons.dashboard_outlined,
                title: 'All Machines',
                subtitle: 'View machines',
                color: Colors.blue,
                isDark: isDark,
                onTap: () {
                  setState(() => _selectedIndex = 1);
                },
              ),
              _buildMonitoringCard(
                icon: Icons.thermostat_outlined,
                title: 'Temperature',
                subtitle: 'Monitor temp',
                color: Colors.orange,
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MachineMonitoringScreen(),
                    ),
                  );
                },
              ),
              _buildMonitoringCard(
                icon: Icons.water_drop_outlined,
                title: 'Humidity',
                subtitle: 'Monitor humidity',
                color: Colors.cyan,
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MachineMonitoringScreen(),
                    ),
                  );
                },
              ),
              _buildMonitoringCard(
                icon: Icons.inventory_2_outlined,
                title: 'Stock Status',
                subtitle: 'Check inventory',
                color: Colors.green,
                isDark: isDark,
                onTap: () {
                  setState(() => _selectedIndex = 2);
                },
              ),
            ],
          ),
        ),
        // Info Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.withOpacity(0.15)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Machine monitoring features coming soon!\nScheduled data at 10:00, 12:00, 14:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.blue[200] : Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonitoringCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineStatusSection(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Machine Status',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _selectedIndex = 1);
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF13ECDA),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: _machineAlerts
                .map((alert) => _buildMachineAlertCard(alert, isDark))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMachineAlertCard(Map<String, dynamic> alert, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: alert['iconBg'],
              shape: BoxShape.circle,
            ),
            child: Icon(alert['icon'], color: alert['iconColor'], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['subtitle'],
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestTransactionsSection(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Transactions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to transactions
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF13ECDA),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: _recentTransactions
                .map(
                  (transaction) => _buildTransactionCard(transaction, isDark),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF13ECDA).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF13ECDA),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['product'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction['machine']} - ${transaction['time']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction['amount'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(height: 16),
          Text(
            'Users Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            index: 0,
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.dashboard_customize_outlined,
            activeIcon: Icons.dashboard_customize,
            label: 'Features',
            index: 1,
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            label: 'Inventory',
            index: 2,
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.group_outlined,
            activeIcon: Icons.group,
            label: 'Users',
            index: 3,
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.attach_money,
            activeIcon: Icons.attach_money,
            label: 'Finance',
            index: 4,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFF13ECDA)
                  : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF13ECDA)
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

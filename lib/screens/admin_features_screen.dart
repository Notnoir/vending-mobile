import 'package:flutter/material.dart';
import 'admin_announcements_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_users_screen.dart';
import 'admin_finance_screen.dart';

class AdminFeaturesScreen extends StatelessWidget {
  const AdminFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1C1C),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: 'Machine ID: '),
                        TextSpan(
                          text: 'MV-042',
                          style: TextStyle(
                            color: Color(0xFF13DAEC),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' | Logged in as: SuperAdmin'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Feature Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                _FeatureCard(
                  icon: Icons.inventory_2,
                  title: 'Inventory',
                  subtitle: 'Manage Stock',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminInventoryScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.group,
                  title: 'Users',
                  subtitle: 'Access Control',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminUsersScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.payments,
                  title: 'Finance',
                  subtitle: 'Sales Reports',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminFinanceScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.campaign,
                  title: 'Announcements',
                  subtitle: 'Manage Ads',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminAnnouncementsScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.thermostat,
                  title: 'Temperature',
                  subtitle: 'Climate Control',
                  onTap: () {
                    _showComingSoon(context, 'Temperature');
                  },
                ),
                _FeatureCard(
                  icon: Icons.receipt_long,
                  title: 'Transactions',
                  subtitle: 'Order History',
                  onTap: () {
                    _showComingSoon(context, 'Transactions');
                  },
                ),
                _FeatureCard(
                  icon: Icons.settings_suggest,
                  title: 'Settings',
                  subtitle: 'System Config',
                  onTap: () {
                    _showComingSoon(context, 'Settings');
                  },
                ),
                _FeatureCard(
                  icon: Icons.monitor_heart,
                  title: 'Health',
                  subtitle: 'Status Check',
                  onTap: () {
                    _showComingSoon(context, 'Health');
                  },
                ),
              ]),
            ),
          ),

          // Bottom Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                children: [
                  // Status Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.thermostat,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '4°C',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Diagnostics Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _showDiagnostics(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7F4F4),
                        foregroundColor: const Color(0xFF13DAEC),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFF13DAEC),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.build, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Run System Diagnostics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: const Color(0xFF13DAEC),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showDiagnostics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'System Diagnostics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _DiagnosticItem(
              icon: Icons.wifi,
              label: 'Network',
              value: 'Connected',
              status: DiagnosticStatus.good,
            ),
            _DiagnosticItem(
              icon: Icons.thermostat,
              label: 'Temperature',
              value: '4°C',
              status: DiagnosticStatus.good,
            ),
            _DiagnosticItem(
              icon: Icons.storage,
              label: 'Storage',
              value: '45% Used',
              status: DiagnosticStatus.good,
            ),
            _DiagnosticItem(
              icon: Icons.memory,
              label: 'Memory',
              value: '2.1 GB / 4 GB',
              status: DiagnosticStatus.warning,
            ),
            _DiagnosticItem(
              icon: Icons.battery_full,
              label: 'Backup Battery',
              value: '100%',
              status: DiagnosticStatus.good,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13DAEC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF13DAEC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: const Color(0xFF13DAEC),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C1C),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              // Subtitle
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DiagnosticStatus { good, warning, error }

class _DiagnosticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final DiagnosticStatus status;

  const _DiagnosticItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  }) : super(key: key);

  Color get statusColor {
    switch (status) {
      case DiagnosticStatus.good:
        return const Color(0xFF10B981);
      case DiagnosticStatus.warning:
        return const Color(0xFFF59E0B);
      case DiagnosticStatus.error:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: statusColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

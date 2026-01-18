import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'create_announcement_screen.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  // Stats
  int _totalCount = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);

    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/announcements'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Announcements response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Backend returns data in 'data' field
        final announcements =
            (data['data'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];

        setState(() {
          _announcements = announcements;
          _calculateStats();
          _isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Unauthorized access. Please login as admin.');
      } else {
        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching announcements: $e');
      setState(() => _isLoading = false);
      _showError('Error loading announcements: $e');
    }
  }

  void _calculateStats() {
    _totalCount = _announcements.length;
    _activeCount = _announcements.where((a) => a['is_active'] == true).length;
    _inactiveCount = _totalCount - _activeCount;
  }

  Future<String?> _getToken() async {
    // Get actual token from AuthService
    final authService = AuthService();
    await authService.init();

    if (authService.token == null) {
      print('No auth token found - user may need to login');
    }

    return authService.token;
  }

  List<Map<String, dynamic>> get _filteredAnnouncements {
    var filtered = _announcements.where((announcement) {
      final matchesSearch =
          announcement['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          announcement['message'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesFilter =
          _filterStatus == 'all' ||
          (_filterStatus == 'active' && announcement['is_active'] == true) ||
          (_filterStatus == 'inactive' && announcement['is_active'] == false);

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort by created_at descending
    filtered.sort((a, b) {
      final dateA = DateTime.parse(
        a['created_at'] ?? DateTime.now().toIso8601String(),
      );
      final dateB = DateTime.parse(
        b['created_at'] ?? DateTime.now().toIso8601String(),
      );
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  Future<void> _toggleActive(int id, bool currentStatus) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/announcements/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'is_active': !currentStatus}),
      );

      if (response.statusCode == 200) {
        _fetchAnnouncements();
        _showSuccess(
          !currentStatus
              ? 'Announcement activated'
              : 'Announcement deactivated',
        );
      } else {
        throw Exception('Failed to update announcement');
      }
    } catch (e) {
      _showError('Error updating announcement: $e');
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    final confirmed = await _showConfirmDialog(
      'Delete Announcement',
      'Are you sure you want to delete this announcement?',
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/announcements/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchAnnouncements();
        _showSuccess('Announcement deleted');
      } else {
        throw Exception('Failed to delete announcement');
      }
    } catch (e) {
      _showError('Error deleting announcement: $e');
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ERROR':
        return const Color(0xFFEF4444);
      case 'WARNING':
      case 'MAINTENANCE':
        return const Color(0xFFF59E0B);
      case 'PROMOTION':
        return const Color(0xFFA855F7);
      case 'INFO':
      default:
        return const Color(0xFF13DAEC);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'ERROR':
        return Icons.error;
      case 'WARNING':
        return Icons.warning;
      case 'MAINTENANCE':
        return Icons.build;
      case 'PROMOTION':
        return Icons.celebration;
      case 'INFO':
      default:
        return Icons.info;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAnnouncementScreen(
          onSuccess: () {
            _fetchAnnouncements();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: const Color(0xFF13DAEC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAnnouncements,
        child: Column(
          children: [
            // Stats Cards
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  _buildStatCard('Total', _totalCount, Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard('Active', _activeCount, Colors.green),
                  const SizedBox(width: 12),
                  _buildStatCard('Inactive', _inactiveCount, Colors.grey),
                ],
              ),
            ),

            // Search & Filter
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Search
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search announcements...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F4F4),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactive', 'inactive'),
                    ],
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAnnouncements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No announcements found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredAnnouncements.length,
                      itemBuilder: (context, index) {
                        final announcement = _filteredAnnouncements[index];
                        return _buildAnnouncementCard(announcement);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF13DAEC),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = value);
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF13DAEC).withOpacity(0.2),
        checkmarkColor: const Color(0xFF13DAEC),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF13DAEC) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final type = announcement['type'] ?? 'INFO';
    final typeColor = _getTypeColor(type);
    final isActive = announcement['is_active'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getTypeIcon(type), color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),

                // Title & Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              announcement['message'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Analytics
            Row(
              children: [
                _buildAnalyticItem(
                  Icons.visibility,
                  announcement['view_count'] ?? 0,
                ),
                const SizedBox(width: 16),
                _buildAnalyticItem(
                  Icons.touch_app,
                  announcement['click_count'] ?? 0,
                ),
                const SizedBox(width: 16),
                _buildAnalyticItem(
                  Icons.close,
                  announcement['dismiss_count'] ?? 0,
                ),
              ],
            ),

            const Divider(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle Active
                IconButton(
                  onPressed: () => _toggleActive(announcement['id'], isActive),
                  icon: Icon(
                    isActive ? Icons.toggle_on : Icons.toggle_off,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                  iconSize: 32,
                ),

                // Delete
                IconButton(
                  onPressed: () => _deleteAnnouncement(announcement['id']),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticItem(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

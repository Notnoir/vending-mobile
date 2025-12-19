import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const CreateAnnouncementScreen({
    Key? key,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _type = 'INFO';
  final _priorityController = TextEditingController(text: '0');
  final _iconController = TextEditingController(text: 'info');
  bool _showOnWeb = true;
  bool _showOnMobile = true;
  bool _hasActionButton = false;
  final _actionButtonTextController = TextEditingController();
  final _actionButtonUrlController = TextEditingController();
  
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _priorityController.dispose();
    _iconController.dispose();
    _actionButtonTextController.dispose();
    _actionButtonUrlController.dispose();
    super.dispose();
  }

  // Get default icon by type
  String _getDefaultIcon(String type) {
    switch (type) {
      case 'ERROR':
        return 'error';
      case 'WARNING':
        return 'warning';
      case 'MAINTENANCE':
        return 'build';
      case 'PROMOTION':
        return 'celebration';
      case 'INFO':
      default:
        return 'info';
    }
  }

  // Handle type change
  void _handleTypeChange(String newType) {
    setState(() {
      _type = newType;
      _iconController.text = _getDefaultIcon(newType);
    });
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
        return Icons.build  ;
      case 'PROMOTION':
        return Icons.celebration;
      case 'INFO':
      default:
        return Icons.info;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final token = await _getToken();
      
      final body = {
        'title': _titleController.text,
        'message': _messageController.text,
        'type': _type,
        'priority': int.tryParse(_priorityController.text) ?? 0,
        'icon': _iconController.text.isNotEmpty ? _iconController.text : null,
        'bg_color': '#FFFFFF', // Always white
        'text_color': '#0D1C1C', // Always dark
        'show_on_web': _showOnWeb,
        'show_on_mobile': _showOnMobile,
        'has_action_button': _hasActionButton,
        'action_button_text': _hasActionButton ? _actionButtonTextController.text : null,
        'action_button_url': _hasActionButton ? _actionButtonUrlController.text : null,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/announcements'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        widget.onSuccess();
        Navigator.pop(context);
        _showSuccess('Announcement created successfully');
      } else {
        throw Exception('Failed to create announcement');
      }
    } catch (e) {
      _showError('Error creating announcement: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<String> _getToken() async {
    // Get from secure storage
    return 'admin_token';
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

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(_type);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      appBar: AppBar(
        title: const Text('Create Announcement'),
        backgroundColor: const Color(0xFF13DAEC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview Card
            _buildPreviewCard(typeColor),
            
            const SizedBox(height: 24),

            // Basic Info Section
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),
            
            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Title *',
              hint: 'Enter announcement title',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),

            // Message
            _buildTextField(
              controller: _messageController,
              label: 'Message *',
              hint: 'Enter announcement message',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Message is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Type & Priority Section
            _buildSectionTitle('Type & Priority'),
            const SizedBox(height: 12),

            // Type Dropdown
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Type *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'INFO', child: Text('📘 Info')),
                DropdownMenuItem(value: 'WARNING', child: Text('⚠️ Warning')),
                DropdownMenuItem(value: 'ERROR', child: Text('🚨 Error')),
                DropdownMenuItem(value: 'MAINTENANCE', child: Text('🔧 Maintenance')),
                DropdownMenuItem(value: 'PROMOTION', child: Text('🎉 Promotion')),
              ],
              onChanged: (value) {
                if (value != null) _handleTypeChange(value);
              },
            ),

            const SizedBox(height: 16),

            // Priority
            _buildTextField(
              controller: _priorityController,
              label: 'Priority',
              hint: '0-100 (higher = more important)',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Icon
            _buildTextField(
              controller: _iconController,
              label: 'Icon',
              hint: 'Material icon name or emoji',
              helperText: 'Auto-filled based on type',
            ),

            const SizedBox(height: 24),

            // Display Options Section
            _buildSectionTitle('Display Options'),
            const SizedBox(height: 12),

            // Show on Web
            SwitchListTile(
              title: const Text('Show on Web'),
              subtitle: const Text('Display this announcement on website'),
              value: _showOnWeb,
              onChanged: (value) => setState(() => _showOnWeb = value),
              activeColor: const Color(0xFF13DAEC),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 12),

            // Show on Mobile
            SwitchListTile(
              title: const Text('Show on Mobile'),
              subtitle: const Text('Display this announcement on mobile app'),
              value: _showOnMobile,
              onChanged: (value) => setState(() => _showOnMobile = value),
              activeColor: const Color(0xFF13DAEC),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 24),

            // Action Button Section
            _buildSectionTitle('Action Button (Optional)'),
            const SizedBox(height: 12),

            // Has Action Button
            SwitchListTile(
              title: const Text('Include Action Button'),
              subtitle: const Text('Add a clickable button with URL'),
              value: _hasActionButton,
              onChanged: (value) => setState(() => _hasActionButton = value),
              activeColor: const Color(0xFF13DAEC),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            if (_hasActionButton) ...[
              const SizedBox(height: 16),
              
              // Button Text
              _buildTextField(
                controller: _actionButtonTextController,
                label: 'Button Text',
                hint: 'e.g., Learn More, Shop Now',
              ),
              
              const SizedBox(height: 16),
              
              // Button URL
              _buildTextField(
                controller: _actionButtonUrlController,
                label: 'Button URL',
                hint: 'https://example.com',
                keyboardType: TextInputType.url,
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13DAEC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Announcement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(Color typeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTypeIcon(_type),
              color: typeColor,
              size: 32,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Title
          Text(
            _titleController.text.isEmpty ? 'Announcement Title' : _titleController.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1C1C),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Message
          Text(
            _messageController.text.isEmpty ? 'Your message will appear here...' : _messageController.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Button Preview
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _hasActionButton && _actionButtonTextController.text.isNotEmpty
                    ? _actionButtonTextController.text
                    : 'Got It',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0D1C1C),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (value) {
        // Update preview on change
        if (label.contains('Title') || label.contains('Message') || label.contains('Button')) {
          setState(() {});
        }
      },
    );
  }
}

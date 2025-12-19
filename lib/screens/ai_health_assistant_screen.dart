import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/helpers.dart';

class Message {
  final String role;
  final String content;
  final DateTime timestamp;
  final List<Product>? recommendedProducts;
  
  Message({
    required this.role,
    required this.content,
    required this.timestamp,
    this.recommendedProducts,
  });
}

class AIHealthAssistantScreen extends StatefulWidget {
  const AIHealthAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIHealthAssistantScreen> createState() => _AIHealthAssistantScreenState();
}

class _AIHealthAssistantScreenState extends State<AIHealthAssistantScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(Message(
      role: 'assistant',
      content: 'Halo! Saya asisten MediVend Anda. Bagaimana saya bisa membantu Anda menemukan obat yang tepat hari ini?',
      timestamp: DateTime.now(),
    ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _textController.clear();
      _isLoading = true;
      _error = null;
    });

    _scrollToBottom();

    try {
      final conversationHistory = _messages.map((msg) => {
        'role': msg.role,
        'content': msg.content,
      }).toList();

      print('Sending to AI: $text');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/health-assistant/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'conversationHistory': conversationHistory,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      print('AI Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Get product recommendations if available
          List<Product>? products;
          if (data['products'] != null && data['products'] is List) {
            products = (data['products'] as List)
                .map((p) => Product.fromJson(p))
                .toList();
          }

          final assistantMessage = Message(
            role: 'assistant',
            content: data['message'] ?? 'Maaf, tidak ada respons.',
            timestamp: DateTime.now(),
            recommendedProducts: products,
          );

          setState(() {
            _messages.add(assistantMessage);
            _isLoading = false;
          });

          _scrollToBottom();
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _error = 'Gagal menghubungi AI. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  void _useQuickAction(String action) {
    final prompts = {
      'Gejala': 'Saya memiliki gejala seperti sakit kepala dan demam',
      'Info Produk': 'Ceritakan tentang obat pereda nyeri',
      'Dosis': 'Berapa dosis yang direkomendasikan untuk paracetamol?',
      'Pertolongan Pertama': 'Apa yang harus saya lakukan untuk luka kecil?',
    };
    _textController.text = prompts[action] ?? action;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildLoadingIndicator();
                }

                if (index == 0) {
                  return Column(
                    children: [
                      _buildTimestamp(),
                      const SizedBox(height: 24),
                      _buildMessageBubble(_messages[index]),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _buildMessageBubble(_messages[index]),
                );
              },
            ),
          ),
          _buildBottomArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5F8F8),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0D1C1C)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          const Text(
            'Dukungan MediVend',
            style: TextStyle(
              color: Color(0xFF0D1C1C),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0D1C1C)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTimestamp() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        'Hari ini, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == 'user';
    
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          _buildAvatar(false),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isUser)
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'MediVend AI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0DF2F2),
                    ),
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF0DF2F2) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 0),
                    bottomRight: Radius.circular(isUser ? 0 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isUser ? 0.15 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isUser ? null : Border.all(
                    color: const Color(0xFFF3F4F6),
                    width: 1,
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF0D1C1C),
                    fontSize: 15,
                    fontWeight: isUser ? FontWeight.bold : FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              if (isUser)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text(
                    'Dibaca ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              // Product recommendations
              if (message.recommendedProducts != null && message.recommendedProducts!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildProductRecommendations(message.recommendedProducts!),
                ),
            ],
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 12),
          _buildAvatar(true),
        ],
      ],
    );
  }

  Widget _buildProductRecommendations(List<Product> products) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk yang Direkomendasikan:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0DF2F2),
            ),
          ),
          const SizedBox(height: 8),
          ...products.take(3).map((product) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            Helpers.getImageUrl(product.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.medication, color: Color(0xFF9CA3AF));
                            },
                          ),
                        )
                      : const Icon(Icons.medication, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 12),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1C1C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Helpers.formatCurrency(product.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0DF2F2),
                        ),
                      ),
                    ],
                  ),
                ),
                // Add to cart button
                GestureDetector(
                  onTap: () {
                    cartProvider.addProduct(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} ditambahkan ke keranjang'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0DF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: Color(0xFF0D1C1C),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFE5E7EB) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isUser ? const Color(0xFFD1D5DB) : const Color(0xFFF3F4F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: isUser ? const Color(0xFF6B7280) : const Color(0xFF0DF2F2),
        size: 20,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(false),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'MediVend AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0DF2F2),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF0DF2F2)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Mengetik...',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F8),
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick action chips
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildQuickActionChip('Gejala', Icons.thermostat),
                  const SizedBox(width: 12),
                  _buildQuickActionChip('Info Produk', Icons.info_outline),
                  const SizedBox(width: 12),
                  _buildQuickActionChip('Dosis', Icons.medication_liquid_outlined),
                  const SizedBox(width: 12),
                  _buildQuickActionChip('Pertolongan Pertama', Icons.medical_services_outlined),
                ],
              ),
            ),
          ),
          // Input area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextField(
                              controller: _textController,
                              maxLines: null,
                              enabled: !_isLoading,
                              style: const TextStyle(
                                color: Color(0xFF0D1C1C),
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ketik gejala atau pertanyaan Anda...',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.fromLTRB(20, 16, 56, 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF0DF2F2), width: 2),
                                ),
                              ),
                              onSubmitted: (text) => _sendMessage(text),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.mic_none, color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0DF2F2), Color(0xFF0ACACA)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0DF2F2).withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoading ? null : () => _sendMessage(_textController.text),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ini adalah konten yang dihasilkan AI dan bukan nasihat medis profesional. Untuk keadaan darurat, segera hubungi rumah sakit terdekat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () => _useQuickAction(label),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0DF2F2)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

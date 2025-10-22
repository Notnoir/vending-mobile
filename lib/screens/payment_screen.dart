import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../providers/cart_provider.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';
import '../utils/helpers.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  Payment? _payment;
  Timer? _statusTimer;
  String? _errorMessage;
  String? _selectedPaymentMethod; // null, 'qris', or 'midtrans'

  @override
  void initState() {
    super.initState();
    // Don't create payment immediately, wait for payment method selection
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _createPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (cartProvider.items.isEmpty) {
        setState(() {
          _errorMessage = 'Keranjang kosong';
          _isLoading = false;
        });
        return;
      }

      final itemsWithoutSlot = cartProvider.items
          .where((item) => item.product.slotId == null)
          .toList();
      if (itemsWithoutSlot.isNotEmpty) {
        setState(() {
          _errorMessage =
              'Produk tidak memiliki slot yang tersedia. Silakan refresh halaman produk.';
          _isLoading = false;
        });
        return;
      }

      final items = cartProvider.items
          .map(
            (item) => {
              'slot_id': item.product.slotId!,
              'quantity': item.quantity,
              'price': item.product.price,
            },
          )
          .toList();

      final payment = await _paymentService.createPayment(
        items: items,
        totalAmount: cartProvider.totalPrice,
      );

      setState(() {
        _payment = payment;
        _isLoading = false;
      });

      _startStatusPolling();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createQrisPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (cartProvider.items.isEmpty) {
        setState(() {
          _errorMessage = 'Keranjang kosong';
          _isLoading = false;
        });
        return;
      }

      final itemsWithoutSlot = cartProvider.items
          .where((item) => item.product.slotId == null)
          .toList();
      if (itemsWithoutSlot.isNotEmpty) {
        setState(() {
          _errorMessage =
              'Produk tidak memiliki slot yang tersedia. Silakan refresh halaman produk.';
          _isLoading = false;
        });
        return;
      }

      final items = cartProvider.items
          .map(
            (item) => {
              'slot_id': item.product.slotId!,
              'quantity': item.quantity,
              'price': item.product.price,
            },
          )
          .toList();

      final payment = await _paymentService.createPayment(
        items: items,
        totalAmount: cartProvider.totalPrice,
      );

      setState(() {
        _payment = payment;
        _isLoading = false;
      });

      _startStatusPolling();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _selectedPaymentMethod = null;
      });
    }
  }

  Future<void> _createMidtransPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (cartProvider.items.isEmpty) {
        setState(() {
          _errorMessage = 'Keranjang kosong';
          _isLoading = false;
        });
        return;
      }

      final itemsWithoutSlot = cartProvider.items
          .where((item) => item.product.slotId == null)
          .toList();
      if (itemsWithoutSlot.isNotEmpty) {
        setState(() {
          _errorMessage =
              'Produk tidak memiliki slot yang tersedia. Silakan refresh halaman produk.';
          _isLoading = false;
        });
        return;
      }

      // STEP 1: Create order in backend first (for single item only for now)
      print('📦 Step 1: Creating order in backend...');
      final firstItem = cartProvider.items[0];
      final items = [
        {
          'slot_id': firstItem.product.slotId!,
          'quantity': firstItem.quantity,
          'price': firstItem.product.price,
        },
      ];

      final backendOrder = await _paymentService.createPayment(
        items: items,
        totalAmount: cartProvider.totalPrice,
      );

      print('✅ Backend order created: ${backendOrder.orderId}');

      // STEP 2: Create Midtrans transaction with the same order ID
      print('📦 Step 2: Creating Midtrans transaction...');
      final paymentRequest = PaymentRequest(
        orderId: backendOrder.orderId,
        amount: cartProvider.totalPrice,
        customerName: 'Customer',
        customerEmail: 'customer@example.com',
        items: cartProvider.items.map((item) {
          return PaymentItem(
            id: item.product.id.toString(),
            name: item.product.name,
            price: item.product.price,
            quantity: item.quantity,
          );
        }).toList(),
      );

      final response = await _paymentService.createTransaction(paymentRequest);

      setState(() {
        _isLoading = false;
      });

      // STEP 3: Open Midtrans payment URL
      if (response.redirectUrl.isNotEmpty) {
        print('🌐 Opening Midtrans URL: ${response.redirectUrl}');

        try {
          final uri = Uri.parse(response.redirectUrl);

          // Launch URL directly without checking canLaunchUrl
          // because canLaunchUrl may return false even when URL is valid
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          // STEP 4: Save payment info and start polling
          setState(() {
            _payment = backendOrder; // Use the order from backend
          });
          _startStatusPolling();
        } catch (launchError) {
          print('❌ Error launching URL: $launchError');
          throw Exception(
            'Tidak dapat membuka halaman pembayaran: $launchError',
          );
        }
      } else {
        throw Exception('No redirect URL received');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _selectedPaymentMethod = null;
      });
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_payment == null) {
        timer.cancel();
        return;
      }

      try {
        final status = await _paymentService.checkPaymentStatus(
          _payment!.orderId,
        );

        if (status == 'settlement' || status == 'capture') {
          timer.cancel();
          _handlePaymentSuccess();
        } else if (status == 'deny' ||
            status == 'cancel' ||
            status == 'expire') {
          timer.cancel();
          _handlePaymentFailed(status);
        }
      } catch (e) {
        // Continue polling on error
      }
    });
  }

  void _handlePaymentSuccess() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clear();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Pembayaran Berhasil'),
          ],
        ),
        content: const Text('Terima kasih! Pembayaran Anda telah berhasil.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialTabIndex: 2),
                ),
                (route) => false,
              );
            },
            child: const Text('Lihat Riwayat'),
          ),
        ],
      ),
    );
  }

  void _handlePaymentFailed(String status) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('Pembayaran Gagal'),
          ],
        ),
        content: Text('Status: $status\nSilakan coba lagi.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _createPayment();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF5F5), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              )
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _selectedPaymentMethod = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: AppTheme.darkBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            : _selectedPaymentMethod == null
            ? _buildPaymentMethodSelection()
            : _payment == null
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              )
            : _buildPaymentDetails(),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    final cartProvider = Provider.of<CartProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shopping_cart, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Ringkasan Pesanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppTheme.accentBlue),
                  ...cartProvider.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.product.name}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            Helpers.formatCurrency(
                              item.product.price * item.quantity,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24, color: AppTheme.accentBlue),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlue,
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(cartProvider.totalPrice),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment Method Title
          const Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 16),

          // Midtrans Payment Method Card
          _buildPaymentMethodCard(
            method: 'midtrans',
            icon: Icons.credit_card,
            title: 'Midtrans',
            subtitle: 'Bayar dengan kartu kredit/debit, e-wallet, dan lainnya',
            color: AppTheme.primaryBlue,
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'midtrans';
              });
              _createMidtransPayment();
            },
          ),
          const SizedBox(height: 12),

          // QRIS Payment Method Card
          _buildPaymentMethodCard(
            method: 'qris',
            icon: Icons.qr_code_2,
            title: 'QRIS',
            subtitle: 'Bayar dengan scan QR code',
            color: const Color(0xFF00AA13),
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'qris';
              });
              _createQrisPayment();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String method,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.white, color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    // For QRIS, show QR code
    if (_selectedPaymentMethod == 'qris' && _payment!.qrCode.isNotEmpty) {
      final cartProvider = Provider.of<CartProvider>(context);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF5F5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan QR Code untuk membayar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _payment!.qrCode,
                        version: QrVersions.auto,
                        size: 250,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.formatCurrency(_payment!.amount),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Order ID: ${_payment!.orderId}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Menunggu pembayaran...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartProvider.items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = cartProvider.items[index];
                  return ListTile(
                    title: Text(
                      item.product.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${item.quantity} x ${Helpers.formatCurrency(item.product.price)}',
                    ),
                    trailing: Text(
                      Helpers.formatCurrency(
                        item.product.price * item.quantity,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // For Midtrans, show waiting message
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF5F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.payment,
                    size: 64,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Menunggu Pembayaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Silakan selesaikan pembayaran di halaman Midtrans yang telah dibuka',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Helpers.formatCurrency(_payment!.amount),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Order ID: ${_payment!.orderId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Mengecek status pembayaran...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

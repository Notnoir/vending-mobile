import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _createPayment();
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
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryRed, AppTheme.darkRed],
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
                child: CircularProgressIndicator(color: AppTheme.primaryRed),
              )
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: AppTheme.primaryRed,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _createPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: AppTheme.darkRed,
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
            : _payment == null
            ? const Center(child: Text('Tidak ada data pembayaran'))
            : SingleChildScrollView(
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
                              color: AppTheme.primaryRed,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Scan QR Code untuk membayar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkRed,
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
                                  color: AppTheme.primaryRed,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryRed.withOpacity(0.2),
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
                                color: AppTheme.primaryYellow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Total Pembayaran',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.darkRed,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Helpers.formatCurrency(_payment!.amount),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Order ID: ${_payment!.orderId}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      color: AppTheme.primaryRed,
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
                          color: AppTheme.darkRed,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
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
                                color: AppTheme.primaryRed,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

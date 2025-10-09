import '../models/payment.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  // Create payment with items (directly to backend like web)
  Future<Payment> createPayment({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    try {
      // For now, we only support single item orders
      // Create order directly to backend using slot_id
      if (items.isEmpty) {
        throw Exception('No items in cart');
      }

      final firstItem = items[0];

      // DEBUG: Log data yang akan dikirim
      print('📦 Creating payment with data:');
      print(
        '  slot_id: ${firstItem['slot_id']} (${firstItem['slot_id'].runtimeType})',
      );
      print(
        '  quantity: ${firstItem['quantity']} (${firstItem['quantity'].runtimeType})',
      );

      final requestBody = {
        'slot_id': firstItem['slot_id'],
        'quantity': firstItem['quantity'],
      };

      print('📦 Request body: $requestBody');

      final response = await _apiService.post(
        ApiEndpoints.orders, // Use backend orders endpoint directly
        body: requestBody,
      );

      return Payment.fromJson(response);
    } catch (e) {
      print('Error creating payment: $e');
      rethrow;
    }
  }

  // Create Midtrans transaction
  Future<PaymentResponse> createTransaction(PaymentRequest request) async {
    try {
      // Call frontend API endpoint for payment creation
      final response = await _apiService.post(
        ApiEndpoints.createPayment,
        body: request.toJson(),
      );

      return PaymentResponse.fromJson(response);
    } catch (e) {
      print('Error creating transaction: $e');
      rethrow;
    }
  }

  // Check payment status - returns String status (from backend order)
  Future<String> checkPaymentStatus(String orderId) async {
    try {
      // Get order status from backend
      final response = await _apiService.get(ApiEndpoints.orderById(orderId));

      // Return status as lowercase to match mobile app expectations
      final status = response['status']?.toString().toLowerCase() ?? 'pending';
      return status;
    } catch (e) {
      print('Error checking payment status: $e');
      rethrow;
    }
  }

  // Check payment status - returns PaymentStatus object
  Future<PaymentStatus> getPaymentStatus(String orderId) async {
    try {
      // Call frontend API endpoint for payment status
      final response = await _apiService.get(
        ApiEndpoints.paymentStatus(orderId),
      );

      return PaymentStatus.fromJson(response);
    } catch (e) {
      print('Error checking payment status: $e');
      rethrow;
    }
  }

  // Poll payment status (for checking multiple times)
  Stream<PaymentStatus> pollPaymentStatus(
    String orderId, {
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 100,
  }) async* {
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        final status = await getPaymentStatus(orderId);
        yield status;

        // Stop polling if payment is settled or failed
        if (status.isSuccess || status.isFailed) {
          break;
        }

        await Future.delayed(interval);
        attempts++;
      } catch (e) {
        print('Error polling payment status: $e');
        await Future.delayed(interval);
        attempts++;
      }
    }
  }

  // Helper to generate payment request from cart
  PaymentRequest createPaymentRequest({
    required String orderId,
    required double totalAmount,
    required String customerName,
    required String customerEmail,
    required List<PaymentItem> items,
  }) {
    return PaymentRequest(
      orderId: orderId,
      amount: totalAmount,
      customerName: customerName,
      customerEmail: customerEmail,
      items: items,
    );
  }
}

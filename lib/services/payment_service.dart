import '../models/payment.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';

class PaymentService {
  final ApiService _apiService = ApiService();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.headers,
    ),
  );

  // Create payment with items (directly to backend like web)
  Future<Payment> createPayment({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    try {
      // Create order with all items
      if (items.isEmpty) {
        throw Exception('No items in cart');
      }

      // DEBUG: Log data yang akan dikirim
      print('📦 Creating payment with data:');
      print('  Total items: ${items.length}');
      print('  Total amount: $totalAmount');
      
      for (var i = 0; i < items.length; i++) {
        print('  Item ${i + 1}: slot=${items[i]['slot_id']}, qty=${items[i]['quantity']}, price=${items[i]['price']}');
      }

      final requestBody = {
        'items': items, // Send all items array
      };

      print('📦 Request body: $requestBody');

      // Use /orders/multi endpoint for multi-item orders
      final endpoint = items.length > 1 ? '/orders/multi' : '/orders';
      print('📦 Using endpoint: $endpoint');

      final response = await _apiService.post(
        endpoint,
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
      print('🔄 Creating Midtrans transaction...');
      print('📦 Request body: ${request.toJson()}');

      // Call frontend API endpoint for payment creation using Dio directly
      final response = await _dio.post(
        ApiEndpoints.createPayment,
        data: request.toJson(),
      );

      print('✅ Midtrans response: ${response.data}');
      return PaymentResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        print('❌ Dio Error: ${e.response?.statusCode} - ${e.response?.data}');
        print('❌ URL: ${e.requestOptions.uri}');
      }
      print('Error creating transaction: $e');
      rethrow;
    }
  }

  // Check payment status - returns String status (from Midtrans via frontend API)
  Future<String> checkPaymentStatus(String orderId) async {
    try {
      print('🔍 Checking payment status for order: $orderId');

      // Get payment status from Midtrans via frontend API
      final response = await _dio.get(ApiEndpoints.paymentStatus(orderId));

      print('✅ Payment status response: ${response.data}');

      // Extract transaction_status from Midtrans response
      final transactionStatus =
          response.data['transaction_status']?.toString().toLowerCase() ??
          'pending';

      print('💳 Midtrans transaction status: $transactionStatus');

      return transactionStatus;
    } catch (e) {
      if (e is DioException) {
        print(
          '❌ Error checking payment status: ${e.response?.statusCode} - ${e.response?.data}',
        );
      } else {
        print('❌ Error checking payment status: $e');
      }
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

  // Manual update payment status (for when webhook doesn't reach backend)
  Future<bool> manualUpdatePaymentStatus(
    String orderId, {
    String status = 'SUCCESS',
  }) async {
    try {
      print('🔧 Manually updating payment status for: $orderId → $status');

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/debug/update-payment/$orderId',
        data: {'status': status},
      );

      print('✅ Manual update response: ${response.data}');
      return response.data['success'] == true;
    } catch (e) {
      if (e is DioException) {
        print(
          '❌ Error manual update: ${e.response?.statusCode} - ${e.response?.data}',
        );
      } else {
        print('❌ Error manual update: $e');
      }
      return false;
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

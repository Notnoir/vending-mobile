import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'dart:convert';
import '../config/api_config.dart';

class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final String baseUrl = ApiConfig.baseUrl;

  /// Upload prescription image and get OCR results
  Future<Map<String, dynamic>> uploadPrescription(File imageFile) async {
    try {
      // First, create a session
      print('Creating prescription scan session...');
      final sessionResponse = await createSession();

      if (sessionResponse['success'] != true) {
        throw Exception('Failed to create session');
      }

      final sessionId = sessionResponse['sessionId'];
      print('Session created: $sessionId');

      // Check file before upload
      print('File path: ${imageFile.path}');
      print('File exists: ${await imageFile.exists()}');
      print('File size: ${await imageFile.length()} bytes');

      // Upload with session ID
      final uri = Uri.parse(
        '$baseUrl/prescription-scan/upload?session=$sessionId',
      );
      print('Upload URL: $uri');

      var request = http.MultipartRequest('POST', uri);

      // Determine content type from file extension
      String contentType = 'image/jpeg';
      final extension = imageFile.path.toLowerCase().split('.').last;
      print('File extension: $extension');

      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      }

      print('Content-Type: $contentType');

      request.files.add(
        await http.MultipartFile.fromPath(
          'prescription',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      print('Sending upload request...');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final uploadData = jsonDecode(response.body);

        // Wait for processing (poll status)
        print('Waiting for OCR processing...');
        await Future.delayed(const Duration(seconds: 2));

        // Get the result
        final result = await getSessionStatus(sessionId);
        return result;
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      print('Error uploading prescription: $e');
      rethrow;
    }
  }

  /// Create a scan session
  Future<Map<String, dynamic>> createSession() async {
    try {
      final uri = Uri.parse('$baseUrl/prescription-scan/create-session');
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create session');
      }
    } catch (e) {
      print('Error creating session: $e');
      rethrow;
    }
  }

  /// Check session status and get results (with polling)
  Future<Map<String, dynamic>> getSessionStatus(
    String sessionId, {
    int maxAttempts = 15,
  }) async {
    try {
      for (int i = 0; i < maxAttempts; i++) {
        final uri = Uri.parse('$baseUrl/prescription-scan/status/$sessionId');
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = data['status'];

          print('Session status: $status (attempt ${i + 1}/$maxAttempts)');

          if (status == 'completed') {
            return data;
          } else if (status == 'error') {
            throw Exception(data['error'] ?? 'Processing failed');
          } else if (status == 'processing' || status == 'waiting') {
            // Wait 2 seconds before next poll
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        } else {
          throw Exception('Failed to get session status');
        }
      }

      throw Exception('Processing timeout. Please try again.');
    } catch (e) {
      print('Error getting session status: $e');
      rethrow;
    }
  }
}

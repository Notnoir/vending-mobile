import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/outbreak_news.dart';

class WHOService {
  static const String baseUrl = 'https://www.who.int/api/news';
  
  /// Get disease outbreak news from WHO
  static Future<List<OutbreakNews>> getOutbreakNews({int limit = 20}) async {
    try {
      print('Fetching WHO outbreak news from: $baseUrl/diseaseoutbreaknews');
      
      final response = await http.get(
        Uri.parse('$baseUrl/diseaseoutbreaknews'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MediVend-Mobile-App',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - WHO API took too long to respond');
        },
      );

      print('WHO API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('WHO API Response Data Type: ${data.runtimeType}');
        
        // WHO API returns data in 'value' field (OData format)
        List newsData = [];
        
        if (data is Map && data.containsKey('value')) {
          newsData = data['value'] as List;
        } else if (data is List) {
          newsData = data;
        } else {
          print('Unexpected response format: $data');
          throw Exception('Unexpected API response format');
        }
        
        print('Found ${newsData.length} news items');
        
        if (newsData.isEmpty) {
          throw Exception('No outbreak news available from WHO');
        }
        
        final newsList = newsData
            .take(limit)
            .map((item) {
              try {
                return _parseNewsItem(item);
              } catch (e) {
                print('Error parsing news item: $e');
                print('Item data: $item');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<OutbreakNews>()
            .toList();
        
        if (newsList.isEmpty) {
          throw Exception('Failed to parse any news items');
        }
        
        return newsList;
        
      } else {
        throw Exception(
          'WHO API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching WHO outbreak news: $e');
      rethrow; // Throw error instead of returning mock data
    }
  }

  /// Parse individual news item with flexible field mapping
  static OutbreakNews _parseNewsItem(Map<String, dynamic> item) {
    // WHO API might use different field names, try multiple variations
    final id = item['id']?.toString() ?? 
               item['ID']?.toString() ?? 
               item['newsId']?.toString() ?? 
               DateTime.now().millisecondsSinceEpoch.toString();
    
    final title = item['title'] ?? 
                  item['Title'] ?? 
                  item['headline'] ?? 
                  'Untitled Outbreak News';
    
    final description = item['description'] ?? 
                       item['Description'] ?? 
                       item['summary'] ?? 
                       item['excerpt'] ?? 
                       '';
    
    final disease = item['disease'] ?? 
                   item['Disease'] ?? 
                   item['diseaseName'] ?? 
                   _extractDiseaseFromTitle(title);
    
    final country = item['country'] ?? 
                   item['Country'] ?? 
                   item['location'] ?? 
                   item['region'] ?? 
                   'Global';
    
    final publishedDate = _parseDate(
      item['publishedDate'] ?? 
      item['PublishedDate'] ?? 
      item['date'] ?? 
      item['createdDate']
    );
    
    final url = item['url'] ?? 
               item['URL'] ?? 
               item['link'] ?? 
               'https://www.who.int/emergencies/disease-outbreak-news';
    
    final imageUrl = item['imageUrl'] ?? 
                    item['ImageUrl'] ?? 
                    item['image'] ?? 
                    item['thumbnail'];
    
    return OutbreakNews(
      id: id,
      title: title,
      description: description,
      disease: disease,
      country: country,
      publishedDate: publishedDate,
      url: url,
      imageUrl: imageUrl,
    );
  }

  /// Parse date from various formats
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
    }
    
    return DateTime.now();
  }

  /// Extract disease name from title if not provided
  static String _extractDiseaseFromTitle(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('dengue')) return 'Dengue Fever';
    if (lowerTitle.contains('covid') || lowerTitle.contains('coronavirus')) {
      return 'COVID-19';
    }
    if (lowerTitle.contains('influenza') || lowerTitle.contains('flu')) {
      return 'Influenza';
    }
    if (lowerTitle.contains('measles')) return 'Measles';
    if (lowerTitle.contains('cholera')) return 'Cholera';
    if (lowerTitle.contains('ebola')) return 'Ebola';
    if (lowerTitle.contains('malaria')) return 'Malaria';
    if (lowerTitle.contains('tuberculosis') || lowerTitle.contains('tb')) {
      return 'Tuberculosis';
    }
    
    return 'Disease Outbreak';
  }
}


class OutbreakNews {
  final String id;
  final String title;
  final String description;
  final String disease;
  final String country;
  final DateTime publishedDate;
  final String url;
  final String? imageUrl;

  OutbreakNews({
    required this.id,
    required this.title,
    required this.description,
    required this.disease,
    required this.country,
    required this.publishedDate,
    required this.url,
    this.imageUrl,
  });

  factory OutbreakNews.fromJson(Map<String, dynamic> json) {
    return OutbreakNews(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      disease: json['disease'] ?? 'Unknown',
      country: json['country'] ?? 'Global',
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'])
          : DateTime.now(),
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/outbreak_news.dart';
import '../services/who_service.dart';
import 'news_webview_screen.dart';

class HealthNewsScreen extends StatefulWidget {
  const HealthNewsScreen({Key? key}) : super(key: key);

  @override
  State<HealthNewsScreen> createState() => _HealthNewsScreenState();
}

class _HealthNewsScreenState extends State<HealthNewsScreen> {
  List<OutbreakNews> _allNews = [];
  List<OutbreakNews> _displayedNews = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _selectedCategory = 'Latest';
  
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all news from API
      final news = await WHOService.getOutbreakNews(limit: 100);
      setState(() {
        _allNews = news;
        _currentPage = 0;
        _displayedNews = _getPageItems();
        _hasMoreData = _displayedNews.length < _allNews.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<OutbreakNews> _getPageItems() {
    final startIndex = 0;
    final endIndex = (_currentPage + 1) * _itemsPerPage;
    return _allNews.take(endIndex.clamp(0, _allNews.length)).toList();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentPage++;
      _displayedNews = _getPageItems();
      _hasMoreData = _displayedNews.length < _allNews.length;
      _isLoadingMore = false;
    });
  }

  Color _getDiseaseColor(String disease) {
    final lowerDisease = disease.toLowerCase();
    if (lowerDisease.contains('dengue')) return const Color(0xFFF59E0B);
    if (lowerDisease.contains('covid') || lowerDisease.contains('influenza')) {
      return const Color(0xFFEF4444);
    }
    if (lowerDisease.contains('measles')) return const Color(0xFFF97316);
    if (lowerDisease.contains('cholera')) return const Color(0xFF06B6D4);
    return const Color(0xFF8B5CF6);
  }

  IconData _getDiseaseIcon(String disease) {
    final lowerDisease = disease.toLowerCase();
    if (lowerDisease.contains('dengue')) return Icons.bug_report;
    if (lowerDisease.contains('covid') || lowerDisease.contains('influenza')) {
      return Icons.coronavirus;
    }
    if (lowerDisease.contains('measles')) return Icons.healing;
    if (lowerDisease.contains('cholera')) return Icons.water_drop;
    return Icons.medical_services;
  }

  void _openUrl(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsWebViewScreen(
          url: url,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      body: CustomScrollView(
        slivers: [
          // Modern Header
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFFF5F8F8),
            foregroundColor: const Color(0xFF0D1C1C),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            title: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'MediVend ',
                    style: TextStyle(color: Color(0xFF0D1C1C)),
                  ),
                  TextSpan(
                    text: 'Daily',
                    style: TextStyle(color: Color(0xFF0ACACA)),
                  ),
                ],
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 24),
                onPressed: _loadNews,
              ),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.transparent,
                    width: 2,
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search health topics...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF499C9C).withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF499C9C),
                      size: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF0D1C1C),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Category Chips
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('Latest'),
                  const SizedBox(width: 12),
                  _buildCategoryChip('Outbreak'),
                  const SizedBox(width: 12),
                  _buildCategoryChip('Prevention'),
                  const SizedBox(width: 12),
                  _buildCategoryChip('Vaccines'),
                  const SizedBox(width: 12),
                  _buildCategoryChip('Global'),
                ],
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: const Text(
                'WHO Health Updates',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1C1C),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),


          // News List
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _errorMessage != null
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load news',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadNews,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF13DAEC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _displayedNews.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.article_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No news available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // Load More button at the end
                                if (index == _displayedNews.length) {
                                  return _buildLoadMoreButton();
                                }

                                final newsItem = _displayedNews[index];
                                return _buildNewsCard(newsItem);
                              },
                              childCount: _displayedNews.length + 1,
                            ),
                          ),
                        ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0df2f2)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFFF0F0F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0df2f2).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF0D1C1C)
                  : const Color(0xFF499C9C),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(OutbreakNews news) {
    final diseaseColor = _getDiseaseColor(news.disease);
    final diseaseIcon = _getDiseaseIcon(news.disease);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showNewsDetail(news),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with disease badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: diseaseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      diseaseIcon,
                      color: diseaseColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: diseaseColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            news.disease,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: diseaseColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                news.country,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                news.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C1C),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                news.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(news.publishedDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _openUrl(news.url, news.title),
                    child: const Row(
                      children: [
                        Text('Read more'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewsDetail(OutbreakNews news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Disease badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDiseaseColor(news.disease).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDiseaseIcon(news.disease),
                        size: 20,
                        color: _getDiseaseColor(news.disease),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        news.disease,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getDiseaseColor(news.disease),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1C1C),
                  ),
                ),

                const SizedBox(height: 12),

                // Meta info
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      news.country,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(news.publishedDate),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  news.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // Source info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Source: World Health Organization (WHO)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _openUrl(news.url, news.title),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Read Full Article on WHO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13DAEC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (!_hasMoreData) {
      // End of data message
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'All news loaded',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Showing ${_displayedNews.length} of ${_allNews.length} articles',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Showing ${_displayedNews.length} of ${_allNews.length} articles',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // Load More button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoadingMore ? null : _loadMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF13DAEC),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoadingMore
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Loading...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.expand_more, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Load More',
                          style: TextStyle(
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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/news_service.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  late Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchAllNews();
  }

  Future<void> _refreshNews() async {
    setState(() {
      _newsFuture = _newsService.fetchAllNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('شكو ماكو v4'),
        actions: [
          IconButton(
            icon: Icon(isIOS ? CupertinoIcons.refresh : Icons.refresh),
            onPressed: _refreshNews,
          ),
        ],
      ),
      body: FutureBuilder<List<NewsArticle>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ ما: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد أخبار حالياً'));
          }

          final articles = snapshot.data!;
          return RefreshIndicator.adaptive(
            onRefresh: _refreshNews,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return _buildNewsCard(context, articles[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsArticle article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (kIsWeb) {
            launchUrl(
              Uri.parse(article.link),
              mode: LaunchMode.externalApplication,
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(article: article),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              CachedNetworkImage(
                imageUrl: kIsWeb
                    ? 'https://corsproxy.io/?' +
                          Uri.encodeComponent(article.imageUrl!)
                    : article.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white, height: 200),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.source,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (article.pubDate != null)
                        Text(
                          DateFormat(
                            'yyyy-MM-dd – kk:mm',
                          ).format(article.pubDate!),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.description != null &&
                      article.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(height: 200, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(height: 20, width: 200, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(
                        height: 15,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

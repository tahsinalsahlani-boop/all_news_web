import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import '../models/news_article.dart';
import 'package:html/parser.dart' show parse;

class NewsService {
  final Map<String, String> _sources = {
    'الجزيرة': 'https://www.aljazeera.net/aljazeerarss.xml',
    'سكاي نيوز': 'https://www.skynewsarabia.com/rss.xml',
    'سي إن إن': 'https://arabic.cnn.com/api/v1/rss/world/rss.xml',
    'بي بي سي': 'https://www.bbc.com/arabic/index.xml',
    'السومرية': 'https://www.alsumaria.tv/Rss/iraq-latest-news/ar.xml',
    'روسيا اليوم': 'https://arabic.rt.com/rss',
    'فرانس 24': 'https://www.france24.com/ar/rss',
    'العهد': 'https://www.al-عهد.net/rss',
    'المسيرة': 'https://www.almasirah.net/rss',
    'المنار': 'https://www.almanar.com.lb/rss',
    'القدس العربي': 'https://www.alquds.co.uk/feed/',
    'العراقية': 'https://www.iraqia.tv/rss/all',
  };

  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/xml, text/xml, */*',
  };

  Future<List<NewsArticle>> fetchAllNews() async {
    final List<Future<List<NewsArticle>>> futures = _sources.entries.map((
      entry,
    ) {
      return _fetchFromSource(entry.value, entry.key)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Timeout fetching from ${entry.key}');
              return [];
            },
          )
          .catchError((e) {
            debugPrint('Error fetching from ${entry.key}: $e');
            return <NewsArticle>[];
          });
    }).toList();

    final results = await Future.wait(futures);
    List<NewsArticle> allArticles = results.expand((x) => x).toList();

    allArticles.sort((a, b) {
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });
    return allArticles;
  }

  Future<List<NewsArticle>> _fetchFromSource(
    String url,
    String sourceName,
  ) async {
    Uri finalUri = Uri.parse(url);

    // Add CORS proxy for web to bypass browser restrictions
    if (kIsWeb) {
      finalUri = Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}');
    }

    final response = await http.get(
      finalUri,
      headers: kIsWeb ? null : _headers,
    );
    if (response.statusCode == 200) {
      var channel = RssFeed.parse(response.body);
      return channel.items?.map((item) {
            String? imageUrl;

            if (item.media?.contents?.isNotEmpty ?? false) {
              imageUrl = item.media!.contents!.first.url;
            }

            if (imageUrl == null || imageUrl.isEmpty) {
              imageUrl = item.enclosure?.url;
            }

            if (imageUrl == null || imageUrl.isEmpty) {
              if (item.media?.thumbnails?.isNotEmpty ?? false) {
                imageUrl = item.media!.thumbnails!.first.url;
              }
            }

            if (imageUrl == null || imageUrl.isEmpty) {
              imageUrl = _extractImageFromHtml(item.description);
            }

            imageUrl = _processImageUrl(imageUrl, sourceName);

            // FULL CONTENT STRATEGY: Combine summary with available fields
            String contentText =
                _cleanHtml(item.content?.value) ??
                _cleanHtml(item.description) ??
                "";

            return NewsArticle(
              title: item.title ?? 'No Title',
              description: contentText,
              link: _fixArticleLink(item.link),
              imageUrl: imageUrl,
              pubDate: item.pubDate,
              source: sourceName,
              rawHtml: item.content?.value ?? item.description,
            );
          }).toList() ??
          [];
    } else {
      throw Exception('Failed to load news from $url');
    }
  }

  String? _processImageUrl(String? url, String source) {
    if (url == null || url.isEmpty) return null;
    String fixedUrl = url.startsWith('//') ? 'https:$url' : url;
    if (source == 'الجزيرة') {
      fixedUrl = fixedUrl.replaceAll(RegExp(r'w=\d+'), 'w=800');
    }
    return fixedUrl;
  }

  String _fixArticleLink(String? link) {
    if (link == null) return '';
    String fixed = link.trim();
    if (!fixed.startsWith('http')) {
      // Handle relative links if they appear
    }
    return fixed.replaceAll(' ', '%20');
  }

  String? _extractImageFromHtml(String? html) {
    if (html == null || html.isEmpty) return null;
    try {
      var doc = parse(html);
      var img = doc.querySelector('img');
      return img?.attributes['src'];
    } catch (e) {
      return null;
    }
  }

  String? _cleanHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) return null;
    var document = parse(htmlString);
    String parsedString = document.body?.text ?? '';
    return parsedString.trim();
  }
}

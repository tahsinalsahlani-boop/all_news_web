import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';

class DetailsScreen extends StatefulWidget {
  final NewsArticle article;

  const DetailsScreen({super.key, required this.article});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; SM-G960U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (error) {
              // Major connection issues
              if (error.errorType == WebResourceErrorType.hostLookup ||
                  error.errorType == WebResourceErrorType.connect ||
                  error.errorType == WebResourceErrorType.timeout) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                  });
                }
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.article.link));
    }
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(widget.article.link);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.source),
        actions: [
          IconButton(
            icon: Icon(
              isIOS
                  ? CupertinoIcons.arrow_up_right_square
                  : Icons.open_in_browser,
            ),
            onPressed: _launchUrl,
          ),
        ],
      ),
      body: _hasError
          ? _buildFullBackupUI()
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_isLoading)
                  Center(child: CircularProgressIndicator.adaptive()),
              ],
            ),
    );
  }

  Widget _buildFullBackupUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.article.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.article.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            widget.article.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (widget.article.pubDate != null)
            Text(
              DateFormat('yyyy/MM/dd HH:mm').format(widget.article.pubDate!),
              style: const TextStyle(color: Colors.grey),
            ),
          const Divider(height: 30),
          const Text(
            "تنبيه: تعذر الاتصال بموقع الصحيفة الأصلي. إليك ملخص الخبر:",
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            widget.article.description ?? "لا يوجد وصف متاح لهذا الخبر.",
            style: const TextStyle(fontSize: 18, height: 1.6),
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: _launchUrl,
              icon: const Icon(Icons.launch),
              label: const Text("اقرأ الخبر كاملاً في المتصفح الخارجي"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _controller?.reload();
              },
              child: const Text("إعادة محاولة التحميل"),
            ),
          ),
        ],
      ),
    );
  }
}

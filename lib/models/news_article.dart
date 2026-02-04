class NewsArticle {
  final String title;
  final String? description;
  final String? content;
  final String link;
  final String? imageUrl;
  final DateTime? pubDate;
  final String source;
  final String? rawHtml;

  NewsArticle({
    required this.title,
    this.description,
    this.content,
    required this.link,
    this.imageUrl,
    this.pubDate,
    required this.source,
    this.rawHtml,
  });
}

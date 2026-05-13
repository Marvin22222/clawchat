class LinkPreview {
  final String url;
  final String? title;
  final String? description;
  final String? image;
  final String? favicon;
  final String? siteName;

  LinkPreview({
    required this.url,
    this.title,
    this.description,
    this.image,
    this.favicon,
    this.siteName,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> json, String url) {
    return LinkPreview(
      url: url,
      title: json['og:title'] as String? ??
             json['title'] as String? ??
             json['twitter:title'] as String?,
      description: json['og:description'] as String? ??
                  json['description'] as String? ??
                  json['twitter:description'] as String?,
      image: json['og:image'] as String? ??
             json['twitter:image'] as String? ??
             json['image'] as String?,
      favicon: json['favicon'] as String?,
      siteName: json['og:site_name'] as String? ?? json['site_name'] as String?,
    );
  }

  bool get hasContent => title != null || description != null;
}
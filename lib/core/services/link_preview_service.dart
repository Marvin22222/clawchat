import 'package:http/http.dart' as http;
import '../../models/link_preview.dart';

/// Service for detecting URLs in text and fetching link previews
class LinkPreviewService {
  static final LinkPreviewService _instance = LinkPreviewService._internal();
  factory LinkPreviewService() => _instance;
  LinkPreviewService._internal();

  // Cache for link previews to avoid repeated fetches
  final Map<String, LinkPreview> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // URL regex pattern - matches most common URL formats
  static final RegExp _urlRegex = RegExp(
    r'(?:https?://)?(?:www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_+.~#?&/=]*)',
    caseSensitive: false,
  );

  /// Check if text contains any URLs
  static bool containsUrl(String text) {
    return _urlRegex.hasMatch(text);
  }

  /// Extract all URLs from text
  static List<String> extractUrls(String text) {
    final matches = _urlRegex.allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Normalize URL (add https:// if missing)
  static String normalizeUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  /// Fetch preview metadata for a URL
  Future<LinkPreview?> fetchPreview(String url) async {
    final normalizedUrl = normalizeUrl(url);

    // Check cache first
    if (_cache.containsKey(normalizedUrl)) {
      return _cache[normalizedUrl];
    }

    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse(normalizedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; ClawChat/1.0)',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 10));

      client.close();

      if (response.statusCode == 200) {
        final preview = _parseHtmlPreview(response.body, normalizedUrl);
        if (preview != null) {
          _cache[normalizedUrl] = preview;
        }
        return preview;
      }
    } catch (e) {
      // Silently fail - URLs without previews will just be clickable text
    }

    return null;
  }

  /// Parse HTML response for OpenGraph/meta tags
  LinkPreview? _parseHtmlPreview(String html, String url) {
    String? title;
    String? description;
    String? image;
    String? favicon;
    String? siteName;

    // Extract <title> tag
    final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
        .firstMatch(html);
    if (titleMatch != null) {
      title = _decodeHtmlEntities(titleMatch.group(1)?.trim() ?? '');
    }

    // Extract meta tags (og:*, twitter:*, description, etc.)
    final metaRegex = RegExp(
      r'<meta[^>]+(content|name|property)=["\']([^"\']+)["\'][^>]*(?:name|property|content)=["\']([^"\']+)["\']',
      caseSensitive: false,
    );

    for (final match in metaRegex.allMatches(html)) {
      final attr1 = match.group(1)?.toLowerCase() ?? '';
      final value1 = match.group(2) ?? '';
      final attr2 = match.group(3)?.toLowerCase() ?? '';

      if (attr1 == 'property' || attr1 == 'name') {
        final metaName = value1.toLowerCase();
        final metaContent = attr2;

        if (metaName == 'og:title') title ??= metaContent;
        if (metaName == 'og:description') description ??= metaContent;
        if (metaName == 'og:image') image ??= metaContent;
        if (metaName == 'og:site_name') siteName ??= metaContent;
        if (metaName == 'twitter:title') title ??= metaContent;
        if (metaName == 'twitter:description') description ??= metaContent;
        if (metaName == 'twitter:image') image ??= metaContent;
      } else if (attr1 == 'content') {
        final metaName = value1.toLowerCase();
        if (metaName == 'description') description ??= attr2;
      }
    }

    // Extract favicon
    final faviconMatch = RegExp(
      r'<link[^>]+rel=["\'](?:shortcut )?icon["\'][^>]+href=["\']([^"\']+)["\']',
      caseSensitive: false,
    ).firstMatch(html);
    if (faviconMatch != null) {
      favicon = _resolveUrl(faviconMatch.group(1) ?? '', url);
    }

    // Fallback favicon
    favicon ??= '${Uri.parse(url).origin}/favicon.ico';

    return LinkPreview(
      url: url,
      title: title,
      description: description,
      image: image != null ? _resolveUrl(image, url) : null,
      favicon: favicon,
      siteName: siteName,
    );
  }

  /// Resolve relative URLs to absolute
  String _resolveUrl(String relativeUrl, String baseUrl) {
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }
    if (relativeUrl.startsWith('//')) {
      return 'https:$relativeUrl';
    }
    final baseUri = Uri.parse(baseUrl);
    if (relativeUrl.startsWith('/')) {
      return '${baseUri.origin}$relativeUrl';
    }
    return '$baseUrl/$relativeUrl';
  }

  /// Decode common HTML entities
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}
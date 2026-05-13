import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme.dart';

/// Widget that renders markdown-formatted text with syntax highlighting for code blocks
class MarkdownRenderer extends StatelessWidget {
  final String content;
  final bool isDark;
  final Color? textColor;
  final Color? linkColor;

  const MarkdownRenderer({
    super.key,
    required this.content,
    required this.isDark,
    this.textColor,
    this.linkColor,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _parseMarkdown(content);
    return SelectableText.rich(
      TextSpan(
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseMarkdown(String text) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    bool inCodeBlock = false;
    String codeBlockContent = '';
    String codeBlockLang = '';
    StringBuffer codeBlockBuffer = StringBuffer();
    List<InlineSpan> inlineSpans = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check for code block delimiters
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          // End of code block - render it
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: _buildCodeBlock(codeBlockContent.trim(), codeBlockLang),
          ));
          spans.add(const TextSpan(text: '\n'));
          codeBlockContent = '';
          codeBlockLang = '';
          codeBlockBuffer = StringBuffer();
          inCodeBlock = false;
        } else {
          // Start of code block - first flush any pending inline content
          if (inlineSpans.isNotEmpty) {
            spans.addAll(inlineSpans);
            inlineSpans = [];
          }
          inCodeBlock = true;
          // Extract language from first line
          codeBlockLang = line.trim().substring(3).trim();
          if (codeBlockLang.isEmpty) {
            codeBlockLang = _detectLanguage(codeBlockBuffer.toString());
          }
        }
        continue;
      }

      if (inCodeBlock) {
        if (codeBlockBuffer.isNotEmpty) codeBlockBuffer.write('\n');
        codeBlockBuffer.write(line);
        continue;
      }

      // Parse block-level elements
      if (line.trim().isEmpty) {
        if (inlineSpans.isNotEmpty) {
          spans.addAll(inlineSpans);
          spans.add(const TextSpan(text: '\n'));
          inlineSpans = [];
        }
        continue;
      }

      // Headers
      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: line.substring(4),
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            height: 1.4,
          ),
        ));
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: line.substring(3),
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            height: 1.4,
          ),
        ));
        spans.add(const TextSpan(text: '\n'));
        continue;
      }
      if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: line.substring(2),
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            height: 1.4,
          ),
        ));
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Blockquotes
      if (line.trim().startsWith('> ')) {
        final quoteText = line.trim().substring(2);
        spans.add(TextSpan(
          text: '> $quoteText',
          style: AppTypography.body.copyWith(
            fontStyle: FontStyle.italic,
            color: (textColor ?? AppColors.textLight).withOpacity(0.7),
            height: 1.4,
          ),
        ));
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Lists (basic - lines starting with - or * or numbers)
      final listMatch = RegExp(r'^(\s*)([-*]|\d+\.)\s+(.*)$').firstMatch(line);
      if (listMatch != null) {
        final indent = listMatch.group(1) ?? '';
        final marker = listMatch.group(2) ?? '';
        final itemText = listMatch.group(3) ?? '';
        spans.add(TextSpan(
          text: '$indent$marker $itemText',
          style: AppTypography.body.copyWith(height: 1.4),
        ));
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Regular line - parse inline markdown
      inlineSpans.addAll(_parseInlineMarkdown(line));
      inlineSpans.add(const TextSpan(text: '\n'));
    }

    // Flush any remaining content
    if (inCodeBlock && codeBlockBuffer.isNotEmpty) {
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.top,
        child: _buildCodeBlock(codeBlockBuffer.toString().trim(), codeBlockLang),
      ));
    } else if (inlineSpans.isNotEmpty) {
      spans.addAll(inlineSpans);
    }

    return spans;
  }

  List<InlineSpan> _parseInlineMarkdown(String text) {
    final spans = <InlineSpan>[];
    final defaultTextColor = textColor ?? AppColors.textLight;
    final defaultLinkColor = linkColor ?? AppColors.primary;

    // Regex patterns for inline markdown
    final codeRegex = RegExp(r'`([^`]+)`');
    final boldRegex = RegExp(r'\*\*([^*]+)\*\*');
    final italicRegex = RegExp(r'\*([^*]+)\*');
    final linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

    // Combine all patterns with their positions
    final allMatches = <_Match>[];

    for (final match in codeRegex.allMatches(text)) {
      allMatches.add(_Match(match.start, match.end, 'code', match));
    }
    for (final match in boldRegex.allMatches(text)) {
      allMatches.add(_Match(match.start, match.end, 'bold', match));
    }
    for (final match in italicRegex.allMatches(text)) {
      allMatches.add(_Match(match.start, match.end, 'italic', match));
    }
    for (final match in linkRegex.allMatches(text)) {
      allMatches.add(_Match(match.start, match.end, 'link', match));
    }

    // Sort by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Filter out overlapping matches
    final filtered = <_Match>[];
    int lastEnd = 0;
    for (final m in allMatches) {
      if (m.start >= lastEnd) {
        filtered.add(m);
        lastEnd = m.end;
      }
    }

    // Build spans
    int pos = 0;
    for (final m in filtered) {
      if (m.start > pos) {
        spans.add(TextSpan(
          text: text.substring(pos, m.start),
          style: AppTypography.body.copyWith(color: defaultTextColor, height: 1.4),
        ));
      }

      switch (m.type) {
        case 'code':
          spans.add(TextSpan(
            text: m.match.group(1),
            style: AppTypography.body.copyWith(
              fontFamily: 'monospace',
              fontSize: 13,
              backgroundColor: defaultTextColor.withOpacity(0.1),
              height: 1.4,
            ),
          ));
          break;
        case 'bold':
          spans.add(TextSpan(
            text: m.match.group(1),
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ));
          break;
        case 'italic':
          spans.add(TextSpan(
            text: m.match.group(1),
            style: AppTypography.body.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ));
          break;
        case 'link':
          final linkText = m.match.group(1) ?? '';
          final linkUrl = m.match.group(2) ?? '';
          spans.add(TextSpan(
            text: linkText,
            style: AppTypography.body.copyWith(
              color: defaultLinkColor,
              decoration: TextDecoration.underline,
              height: 1.4,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl(linkUrl),
          ));
          break;
      }

      pos = m.end;
    }

    // Remaining text
    if (pos < text.length) {
      spans.add(TextSpan(
        text: text.substring(pos),
        style: AppTypography.body.copyWith(color: defaultTextColor, height: 1.4),
      ));
    }

    return spans;
  }

  Widget _buildCodeBlock(String code, String language) {
    // Apply JSON formatting if applicable
    String displayContent = code;
    if (language == 'json') {
      try {
        final parsed = json.decode(code);
        displayContent = const JsonEncoder.withIndent('  ').convert(parsed);
      } catch (_) {
        // Keep original if parsing fails
      }
    }

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(NavigatorState().key.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('Code copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language badge
            if (language.isNotEmpty && language != 'plaintext')
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  top: AppSpacing.xs,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            // Code content
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: HighlightView(
                displayContent,
                language: language.isEmpty ? 'plaintext' : language,
                theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _detectLanguage(String code) {
    if (code.contains('function') || code.contains('const ') || code.contains('let ')) {
      return 'javascript';
    } else if (code.contains('def ') || code.contains('import ') && code.contains(':')) {
      return 'python';
    } else if (code.contains('class ') && code.contains('extends')) {
      return 'dart';
    } else if (code.contains('{') && code.contains(':') && code.contains(',')) {
      return 'json';
    }
    return 'plaintext';
  }

  Future<void> _openUrl(String url) async {
    final normalizedUrl = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(normalizedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _Match {
  final int start;
  final int end;
  final String type;
  final RegExpMatch match;

  _Match(this.start, this.end, this.type, this.match);
}
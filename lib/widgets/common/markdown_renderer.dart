import 'package:flutter/material.dart';

class MarkdownRenderer extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const MarkdownRenderer({
    super.key,
    required this.text,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 14,
    );

    final style = baseStyle ?? defaultStyle;

    // Simple markdown parsing
    final spans = _parseMarkdown(text, style);

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<TextSpan> _parseMarkdown(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.startsWith('```')) {
        // Code block - skip for now
        continue;
      } else if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: '${line.substring(2)}\n',
          style: baseStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
        ));
      } else if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: '${line.substring(3)}\n',
          style: baseStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ));
      } else if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: '${line.substring(4)}\n',
          style: baseStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        spans.add(TextSpan(
          text: '• ${line.substring(2)}\n',
          style: baseStyle,
        ));
      } else if (line.startsWith('1. ') || line.startsWith('2. ') || line.startsWith('3. ')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: baseStyle,
        ));
      } else {
        // Parse inline formatting
        spans.addAll(_parseInlineFormatting(line, baseStyle));
        if (i < lines.length - 1) {
          spans.add(const TextSpan(text: '\n'));
        }
      }
    }

    return spans;
  }

  List<TextSpan> _parseInlineFormatting(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|\[([^\]]+)\]\(([^)]+)\)');
    
    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Bold **text**
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      }
      // Italic *text*
      else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      // Code `text`
      else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
        ));
      }
      // Link [text](url)
      else if (match.group(4) != null && match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return spans;
  }
}

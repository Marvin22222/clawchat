import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../models/message.dart';

/// Service for exporting chat messages in various formats
class ChatExportService {
  /// Export messages as JSON
  static String exportAsJson(List<ChatMessage> messages) {
    final jsonList = messages.map((m) => _messageToJson(m)).toList();
    return _formatJson(jsonList);
  }

  /// Export messages as plain text
  static String exportAsText(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('═' * 50);
    buffer.writeln('  ClawChat Export');
    buffer.writeln('  Exportiert: ${_formatDate(DateTime.now())}');
    buffer.writeln('  Nachrichten: ${messages.length}');
    buffer.writeln('═' * 50);
    buffer.writeln();

    for (final msg in messages) {
      final typeLabel = msg.type == MessageType.user ? 'Du' : 'Assistant';
      final agentInfo = msg.agentName != null ? ' [${msg.agentName}]' : '';
      buffer.writeln('${'─' * 50}');
      buffer.writeln('[$typeLabel$agentInfo • ${_formatDateTime(msg.timestamp)}]');
      buffer.writeln();
      buffer.writeln(msg.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Export messages as PDF
  static Future<Uint8List> exportAsPdf(List<ChatMessage> messages) async {
    final pdf = pw.Document();

    // Group messages by date
    final groupedMessages = _groupMessagesByDate(messages);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(context),
        footer: (context) => _buildPdfFooter(context),
        build: (context) {
          final widgets = <pw.Widget>[];

          for (final entry in groupedMessages.entries) {
            // Date header
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            );

            // Messages for this date
            for (final msg in entry.value) {
              widgets.add(_buildPdfMessage(msg));
            }
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfHeader(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ClawChat Export',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            'Seite ${context.pageNumber}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            'Exportiert mit ClawChat • ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfMessage(ChatMessage msg) {
    final isUser = msg.type == MessageType.user;
    final alignment = isUser ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
    final bgColor = isUser ? PdfColors.blue50 : PdfColors.grey100;
    final borderColor = isUser ? PdfColors.blue200 : PdfColors.grey300;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      alignment: alignment,
      child: pw.Container(
        constraints: const pw.BoxConstraints(maxWidth: 500),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: borderColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: isUser ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
          children: [
            // Meta info
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: isUser ? PdfColors.blue : PdfColors.purple,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    isUser ? 'Du' : (msg.agentName ?? 'Assistant'),
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  _formatTime(msg.timestamp),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            // Content
            pw.Text(
              msg.content,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey800,
                lineSpacing: 1.5,
              ),
            ),
            // Attachments indicator
            if (msg.attachments != null && msg.attachments!.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Icon(pw.IconData(0xe15b), size: 12, color: PdfColors.grey600),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    '${msg.attachments!.length} Anhang/Anhänge',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Share export as file
  static Future<void> shareExport(String content, String filename) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ClawChat Export',
        text: 'ClawChat Chat-Export',
      );
    } catch (e) {
      // Fallback to clipboard
      debugPrint('Share failed, using clipboard fallback: $e');
      rethrow;
    }
  }

  /// Share PDF export
  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ClawChat Export',
        text: 'ClawChat Chat-Export als PDF',
      );
    } catch (e) {
      debugPrint('PDF share failed: $e');
      rethrow;
    }
  }

  static Map<String, List<ChatMessage>> _groupMessagesByDate(List<ChatMessage> messages) {
    final grouped = <String, List<ChatMessage>>{};
    
    for (final msg in messages) {
      final dateKey = _formatDate(msg.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(msg);
    }
    
    return grouped;
  }

  static String _formatJson(List<dynamic> jsonList) {
    // Simple JSON formatter with indentation
    final buffer = StringBuffer();
    buffer.writeln('{');
    buffer.writeln('  "exportDate": "${DateTime.now().toIso8601String()}",');
    buffer.writeln('  "messageCount": ${jsonList.length},');
    buffer.writeln('  "messages": [');
    
    for (int i = 0; i < jsonList.length; i++) {
      final msg = jsonList[i] as Map<String, dynamic>;
      buffer.write('    {');
      buffer.write('"id": "${msg['id']}", ');
      buffer.write('"type": "${msg['type']}", ');
      buffer.write('"content": ${_escapeString(msg['content'])}, ');
      buffer.write('"timestamp": "${msg['timestamp']}"');
      if (msg['agentName'] != null) {
        buffer.write(', "agentName": "${msg['agentName']}"');
      }
      buffer.write('}');
      if (i < jsonList.length - 1) buffer.write(',');
      buffer.writeln();
    }
    
    buffer.writeln('  ]');
    buffer.writeln('}');
    return buffer.toString();
  }

  static String _escapeString(String str) {
    return '"${str.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  }

  static String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    final now = DateTime.now();
    
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Heute';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) {
      return 'Gestern';
    } else {
      return '${dt.day}. ${months[dt.month - 1]} ${dt.year}';
    }
  }

  static String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt)} $hour:$minute';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'id': message.id,
      'content': message.content,
      'type': message.type.name,
      'timestamp': message.timestamp.toIso8601String(),
      'agentName': message.agentName,
      'attachments': message.attachments?.map((a) => {
        'fileName': a.fileName,
        'mimeType': a.mimeType,
      }).toList(),
    };
  }
}
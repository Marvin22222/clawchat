import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/message.dart';
import 'chat_persistence_service.dart';

/// Service for backing up and restoring chat data
class BackupService {
  /// Export all messages as JSON (for full backup)
  static Future<String> exportAllAsJson() async {
    final messages = await ChatPersistenceService.loadMessages();
    final export = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'messageCount': messages.length,
      'messages': messages.map((m) => _messageToJson(m)).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Export a single chat conversation as JSON
  static Future<String> exportChatAsJson(List<ChatMessage> messages, {String? chatName}) async {
    final export = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'chatName': chatName ?? 'default',
      'messageCount': messages.length,
      'messages': messages.map((m) => _messageToJson(m)).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Export chat as plain text (human-readable)
  static Future<String> exportChatAsText(List<ChatMessage> messages, {String? chatName}) async {
    return ChatPersistenceService.exportAsText(messages);
  }

  /// Export chat as PDF
  static Future<Uint8List> exportChatAsPdf(List<ChatMessage> messages, {String? chatName}) async {
    final pdf = pw.Document();
    final groupedMessages = _groupMessagesByDate(messages);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(context, chatName),
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

  /// Share export as file
  static Future<void> shareExport(String content, String filename) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ClawChat Backup',
        text: 'ClawChat Backup Export',
      );
    } catch (e) {
      debugPrint('Share failed: $e');
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
        subject: 'ClawChat Backup',
        text: 'ClawChat Backup als PDF',
      );
    } catch (e) {
      debugPrint('PDF share failed: $e');
      rethrow;
    }
  }

  /// Restore messages from JSON backup
  static Future<bool> restoreFromJson(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final messagesJson = data['messages'] as List;
      final messages = messagesJson.map((m) => _messageFromJson(m)).toList();
      await ChatPersistenceService.saveMessages(messages);
      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  // ===== Private helpers =====

  static Map<String, List<ChatMessage>> _groupMessagesByDate(List<ChatMessage> messages) {
    final grouped = <String, List<ChatMessage>>{};
    for (final msg in messages) {
      final dateKey = _formatDate(msg.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(msg);
    }
    return grouped;
  }

  static pw.Widget _buildPdfHeader(pw.Context context, String? chatName) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            chatName != null ? 'ClawChat - $chatName' : 'ClawChat Backup',
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
            'Backup erstellt mit ClawChat • ${_formatDate(DateTime.now())}',
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
            pw.Text(
              msg.content,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey800,
                lineSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'id': message.id,
      'content': message.content,
      'type': message.type.index,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'status': message.status.index,
      'agentName': message.agentName,
      'attachments': message.attachments?.map((a) => {
        'path': a.path,
        'fileName': a.fileName,
        'mimeType': a.mimeType,
        'size': a.size,
      }).toList(),
      'reactions': message.reactions,
    };
  }

  static ChatMessage _messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      type: MessageType.values[json['type']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      status: MessageStatus.values[json['status']],
      agentName: json['agentName'],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((a) => MessageAttachment(
              path: a['path'],
              fileName: a['fileName'],
              mimeType: a['mimeType'] ?? 'image/jpeg',
              size: a['size'],
            )).toList()
          : null,
      reactions: json['reactions'] != null
          ? Map<String, int>.from(json['reactions'])
          : null,
    );
  }

  static String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Heute';
    } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) {
      return 'Gestern';
    }
    return '${dt.day}. ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
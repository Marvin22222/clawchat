import 'package:flutter/material.dart';

class DateTimeUtils {
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    // Less than 1 hour: "vor 5 Min"
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return mins <= 1 ? 'Gerade eben' : 'vor ${mins} Min';
    }
    // Less than 24 hours: "vor 2 Std"
    if (diff.inHours < 24) {
      final hrs = diff.inHours;
      return 'vor $hrs Std';
    }
    // Yesterday: "Gestern, 14:32"
    if (isYesterday(dateTime)) {
      return 'Gestern, ${_formatTimeOnly(dateTime)}';
    }
    // This week (7 days): "Mo, 14:32"
    if (diff.inDays < 7) {
      final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      final dayName = days[dateTime.weekday - 1];
      return '$dayName, ${_formatTimeOnly(dateTime)}';
    }
    // Older: "01.01.24" (date only, 2-digit year)
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year.toString().substring(2)}';
  }

  static String _formatTimeOnly(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Jetzt';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${dateTime.day}.${dateTime.month}.';
    }
  }

  static String formatFullDate(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatFullDate(dateTime)} ${formatTime(dateTime)}';
  }

  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }
}

class StringUtils {
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  static bool isValidUrl(String text) {
    return Uri.tryParse(text)?.hasAbsolutePath ?? false;
  }

  static String extractUrls(String text) {
    final urlPattern = RegExp(r'https?://[^\s]+');
    return urlPattern.stringMatch(text) ?? '';
  }
}

class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ist erforderlich';
    }
    return null;
  }

  static String? validateGatewayUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Gateway URL ist erforderlich';
    }
    if (!value.contains(':') && !value.contains('.')) {
      return 'Ungültige URL';
    }
    return null;
  }

  static String? validateToken(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Token ist erforderlich';
    }
    if (value.length < 10) {
      return 'Token ist zu kurz';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-Mail ist erforderlich';
    }
    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailPattern.hasMatch(value)) {
      return 'Ungültige E-Mail-Adresse';
    }
    return null;
  }
}
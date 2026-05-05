import 'package:flutter/material.dart';

export 'spacing.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF10A37F);
  static const Color primaryHover = Color(0xFF14B890);
  static const Color primaryMuted = Color(0xFF3F3F46);
  static const Color primaryLight = Color(0xFF14B890);
  static const Color primaryDark = Color(0xFF10A37F);

  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryLight = Color(0xFFA78BFA);

  static const Color bgPrimary = Color(0xFF0D0D0D);
  static const Color bgSecondary = Color(0xFF171717);
  static const Color bgTertiary = Color(0xFF1F1F1F);
  static const Color bgElevated = Color(0xFF242424);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B8B);
  static const Color textMuted = Color(0xFF565865);
  static const Color textInverse = Color(0xFF0D0D0D);

  static const Color success = Color(0xFF10B981);
  static const Color successMuted = Color(0xFF1A3A2A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningMuted = Color(0xFF3A2F1A);
  static const Color error = Color(0xFFEF4444);
  static const Color errorMuted = Color(0xFF3A1A1A);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoMuted = Color(0xFF1A2A3A);

  static const Color userBubble = Color(0xFF343541);
  static const Color assistantBubble = Color(0xFF1F1F1F);
  static const Color systemBubble = Color(0xFF2A2A35);

  static const Color border = Color(0xFF2F2F2F);
  static const Color borderLight = Color(0xFF3F3F3F);
  static const Color borderFocused = Color(0xFF10A37F);

  static const Color shadow = Color(0x40000000);
  static const Color shadowAccent = Color(0x4010A37F);

  static const Color codeBackground = Color(0xFF161B22);
  static const Color codeBorder = Color(0xFF30363D);

  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, primaryHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFF1F1F1F),
      Color(0xFF2A2A2A),
      Color(0xFF1F1F1F),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // Light theme colors
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgLightSecondary = Color(0xFFF4F4F5);
  static const Color bgLightTertiary = Color(0xFFE4E4E7);
  // Dark theme colors
  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color bgDarkSecondary = Color(0xFF171717);
  static const Color bgDarkTertiary = Color(0xFF1F1F1F);
  // Text colors
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color textDarkSecondary = Color(0xFF8B8B8B);
  static const Color textLight = Color(0xFF18181B);
  static const Color textLightSecondary = Color(0xFF71717A);
  // Bubble colors
  static const Color assistantBubbleDark = assistantBubble;
  static const Color assistantBubbleLight = Color(0xFFF4F4F5);
}

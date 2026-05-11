#!/usr/bin/env python3
import re

with open('lib/features/chat/widgets/chat_widgets.dart', 'r') as f:
    content = f.read()

# Voice Message label (line ~849)
old = """'Voice Message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.isUser
                        ? Colors.white
                        : (isDark ? AppColors.textDark : AppColors.textLight),
                  ),"""
new = """'Voice Message',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: widget.isUser
                        ? Colors.white
                        : (isDark ? AppColors.textDark : AppColors.textLight),
                  ),"""
content = content.replace(old, new)

# Duration text
old = """style: TextStyle(
                      fontSize: 10,
                      color: widget.isUser
                          ? Colors.white70
                          : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    ),"""
new = """style: AppTypography.captionSmall.copyWith(
                      color: widget.isUser
                          ? Colors.white70
                          : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    ),"""
content = content.replace(old, new)

# File attachment filename
old = """Text(
              attachment.fileName,
              style: TextStyle(
                fontSize: 12,
                color: isUser ? Colors.white : (isDark ? AppColors.textDark : AppColors.textLight),
              ),
              overflow: TextOverflow.ellipsis,
            ),"""
new = """Text(
              attachment.fileName,
              style: AppTypography.bodySmall.copyWith(
                color: isUser ? Colors.white : (isDark ? AppColors.textDark : AppColors.textLight),
              ),
              overflow: TextOverflow.ellipsis,
            ),"""
content = content.replace(old, new)

# _InteractiveText text style
old = """TextSpan(
            text: widget.content,
            style: TextStyle(
              color: textColor,
              height: 1.4,
            ),
          ),"""
new = """TextSpan(
            text: widget.content,
            style: AppTypography.body.copyWith(
              color: textColor,
              height: 1.4,
            ),
          ),"""
content = content.replace(old, new)

# language badge uppercase
old = """Text(
                      language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),"""
new = """Text(
                      language.toUpperCase(),
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),"""
content = content.replace(old, new)

# toolName TextStyle (line 1261)
old = """Text(
                              widget.toolName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),"""
new = """Text(
                              widget.toolName,
                              style: AppTypography.h5.copyWith(
                                color: widget.isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),"""
content = content.replace(old, new)

# progress percentage text
old = """Text(
                      '${(widget.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),"""
new = """Text(
                      '${(widget.progress * 100).toInt()}%',
                      style: AppTypography.captionSmall.copyWith(
                        color: widget.isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),"""
content = content.replace(old, new)

# _SectionTitle (line 1429)
old = """Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isError
            ? AppColors.error
            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
      ),
    );"""
new = """Text(
      title,
      style: AppTypography.label.copyWith(
        fontWeight: FontWeight.w600,
        color: isError
            ? AppColors.error
            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
      ),
    );"""
content = content.replace(old, new)

# "OpenClaw denkt nach" text
old = """Text(
            'OpenClaw denkt nach',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
          )"""
new = """Text(
            'OpenClaw denkt nach',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: widget.isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
          )"""
content = content.replace(old, new)

# Voice Message recording text
old = """Text(
                      'Voice Message recording...',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),"""
new = """Text(
                      'Voice Message recording...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),"""
content = content.replace(old, new)

# duration in recording indicator
old = """Text(
                      _formatDuration(_voiceMessageService?.recordingDuration ?? Duration.zero),
                      style: TextStyle(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),"""
new = """Text(
                      _formatDuration(_voiceMessageService?.recordingDuration ?? Duration.zero),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        fontFamily: 'monospace',
                      ),
                    ),"""
content = content.replace(old, new)

# Recording text
old = """Text(
                      'Recording...',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),"""
new = """Text(
                      'Recording...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),"""
content = content.replace(old, new)

# transcribedText style
old = """Text(
                        _voiceService?.transcribedText ?? '',
                        style: TextStyle(
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),"""
new = """Text(
                        _voiceService?.transcribedText ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),"""
content = content.replace(old, new)

with open('lib/features/chat/widgets/chat_widgets.dart', 'w') as f:
    f.write(content)

print("Done!")
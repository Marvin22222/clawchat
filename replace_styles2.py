#!/usr/bin/env python3
with open('lib/features/chat/widgets/chat_widgets.dart', 'r') as f:
    content = f.read()

# emoji in quick reaction picker
old = "child: Text(emoji, style: const TextStyle(fontSize: 24)),"
new = "child: Text(emoji, style: const TextStyle(fontSize: 24)) // intentionally kept - emoji needs specific size"
content = content.replace(old, new, 1)

# Voice Message label - need to match different formatting
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
old = """'${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isUser 
                          ? Colors.white70 
                          : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    ),"""
new = """'${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: AppTypography.captionSmall.copyWith(
                      color: widget.isUser 
                          ? Colors.white70 
                          : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    ),"""
content = content.replace(old, new)

# toolName
old = """widget.toolName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark 
                                    ? AppColors.textDark 
                                    : AppColors.textLight,
                              ),"""
new = """widget.toolName,
                              style: AppTypography.h5.copyWith(
                                color: widget.isDark 
                                    ? AppColors.textDark 
                                    : AppColors.textLight,
                              ),"""
content = content.replace(old, new)

# progress percentage
old = """'${(widget.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isDark 
                            ? AppColors.textDarkSecondary 
                            : AppColors.textLightSecondary,
                      ),"""
new = """'${(widget.progress * 100).toInt()}%',
                      style: AppTypography.captionSmall.copyWith(
                        color: widget.isDark 
                            ? AppColors.textDarkSecondary 
                            : AppColors.textLightSecondary,
                      ),"""
content = content.replace(old, new)

# _SectionTitle
old = """title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isError 
            ? AppColors.error 
            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
      ),"""
new = """title,
      style: AppTypography.label.copyWith(
        fontWeight: FontWeight.w600,
        color: isError 
            ? AppColors.error 
            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
      ),"""
content = content.replace(old, new)

# OpenClaw denkt nach
old = """'OpenClaw denkt nach',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isDark 
                  ? AppColors.textDarkSecondary 
                  : AppColors.textLightSecondary,
            ),"""
new = """'OpenClaw denkt nach',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: widget.isDark 
                  ? AppColors.textDarkSecondary 
                  : AppColors.textLightSecondary,
            ),"""
content = content.replace(old, new)

with open('lib/features/chat/widgets/chat_widgets.dart', 'w') as f:
    f.write(content)

print("Done!")
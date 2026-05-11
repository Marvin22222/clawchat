#!/usr/bin/env python3
with open('lib/features/chat/widgets/chat_widgets.dart', 'r') as f:
    lines = f.readlines()

output = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # Line 850 (0-indexed: 849): Voice Message label
    if i == 849 and "'Voice Message'," in line:
        output.append(line)  # 'Voice Message',
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 12,
        i += 1
        output.append(lines[i])  # fontWeight: FontWeight.w500,
        i += 1
        # Replace next 3 lines
        output.append('                    color: widget.isUser\n')
        output.append('                        ? Colors.white\n')
        output.append('                        : (isDark ? AppColors.textDark : AppColors.textLight),\n')
        i += 1  # skip '                    color: widget.isUser'
        i += 1  # skip '                        ? Colors.white'
        i += 1  # skip '                        : (isDark ? AppColors.textDark : AppColors.textLight),'
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # Line 860 (0-indexed: 859): Duration text
    if i == 860 and '${_formatDuration(_position)} / ${_formatDuration(_duration)}' in line:
        output.append(line)  # '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 10,
        i += 1
        # Replace next 3 lines
        output.append('                      color: widget.isUser\n')
        output.append('                          ? Colors.white70\n')
        output.append('                          : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),\n')
        i += 1  # skip '                      color: widget.isUser'
        i += 1  # skip '                          ? Colors.white70'
        i += 1  # skip '                          : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),'
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # Line 1258 (0-indexed: 1257): toolName TextStyle
    if i == 1258 and 'widget.toolName,' in line:
        output.append(line)  # widget.toolName,
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 15,
        i += 1
        output.append(lines[i])  # fontWeight: FontWeight.w700,
        i += 1
        # Replace color line
        output.append('                                color: widget.isDark\n')
        output.append('                                    ? AppColors.textDark\n')
        output.append('                                    : AppColors.textLight,\n')
        i += 1  # skip old color line
        i += 1  # skip old color line
        i += 1  # skip old ),
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # Line 1318 (0-indexed: 1317): progress percentage
    if i == 1318 and "'${(widget.progress * 100).toInt()}%'" in line:
        output.append(line)  # '${(widget.progress * 100).toInt()}%',
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 10,
        i += 1
        # Replace next 4 lines
        output.append('                      color: widget.isDark\n')
        output.append('                          ? AppColors.textDarkSecondary\n')
        output.append('                          : AppColors.textLightSecondary,\n')
        i += 1  # skip color line
        i += 1  # skip ternary line
        i += 1  # skip ternary line
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # Line 1427 (0-indexed: 1426): _SectionTitle
    if i == 1427 and 'title,' in line:
        output.append(line)  # title,
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 12,
        i += 1
        output.append(lines[i])  # fontWeight: FontWeight.w600,
        i += 1
        # Replace next 5 lines
        output.append('        color: isError\n')
        output.append('            ? AppColors.error\n')
        output.append('            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),\n')
        i += 1  # skip fontSize: 12
        i += 1  # skip fontWeight
        i += 1  # skip color isError line
        i += 1  # skip ternary line
        i += 1  # skip ternary line
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # Line 1597 (0-indexed: 1596): OpenClaw denkt nach
    if i == 1597 and "'OpenClaw denkt nach'" in line:
        output.append(line)  # 'OpenClaw denkt nach',
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 13,
        i += 1
        # Replace next 5 lines
        output.append('              color: widget.isDark\n')
        output.append('                  ? AppColors.textDarkSecondary\n')
        output.append('                  : AppColors.textLightSecondary,\n')
        i += 1  # skip fontSize
        i += 1  # skip fontWeight
        i += 1  # skip color
        i += 1  # skip ternary
        output.append(lines[i])  # ),
        i += 1
        continue
    
    output.append(line)
    i += 1

with open('lib/features/chat/widgets/chat_widgets.dart', 'w') as f:
    f.writelines(output)

print("Done!")
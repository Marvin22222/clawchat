#!/usr/bin/env python3
with open('lib/features/chat/widgets/chat_widgets.dart', 'r') as f:
    lines = f.readlines()

output = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # emoji style at line 366 (0-indexed: 365)
    if i == 365 and 'Text(emoji, style' in line:
        output.append(line)  # child: Text(emoji, style: const TextStyle(fontSize: 24)),
        i += 1
        continue
    
    # Voice Message label style (0-indexed: 848)
    if i == 848 and "'Voice Message'," in line:
        output.append(line)  # 'Voice Message',
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 12,
        i += 1
        output.append(lines[i])  # fontWeight: FontWeight.w500,
        i += 1
        # Replace color lines
        output.append('                    color: widget.isUser\n')
        output.append('                        ? Colors.white\n')
        output.append('                        : (isDark ? AppColors.textDark : AppColors.textLight),\n')
        i += 3  # skip original color lines
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # Duration text style (0-indexed: 859)
    if i == 859 and '${_formatDuration(_position)}' in line:
        output.append(line)  # '${_formatDuration(_position)} / ...',
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 10,
        i += 1
        # Replace color lines
        output.append('                      color: widget.isUser\n')
        output.append('                          ? Colors.white70\n')
        output.append('                          : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),\n')
        i += 3  # skip original color lines
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # toolName style (0-indexed: 1257)
    if i == 1257 and 'widget.toolName,' in line:
        output.append(line)  # widget.toolName,
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 15,
        i += 1
        output.append(lines[i])  # fontWeight: FontWeight.w700,
        i += 1
        # Replace color lines
        output.append('                                color: widget.isDark\n')
        output.append('                                    ? AppColors.textDark\n')
        output.append('                                    : AppColors.textLight,\n')
        i += 3  # skip original color lines
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # progress percentage style (0-indexed: 1317)
    if i == 1317 and "'${(widget.progress * 100).toInt()}%'" in line:
        output.append(line)  # '${(widget.progress * 100).toInt()}%',
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 10,
        i += 1
        # Replace color lines
        output.append('                      color: widget.isDark\n')
        output.append('                          ? AppColors.textDarkSecondary\n')
        output.append('                          : AppColors.textLightSecondary,\n')
        i += 3  # skip original color lines
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # _SectionTitle style (0-indexed: 1426)
    if i == 1426 and 'title,' in line:
        output.append(line)  # title,
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 12,
        i += 1
        output.append(lines[i])  # fontWeight: FontWeight.w600,
        i += 1
        # Replace color lines
        output.append('        color: isError\n')
        output.append('            ? AppColors.error\n')
        output.append('            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),\n')
        i += 3  # skip original color lines
        output.append(lines[i])  # ),
        i += 1
        continue
    
    # OpenClaw denkt nach style (0-indexed: 1596)
    if i == 1596 and "'OpenClaw denkt nach'" in line:
        output.append(line)  # 'OpenClaw denkt nach',
        i += 1
        output.append(lines[i])  # style: TextStyle(
        i += 1
        output.append(lines[i])  # fontSize: 13,
        i += 1
        # Replace color lines
        output.append('              color: widget.isDark\n')
        output.append('                  ? AppColors.textDarkSecondary\n')
        output.append('                  : AppColors.textLightSecondary,\n')
        i += 3  # skip original color lines
        output.append(lines[i])  # ),
        i += 1
        continue
    
    output.append(line)
    i += 1

with open('lib/features/chat/widgets/chat_widgets.dart', 'w') as f:
    f.writelines(output)

print("Done!")
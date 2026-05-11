#!/usr/bin/env python3
with open('lib/features/chat/widgets/chat_widgets.dart', 'r') as f:
    lines = f.readlines()

output = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # Voice Message label style - check for 'Voice Message' on this line
    if "'Voice Message'," in line:
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
    
    # Duration text style
    if '${_formatDuration(_position)}' in line:
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
    
    # toolName style
    if 'widget.toolName,' in line and i > 1200 and i < 1300:
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
    
    # progress percentage style
    if "'${(widget.progress * 100).toInt()}%'" in line:
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
    
    # _SectionTitle style - check title, but only after line 1400
    if line.strip() == 'title,' and i > 1400:
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
    
    # OpenClaw denkt nach style
    if "'OpenClaw denkt nach'" in line:
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
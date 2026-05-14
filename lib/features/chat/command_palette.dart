import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../core/services/haptic_service.dart';

/// Command data model
class Command {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String action;
  final List<String> keywords;

  const Command({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.action,
    this.keywords = const [],
  });
}

/// Available commands
class CommandData {
  static const List<Command> commands = [
    Command(
      id: 'new',
      name: 'Neuer Chat',
      description: 'Einen neuen Chat starten',
      icon: Iconsax.edit,
      action: '/new',
      keywords: ['neu', 'new', 'start', 'chat'],
    ),
    Command(
      id: 'agents',
      name: 'Agent wechseln',
      description: 'Zu einem anderen Agenten wechseln',
      icon: Icons.smart_toy,
      action: '/agents',
      keywords: ['agent', 'wechsel', 'switch', 'bot'],
    ),
    Command(
      id: 'search',
      name: 'Nachrichten suchen',
      description: 'Durch现有ene Chat-Nachrichten suchen',
      icon: Iconsax.search_normal_1,
      action: '/search',
      keywords: ['suchen', 'search', 'find', 'finden'],
    ),
    Command(
      id: 'export',
      name: 'Chat exportieren',
      description: 'Chat als JSON, Text oder PDF exportieren',
      icon: Icons.cloud_download,
      action: '/export',
      keywords: ['export', 'speichern', 'download', 'sichern'],
    ),
    Command(
      id: 'settings',
      name: 'Einstellungen',
      description: 'App-Einstellungen öffnen',
      icon: Iconsax.setting_2,
      action: '/settings',
      keywords: ['einstellungen', 'settings', 'config', 'konfiguration'],
    ),
    Command(
      id: 'help',
      name: 'Hilfe',
      description: 'Hilfe und Tipps anzeigen',
      icon: Icons.help_outline,
      action: '/help',
      keywords: ['hilfe', 'help', 'tipps', 'support'],
    ),
    Command(
      id: 'clear',
      name: 'Chat leeren',
      description: 'Alle Nachrichten im aktuellen Chat löschen',
      icon: Iconsax.trash,
      action: '/clear',
      keywords: ['leeren', 'clear', 'löschen', 'delete', 'reset'],
    ),
  ];
}

/// Command Palette Widget
/// Triggered with Ctrl+K or / command
class CommandPalette extends StatefulWidget {
  final Function(String) onCommandSelected;
  final VoidCallback onClose;

  const CommandPalette({
    super.key,
    required this.onCommandSelected,
    required this.onClose,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<Command> _filteredCommands = CommandData.commands;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    // Start animation
    _animationController.forward();
    
    // Auto-focus search input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterCommands(String query) {
    final lowerQuery = query.toLowerCase().trim();
    
    setState(() {
      if (lowerQuery.isEmpty) {
        _filteredCommands = CommandData.commands;
      } else {
        _filteredCommands = CommandData.commands.where((cmd) {
          // Match against name, description, action, and keywords
          return cmd.name.toLowerCase().contains(lowerQuery) ||
              cmd.description.toLowerCase().contains(lowerQuery) ||
              cmd.action.toLowerCase().contains(lowerQuery) ||
              cmd.keywords.any((k) => k.contains(lowerQuery));
        }).toList();
      }
      _selectedIndex = 0;
    });
  }

  void _selectCommand(Command command) {
    HapticService.lightImpact();
    widget.onCommandSelected(command.action);
    _close();
  }

  void _close() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    
    final key = event.logicalKey;
    
    if (key == LogicalKeyboardKey.escape) {
      _close();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
      });
      _ensureSelectedVisible();
      HapticService.selectionClick();
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + _filteredCommands.length) % _filteredCommands.length;
      });
      _ensureSelectedVisible();
      HapticService.selectionClick();
    } else if (key == LogicalKeyboardKey.enter) {
      if (_filteredCommands.isNotEmpty) {
        _selectCommand(_filteredCommands[_selectedIndex]);
      }
    }
  }

  void _ensureSelectedVisible() {
    if (_scrollController.hasClients) {
      const itemHeight = 64.0;
      final targetOffset = _selectedIndex * itemHeight;
      final viewportHeight = _scrollController.position.viewportDimension;
      final currentOffset = _scrollController.offset;
      
      if (targetOffset < currentOffset) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      } else if (targetOffset + itemHeight > currentOffset + viewportHeight) {
        _scrollController.animateTo(
          targetOffset + itemHeight - viewportHeight,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from closing
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 500,
                          constraints: const BoxConstraints(maxHeight: 400),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.bgDarkSecondary 
                                : AppColors.bgLightSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSearchBar(isDark),
                              const Divider(height: 1),
                              _buildCommandList(isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Iconsax.search_normal_1,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _filterCommands,
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
              decoration: InputDecoration(
                hintText: 'Befehl suchen...',
                hintStyle: AppTypography.body.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Text(
              'ESC',
              style: AppTypography.captionSmall.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandList(bool isDark) {
    if (_filteredCommands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Keine Befehle gefunden',
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        itemCount: _filteredCommands.length,
        itemBuilder: (context, index) {
          final command = _filteredCommands[index];
          final isSelected = index == _selectedIndex;
          
          return _CommandListItem(
            command: command,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => _selectCommand(command),
          );
        },
      ),
    );
  }
}

class _CommandListItem extends StatelessWidget {
  final Command command;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CommandListItem({
    required this.command,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary.withOpacity(0.2)
                      : (isDark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  command.icon,
                  size: 18,
                  color: isSelected 
                      ? AppColors.primary
                      : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      command.name,
                      style: AppTypography.body.copyWith(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      command.description,
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark 
                            ? AppColors.textDarkSecondary 
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

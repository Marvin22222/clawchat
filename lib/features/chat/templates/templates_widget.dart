import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/templates_service.dart';
import '../../models/message_template.dart';

/// Widget for displaying and selecting message templates
class TemplatesWidget extends StatefulWidget {
  final Function(String) onTemplateSelected;
  final VoidCallback? onClose;

  const TemplatesWidget({
    super.key,
    required this.onTemplateSelected,
    this.onClose,
  });

  @override
  State<TemplatesWidget> createState() => _TemplatesWidgetState();
}

class _TemplatesWidgetState extends State<TemplatesWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MessageTemplate> _allTemplates = [];
  List<MessageTemplate> _customTemplates = [];
  bool _isLoading = true;

  final List<String> _categories = ['Schnellantworten', 'Code', 'Links', 'Custom'];
  final List<String> _categoryKeys = ['quick', 'code', 'links', 'custom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final defaults = TemplatesService.getDefaultTemplates();
    final custom = await TemplatesService.getCustomTemplates();
    
    if (mounted) {
      setState(() {
        _allTemplates = defaults;
        _customTemplates = custom;
        _isLoading = false;
      });
    }
  }

  List<MessageTemplate> _getTemplatesForCategory(int index) {
    final category = _categoryKeys[index];
    if (category == 'custom') {
      return _customTemplates;
    }
    return _allTemplates.where((t) => t.category == category).toList();
  }

  IconData _getCategoryIcon(int index) {
    switch (index) {
      case 0:
        return Iconsax.flash;
      case 1:
        return Iconsax.code;
      case 2:
        return Iconsax.link_21;
      case 3:
        return Iconsax.star;
      default:
        return Iconsax.message;
    }
  }

  void _onTemplateTap(MessageTemplate template) {
    HapticService.lightImpact();
    widget.onTemplateSelected(template.content);
  }

  void _onTemplateLongPress(MessageTemplate template) {
    if (template.isCustom) {
      _showTemplateOptions(template);
    }
  }

  void _showTemplateOptions(MessageTemplate template) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(Iconsax.play, color: AppColors.primary),
                title: const Text('Vorlage einfügen'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onTemplateSelected(template.content);
                },
              ),
              ListTile(
                leading: Icon(Iconsax.edit, color: AppColors.warning),
                title: const Text('Bearbeiten'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditTemplateDialog(template);
                },
              ),
              ListTile(
                leading: Icon(Iconsax.trash, color: AppColors.error),
                title: const Text('Löschen', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await TemplatesService.deleteTemplate(template.id);
                  _loadTemplates();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTemplateDialog(MessageTemplate template) {
    final titleController = TextEditingController(text: template.title);
    final contentController = TextEditingController(text: template.content);
    final shortcutController = TextEditingController(text: template.shortcut ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        title: const Text('Vorlage bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: shortcutController,
                decoration: const InputDecoration(
                  labelText: 'Shortcut (z.B. /hello)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Inhalt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                return;
              }
              
              final updated = template.copyWith(
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                shortcut: shortcutController.text.trim().isEmpty ? null : shortcutController.text.trim(),
              );
              
              await TemplatesService.updateTemplate(updated);
              if (context.mounted) Navigator.pop(context);
              _loadTemplates();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddTemplateDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final shortcutController = TextEditingController();
    String selectedCategory = 'quick';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          title: const Text('Neue Vorlage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    hintText: 'z.B. Begrüßung',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'quick', child: Text(_categories[0])),
                    DropdownMenuItem(value: 'code', child: Text(_categories[1])),
                    DropdownMenuItem(value: 'links', child: Text(_categories[2])),
                    DropdownMenuItem(value: 'custom', child: Text(_categories[3])),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: shortcutController,
                  decoration: const InputDecoration(
                    labelText: 'Shortcut (optional, z.B. /hi)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Inhalt',
                    hintText: 'Vorlagen-Text hier eingeben...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                  return;
                }
                
                final template = MessageTemplate(
                  id: TemplatesService.generateId(),
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  shortcut: shortcutController.text.trim().isEmpty ? null : shortcutController.text.trim(),
                  isCustom: true,
                  category: selectedCategory,
                );
                
                await TemplatesService.saveTemplate(template);
                if (context.mounted) Navigator.pop(context);
                _loadTemplates();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Erstellen', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vorlagen',
                  style: AppTypography.h4.copyWith(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Iconsax.add_circle, color: AppColors.primary),
                      onPressed: _showAddTemplateDialog,
                      tooltip: 'Vorlage hinzufügen',
                    ),
                    IconButton(
                      icon: Icon(Iconsax.close_square, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              indicatorColor: AppColors.primary,
              tabs: List.generate(_categories.length, (index) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getCategoryIcon(index), size: 16),
                    const SizedBox(width: 4),
                    Text(_categories[index]),
                  ],
                ),
              )),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(_categories.length, (index) {
                      final templates = _getTemplatesForCategory(index);
                      if (templates.isEmpty) {
                        return _buildEmptyState(index, isDark);
                      }
                      return _buildTemplateGrid(templates, isDark);
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int index, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(index),
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keine Vorlagen in dieser Kategorie',
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          if (index == 3) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: _showAddTemplateDialog,
              icon: const Icon(Iconsax.add),
              label: const Text('Eigene Vorlage erstellen'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateGrid(List<MessageTemplate> templates, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.0,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          template: template,
          onTap: () => _onTemplateTap(template),
          onLongPress: () => _onTemplateLongPress(template),
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final MessageTemplate template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onLongPress,
  });

  IconData _getCategoryIcon() {
    switch (template.category) {
      case 'code':
        return Iconsax.code;
      case 'links':
        return Iconsax.link_21;
      case 'custom':
        return Iconsax.star;
      default:
        return Iconsax.flash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(),
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    template.title,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (template.shortcut != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      template.shortcut!,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                template.content.length > 60
                    ? '${template.content.substring(0, 60)}...'
                    : template.content,
                style: AppTypography.captionSmall.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick templates bar shown above the input field
class QuickTemplatesBar extends StatelessWidget {
  final Function(String) onTemplateSelected;

  const QuickTemplatesBar({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaults = TemplatesService.getDefaultTemplates();
    final quickTemplates = defaults.where((t) => t.category == 'quick').take(5).toList();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: quickTemplates.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final template = quickTemplates[index];
          return GestureDetector(
            onTap: () => onTemplateSelected(template.content),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.flash,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    template.shortcut ?? template.title,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
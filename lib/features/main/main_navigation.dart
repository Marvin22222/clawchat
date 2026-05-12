// Deferred imports for cold start optimization
// Heavy screens loaded only when actually needed
import 'features/home/home_hub_screen.dart' deferred as home;
import 'features/chat/chat_screen.dart' deferred as chat;
import 'features/files/files_screen.dart' deferred as files;
import 'features/tasks/tasks_screen.dart' deferred as tasks;
import 'features/history/session_history_screen.dart' deferred as history;
import 'features/settings/settings_screen.dart' deferred as settings;

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../widgets/layout/modern_sidebar.dart';

/// Deferred screen widget - loads screen only when needed (reduces cold start)
/// Shows a loading indicator while the screen is being loaded
class DeferredScreen extends StatefulWidget {
  final String screenKey;
  final Future<Widget> Function() screenLoader;
  final Widget? placeholder;
  
  const DeferredScreen({
    super.key,
    required this.screenKey,
    required this.screenLoader,
    this.placeholder,
  });

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  Widget? _screen;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadScreen();
  }
  
  Future<void> _loadScreen() async {
    try {
      final screen = await widget.screenLoader();
      if (mounted) {
        setState(() {
          _screen = screen;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _screen ?? widget.placeholder ?? const SizedBox();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<SidebarItem> _sidebarItems = const [
    SidebarItem(
      label: 'Home',
      icon: Iconsax.home,
      activeIcon: Iconsax.home,
    ),
    SidebarItem(
      label: 'Chat',
      icon: Iconsax.messages,
      activeIcon: Iconsax.messages,
    ),
    SidebarItem(
      label: 'Files',
      icon: Iconsax.folder,
      activeIcon: Iconsax.folder,
    ),
    SidebarItem(
      label: 'Tasks',
      icon: Iconsax.task,
      activeIcon: Iconsax.task,
    ),
    SidebarItem(
      label: 'History',
      icon: Iconsax.clock_1,
      activeIcon: Iconsax.clock_1,
    ),
    SidebarItem(
      label: 'Settings',
      icon: Iconsax.setting_2,
      activeIcon: Iconsax.setting_2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-warm common screens in background after initial frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prewarmScreens();
    });
  }
  
  Future<void> _prewarmScreens() async {
    // Pre-warm settings screen since users often go there
    Future.microtask(() async {
      // ignore: unused_local_variable
      final _ = settings.SettingsScreen();
    });
  }

  Widget _buildScreen(int index) {
    // All screens use DeferredScreen for consistent lazy loading
    switch (index) {
      case 0:
        return DeferredScreen(
          screenKey: 'home',
          screenLoader: () async => home.HomeHubScreen(),
        );
      case 1:
        return DeferredScreen(
          screenKey: 'chat',
          screenLoader: () async => chat.ChatScreen(),
        );
      case 2:
        return DeferredScreen(
          screenKey: 'files',
          screenLoader: () async => files.FilesScreen(),
        );
      case 3:
        return DeferredScreen(
          screenKey: 'tasks', 
          screenLoader: () async => tasks.TasksScreen(),
        );
      case 4:
        return DeferredScreen(
          screenKey: 'history',
          screenLoader: () async => history.SessionHistoryScreen(),
        );
      case 5:
        return DeferredScreen(
          screenKey: 'settings',
          screenLoader: () async => settings.SettingsScreen(),
        );
      default:
        return DeferredScreen(
          screenKey: 'home',
          screenLoader: () async => home.HomeHubScreen(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          ModernSidebar(
            selectedIndex: _currentIndex,
            onIndexChanged: (index) => setState(() => _currentIndex = index),
            userName: 'User',
            items: _sidebarItems,
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: List.generate(6, (i) => _buildScreen(i)),
            ),
          ),
        ],
      ),
    );
  }
}

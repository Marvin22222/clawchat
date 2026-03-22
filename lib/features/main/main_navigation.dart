import 'package:flutter/material.dart';
import '../../widgets/layout/modern_sidebar.dart';
import '../chat/chat_screen.dart';
import '../files/files_screen.dart';
import '../tasks/tasks_screen.dart';
import '../history/session_history_screen.dart';
import '../settings/settings_screen.dart';
import '../home/home_hub_screen.dart';

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
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    SidebarItem(
      label: 'Chat',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
    ),
    SidebarItem(
      label: 'Files',
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
    ),
    SidebarItem(
      label: 'Tasks',
      icon: Icons.task_outlined,
      activeIcon: Icons.task,
    ),
    SidebarItem(
      label: 'History',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
    ),
    SidebarItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
    ),
  ];

  final List<Widget> _screens = const [
    HomeHubScreen(),
    ChatScreen(),
    FilesScreen(),
    TasksScreen(),
    SessionHistoryScreen(),
    SettingsScreen(),
  ];

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
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

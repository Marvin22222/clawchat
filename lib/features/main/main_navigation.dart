import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
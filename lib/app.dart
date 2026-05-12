import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/chat/providers/lazy_notification_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/agent_presets_provider.dart';

class ClawChatApp extends StatelessWidget {
  const ClawChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Deferred: VoiceInputService - only needed when user opens chat
        // ChangeNotifierProvider(create: (_) => VoiceInputService()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        // Deferred: NotificationService - initialized on first use (lazy)
        ChangeNotifierProvider(create: (_) => LazyNotificationProvider()),
        ChangeNotifierProvider(create: (_) => AgentPresetsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return AnimatedTheme(
            data: themeProvider.isDarkMode
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: MaterialApp(
              title: 'ClawChat',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const AppWrapper(),
            ),
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (auth.isLoggedIn && auth.ws.isConnected) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

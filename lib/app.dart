import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/colors.dart';
import 'core/constants/spacing.dart';
import 'core/constants/typography.dart';
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showOfflineOverlay = false;

  @override
  void initState() {
    super.initState();
    // Listen for connection changes after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectionListener();
    });
  }

  void _setupConnectionListener() {
    final auth = context.read<AuthProvider>();
    auth.ws.connectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() {
          _showOfflineOverlay = !isConnected;
        });
      }
    });
  }

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

    return Stack(
      children: [
        if (auth.isLoggedIn && auth.ws.isConnected)
          const HomeScreen()
        else if (!auth.isLoggedIn)
          const LoginScreen()
        else
          const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        // Global Offline Overlay
        if (_showOfflineOverlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.wifi_slash,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Offline-Modus',
                      style: AppTypography.label.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
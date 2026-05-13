import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/voice_input_service.dart';
import '../../core/constants/app_config.dart';
import '../../features/auth/biometric_auth_sheet.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/whats_new_sheet.dart';
import '../../features/tasks/providers/task_provider.dart';
import '../../providers/auth_provider.dart';

class ClawChatApp extends StatelessWidget {
  const ClawChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => VoiceInputService()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ClawChat',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: LocalizationService.getCurrentLocale(),
            supportedLocales: LocalizationService.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppWrapper(),
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

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _isLocked = false;
  bool _showOnboarding = false;
  bool _showWhatsNew = false;
  DateTime? _backgroundedAt;
  String? _lastVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool(AppConfig.keyOnboardingComplete) ?? false;
    final currentVersion = AppConfig.appVersion;
    _lastVersion = prefs.getString('last_app_version');
    
    if (!onboardingComplete) {
      setState(() => _showOnboarding = true);
    } else if (_lastVersion != null && _lastVersion != currentVersion) {
      // App was updated - show what's new
      setState(() => _showWhatsNew = true);
    }
    
    // Update stored version
    await prefs.setString('last_app_version', currentVersion);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final auth = context.read<AuthProvider>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background - start timer
      if (auth.useAutoLock == true && auth.isLoggedIn) {
        _backgroundedAt = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground - check if should lock
      if (auth.useAutoLock == true &&
          auth.isLoggedIn &&
          _backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        final lockMinutes = auth.autoLockMinutes ?? 5;
        if (elapsed.inMinutes >= lockMinutes) {
          setState(() {
            _isLocked = true;
          });
        }
        _backgroundedAt = null;
      }
    }
  }

  void _unlock() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConfig.keyOnboardingComplete, true);
          setState(() => _showOnboarding = false);
        },
      );
    }

    if (_showWhatsNew) {
      return WhatsNewSheet(
        onClose: () {
          setState(() => _showWhatsNew = false);
        },
      );
    }

    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    if (_isLocked) {
      return _AppLockScreen(
        onUnlock: _unlock,
        onLogout: () {
          context.read<AuthProvider>().logout();
          setState(() {
            _isLocked = false;
          });
        },
      );
    }

    return const AuthWrapper();
  }
}

class _AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final VoidCallback onLogout;

  const _AppLockScreen({
    required this.onUnlock,
    required this.onLogout,
  });

  @override
  State<_AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<_AppLockScreen> {
  bool _isAuthenticating = false;

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    final authenticated = await showBiometricAuthSheet(context);

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (authenticated) {
      widget.onUnlock();
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-start authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Lock icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                'ClawChat gesperrt',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'Authentifiziere dich um fortzufahren',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
              ),

              const Spacer(),

              // Unlock button
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Entsperren'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              // Logout button
              TextButton(
                onPressed: widget.onLogout,
                child: const Text('Abmelden'),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
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
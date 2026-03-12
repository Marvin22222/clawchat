import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _gatewayController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill if credentials exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.gatewayUrl != null) {
        _gatewayController.text = auth.gatewayUrl!;
      }
      if (auth.token != null) {
        _tokenController.text = auth.token!;
      }
    });
  }

  @override
  void dispose() {
    _gatewayController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_gatewayController.text.isEmpty || _tokenController.text.isEmpty) {
      setState(() => _error = 'Bitte Gateway URL und Token eingeben');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _gatewayController.text,
      _tokenController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (!success) {
        setState(() => _error = 'Verbindung fehlgeschlagen. Bitte URL und Token prüfen.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Title
              Text(
                'ClawChat',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              Text(
                'Verbindung zu OpenClaw',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark 
                      ? AppColors.textDarkSecondary 
                      : AppColors.textLightSecondary,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Gateway URL
              Text(
                'Gateway URL',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _gatewayController,
                decoration: const InputDecoration(
                  hintText: 'z.B. localhost:18789 oder deine.domain.com',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Token
              Text(
                'Gateway Token',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  hintText: 'gw_xxxxxxxxxxxxx',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verbinden'),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Help text
              Text(
                'Du findest dein Gateway Token in den OpenClaw Einstellungen unter "Gateway".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

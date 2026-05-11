import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _gatewayController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  String? _error;
  bool _biometricAvailable = false;
  String _biometricTypeName = 'Biometrie';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    
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

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isBiometricAvailable();
    final typeName = await BiometricService.getBiometricTypeName();
    
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricTypeName = typeName;
      });
    }
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

  Future<void> _loginWithBiometric() async {
    if (!_biometricAvailable) {
      setState(() => _error = 'Biometrische Anmeldung nicht verfügbar');
      return;
    }

    setState(() {
      _isBiometricLoading = true;
      _error = null;
    });

    // Authenticate with biometrics
    final authenticated = await BiometricService.authenticateWithBiometric(
      reason: 'Authentifiziere dich für ClawChat',
    );

    if (mounted) {
      setState(() => _isBiometricLoading = false);

      if (authenticated) {
        // Load saved credentials and login
        final auth = context.read<AuthProvider>();
        
        // Try to get stored credentials
        final gatewayUrl = _gatewayController.text.isNotEmpty 
            ? _gatewayController.text 
            : auth.gatewayUrl;
        final token = _tokenController.text.isNotEmpty 
            ? _tokenController.text 
            : auth.token;

        if (gatewayUrl != null && token != null) {
          final success = await auth.login(gatewayUrl, token, saveCredentials: false);
          if (!success && mounted) {
            setState(() => _error = 'Automatische Anmeldung fehlgeschlagen');
          }
        } else {
          setState(() => _error = 'Keine gespeicherten Anmeldedaten gefunden');
        }
      } else {
        setState(() => _error = 'Biometrische Authentifizierung fehlgeschlagen');
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
                    Iconsax.messages_rounded,
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
                  prefixIcon: Icon(Iconsax.link),
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
                  prefixIcon: Icon(Iconsax.key),
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
              
              // Biometric Login Button
              if (_biometricAvailable) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _isBiometricLoading ? null : _loginWithBiometric,
                  icon: _isBiometricLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _biometricTypeName == 'Face ID' 
                              ? Iconsax.face 
                              : Iconsax.finger_print,
                        ),
                  label: Text('Mit $_biometricTypeName anmelden'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ],
              
              const SizedBox(height: AppSpacing.xl),
              
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/biometric_auth_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_auth_service.dart';
import 'login_page.dart';

/// Tela de login biométrico
/// Exibida quando o usuário precisa se autenticar para acessar o app
class BiometricLoginPage extends StatefulWidget {
  const BiometricLoginPage({
    super.key,
    this.onAuthenticationSuccess,
    this.onAuthenticationFailed,
    this.allowSkip = false,
    this.title = 'Autenticação Necessária',
    this.subtitle = 'Use sua biometria para acessar o aplicativo',
  });

  /// Callback chamado quando a autenticação é bem-sucedida
  final VoidCallback? onAuthenticationSuccess;
  
  /// Callback chamado quando a autenticação falha
  final VoidCallback? onAuthenticationFailed;
  
  /// Se permite pular a autenticação biométrica
  final bool allowSkip;
  
  /// Título da tela
  final String title;
  
  /// Subtítulo da tela
  final String subtitle;

  @override
  State<BiometricLoginPage> createState() => _BiometricLoginPageState();
}

class _BiometricLoginPageState extends State<BiometricLoginPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAuthentication();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Configura as animações
  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Consumer<BiometricAuthProvider>(
          builder: (context, biometricProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildBiometricIcon(biometricProvider),
                  const SizedBox(height: 32),
                  _buildStatusText(biometricProvider),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) _buildErrorMessage(),
                  const Spacer(),
                  _buildActionButtons(biometricProvider),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Cabeçalho com título e subtítulo
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Ícone biométrico animado
  Widget _buildBiometricIcon(BiometricAuthProvider provider) {
    IconData iconData;
    
    // Determina o ícone baseado nos tipos de biometria disponíveis
    if (provider.availableBiometrics.contains(BiometricType.face)) {
      iconData = Icons.face;
    } else if (provider.availableBiometrics.contains(BiometricType.fingerprint)) {
      iconData = Icons.fingerprint;
    } else {
      iconData = Icons.security;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Texto de status da autenticação
  Widget _buildStatusText(BiometricAuthProvider provider) {
    String statusText;
    
    if (_isAuthenticating) {
      statusText = 'Autenticando...';
    } else if (provider.state == BiometricAuthState.error) {
      statusText = 'Falha na autenticação';
    } else if (provider.state == BiometricAuthState.authenticated) {
      statusText = 'Autenticado com sucesso!';
    } else {
      statusText = 'Toque no ícone para autenticar';
    }

    return Text(
      statusText,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Mensagem de erro
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Botões de ação
  Widget _buildActionButtons(BiometricAuthProvider provider) {
    return Column(
      children: [
        // Botão principal de autenticação
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isAuthenticating ? null : _startAuthentication,
            icon: _isAuthenticating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.fingerprint),
            label: Text(_isAuthenticating ? 'Autenticando...' : 'Autenticar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        
        // Botão para pular (se permitido)
        if (widget.allowSkip) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isAuthenticating ? null : _skipAuthentication,
            child: const Text(
              'Pular por agora',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
        
        // Botão para login tradicional
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _isAuthenticating ? null : _useTraditionalLogin,
          icon: const Icon(Icons.login, color: Colors.white70, size: 18),
          label: const Text(
            'Usar Email e Senha',
            style: TextStyle(color: Colors.white70),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white70),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        
        // Botão de configurações
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isAuthenticating ? null : _openSettings,
          icon: const Icon(Icons.settings, color: Colors.white70, size: 16),
          label: const Text(
            'Configurações',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Inicia o processo de autenticação
  Future<void> _startAuthentication() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<BiometricAuthProvider>();
      
      if (!provider.canUseBiometric) {
        throw Exception('Autenticação biométrica não está disponível');
      }

      final success = await provider.authenticate(
        reason: 'Autentique-se para acessar o aplicativo',
        useErrorDialogs: false,
        stickyAuth: true,
      );

      if (success) {
        _onAuthenticationSuccess();
      } else {
        _onAuthenticationFailed(provider.errorMessage ?? 'Falha na autenticação');
      }
    } catch (e) {
      _onAuthenticationFailed(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  /// Chamado quando a autenticação é bem-sucedida
  void _onAuthenticationSuccess() {
    _pulseController.stop();
    
    if (widget.onAuthenticationSuccess != null) {
      widget.onAuthenticationSuccess!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  /// Chamado quando a autenticação falha
  void _onAuthenticationFailed(String error) {
    setState(() => _errorMessage = error);
    
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });

    if (widget.onAuthenticationFailed != null) {
      widget.onAuthenticationFailed!();
    }
  }

  /// Pula a autenticação (se permitido)
  void _skipAuthentication() {
    Navigator.of(context).pop(false);
  }

  /// Navega para o login tradicional
  void _useTraditionalLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  /// Abre as configurações de autenticação biométrica
  void _openSettings() {
    Navigator.of(context).pushNamed('/biometric-settings');
  }
}

/// Widget simplificado para uso em diálogos
class BiometricLoginDialog extends StatelessWidget {
  const BiometricLoginDialog({
    super.key,
    this.title = 'Autenticação Necessária',
    this.subtitle = 'Use sua biometria para continuar',
    this.allowSkip = false,
  });

  final String title;
  final String subtitle;
  final bool allowSkip;

  /// Exibe o diálogo de autenticação biométrica
  static Future<bool?> show(
    BuildContext context, {
    String title = 'Autenticação Necessária',
    String subtitle = 'Use sua biometria para continuar',
    bool allowSkip = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BiometricLoginDialog(
        title: title,
        subtitle: subtitle,
        allowSkip: allowSkip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: BiometricLoginPage(
          title: title,
          subtitle: subtitle,
          allowSkip: allowSkip,
          onAuthenticationSuccess: () => Navigator.of(context).pop(true),
          onAuthenticationFailed: () {}, // Mantém o diálogo aberto
        ),
      ),
    );
  }
}
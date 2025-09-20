import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_auth_provider.dart';
import '../pages/home/home_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/biometric_login_page.dart';

/// Widget responsável por gerenciar o fluxo de autenticação da aplicação
/// Inclui autenticação tradicional e biométrica
class AuthenticationFlow extends StatefulWidget {
  const AuthenticationFlow({super.key});

  @override
  State<AuthenticationFlow> createState() => _AuthenticationFlowState();
}

class _AuthenticationFlowState extends State<AuthenticationFlow> {
  @override
  void initState() {
    super.initState();
    _initializeBiometricAuth();
  }

  /// Inicializa o provider de autenticação biométrica
  Future<void> _initializeBiometricAuth() async {
    final biometricProvider = context.read<BiometricAuthProvider>();
    await biometricProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BiometricAuthProvider>(
      builder: (context, authProvider, biometricProvider, child) {
        // Se o usuário está autenticado, vai para a home
        if (authProvider.isAuthenticated) {
          return const HomePage();
        }

        // Se a biometria está habilitada e disponível, mostra tela biométrica
        if (biometricProvider.isBiometricEnabled && 
            biometricProvider.isDeviceSupported) {
          return const BiometricLoginPage();
        }

        // Caso contrário, mostra tela de login tradicional
        return const LoginPage();
      },
    );
  }
}
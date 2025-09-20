import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

// Exportando BiometricType do plugin local_auth
export 'package:local_auth/local_auth.dart' show BiometricType;

/// Tipos de erro de autenticação biométrica
enum BiometricAuthError {
  notAvailable,
  notEnrolled,
  passcodeNotSet,
  lockedOut,
  permanentlyLockedOut,
  userCancel,
  unknown,
}

/// Resultado da autenticação biométrica
class BiometricAuthResult {
  final bool isSuccess;
  final BiometricAuthError? error;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.isSuccess,
    this.error,
    this.errorMessage,
  });

  factory BiometricAuthResult.success() {
    return const BiometricAuthResult(isSuccess: true);
  }

  factory BiometricAuthResult.failure({
    required BiometricAuthError error,
    String? errorMessage,
  }) {
    return BiometricAuthResult(
      isSuccess: false,
      error: error,
      errorMessage: errorMessage,
    );
  }
}

/// Serviço para autenticação biométrica usando o plugin local_auth
class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica se o dispositivo suporta autenticação biométrica
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Verifica se é possível verificar biometrias no dispositivo
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Obtém a lista de biometrias disponíveis no dispositivo
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Verifica se o dispositivo possui biometria forte (fingerprint, face, iris)
  static Future<bool> hasStrongBiometric() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.face) ||
          biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.iris);
    } catch (e) {
      return false;
    }
  }

  /// Realiza a autenticação biométrica
  static Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // Verifica se o dispositivo suporta autenticação
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return BiometricAuthResult.failure(
          error: BiometricAuthError.notAvailable,
          errorMessage: 'Dispositivo não suporta autenticação biométrica',
        );
      }

      // Verifica se pode verificar biometrias
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return BiometricAuthResult.failure(
          error: BiometricAuthError.notAvailable,
          errorMessage: 'Não é possível verificar biometrias neste dispositivo',
        );
      }

      // Verifica se há biometrias cadastradas
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return BiometricAuthResult.failure(
          error: BiometricAuthError.notEnrolled,
          errorMessage: 'Nenhuma biometria cadastrada no dispositivo',
        );
      }

      // Realiza a autenticação
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
        ),
      );

      if (didAuthenticate) {
        return BiometricAuthResult.success();
      } else {
        return BiometricAuthResult.failure(
          error: BiometricAuthError.userCancel,
          errorMessage: 'Autenticação cancelada pelo usuário',
        );
      }
    } on PlatformException catch (e) {
      return BiometricAuthResult.failure(
        error: _mapPlatformExceptionToError(e.code),
        errorMessage: e.message ?? 'Erro desconhecido na autenticação',
      );
    } catch (e) {
      return BiometricAuthResult.failure(
        error: BiometricAuthError.unknown,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }

  /// Mapeia códigos de erro da plataforma para nossos tipos de erro
  static BiometricAuthError _mapPlatformExceptionToError(String errorCode) {
    switch (errorCode) {
      case auth_error.notAvailable:
        return BiometricAuthError.notAvailable;
      case auth_error.notEnrolled:
        return BiometricAuthError.notEnrolled;
      case auth_error.passcodeNotSet:
        return BiometricAuthError.passcodeNotSet;
      case auth_error.lockedOut:
        return BiometricAuthError.lockedOut;
      case auth_error.permanentlyLockedOut:
        return BiometricAuthError.permanentlyLockedOut;
      case auth_error.biometricOnlyNotSupported:
        return BiometricAuthError.notAvailable;
      default:
        return BiometricAuthError.unknown;
    }
  }

  /// Obtém descrições amigáveis dos tipos de biometria
  static List<String> getBiometricTypeDescriptions(List<BiometricType> types) {
    return types.map((type) => _getBiometricTypeDescription(type)).toList();
  }

  /// Obtém descrição amigável de um tipo de biometria
  static String _getBiometricTypeDescription(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Reconhecimento Facial';
      case BiometricType.fingerprint:
        return 'Impressão Digital';
      case BiometricType.iris:
        return 'Reconhecimento de Íris';
      case BiometricType.weak:
        return 'Biometria Fraca';
      case BiometricType.strong:
        return 'Biometria Forte';
    }
  }

  /// Obtém descrição do erro de autenticação
  static String getErrorDescription(BiometricAuthError error) {
    switch (error) {
      case BiometricAuthError.notAvailable:
        return 'Autenticação biométrica não disponível';
      case BiometricAuthError.notEnrolled:
        return 'Nenhuma biometria cadastrada';
      case BiometricAuthError.passcodeNotSet:
        return 'Código de acesso não configurado';
      case BiometricAuthError.lockedOut:
        return 'Autenticação temporariamente bloqueada';
      case BiometricAuthError.permanentlyLockedOut:
        return 'Autenticação permanentemente bloqueada';
      case BiometricAuthError.userCancel:
        return 'Autenticação cancelada pelo usuário';
      case BiometricAuthError.unknown:
        return 'Erro desconhecido na autenticação';
    }
  }
}
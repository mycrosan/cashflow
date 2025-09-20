import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/biometric_auth_service.dart';

/// Estados da autenticação biométrica
enum BiometricAuthState {
  initial,
  checking,
  available,
  notAvailable,
  authenticating,
  authenticated,
  failed,
  error,
}

/// Provider responsável pelo gerenciamento de estado da autenticação biométrica
/// Segue o padrão Provider e princípios SOLID
class BiometricAuthProvider extends ChangeNotifier {
  // Estado atual da autenticação
  BiometricAuthState _state = BiometricAuthState.initial;
  
  // Configurações de autenticação
  bool _isBiometricEnabled = false;
  bool _isDeviceSupported = false;
  List<BiometricType> _availableBiometrics = [];
  
  // Mensagens de erro
  String? _errorMessage;
  BiometricAuthError? _errorType;
  
  // Chaves para SharedPreferences
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastAuthTime = 'last_auth_time';
  static const String _keyAuthTimeout = 'auth_timeout_minutes';
  
  // Configurações de timeout (em minutos)
  int _authTimeoutMinutes = 5;
  DateTime? _lastAuthTime;

  // Getters
  BiometricAuthState get state => _state;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isDeviceSupported => _isDeviceSupported;
  List<BiometricType> get availableBiometrics => List.unmodifiable(_availableBiometrics);
  String? get errorMessage => _errorMessage;
  BiometricAuthError? get errorType => _errorType;
  int get authTimeoutMinutes => _authTimeoutMinutes;
  DateTime? get lastAuthTime => _lastAuthTime;

  // Getters computados
  bool get isLoading => _state == BiometricAuthState.checking || 
                       _state == BiometricAuthState.authenticating;
  
  bool get isAuthenticated => _state == BiometricAuthState.authenticated;
  
  bool get canUseBiometric => _isDeviceSupported && 
                             _availableBiometrics.isNotEmpty && 
                             _isBiometricEnabled;

  bool get needsAuthentication {
    if (!_isBiometricEnabled || _lastAuthTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    final timeDifference = now.difference(_lastAuthTime!);
    return timeDifference.inMinutes >= _authTimeoutMinutes;
  }

  /// Inicializa o provider carregando configurações salvas
  Future<void> initialize() async {
    try {
      // Carrega configurações sem notificar listeners ainda
      await _loadSettings();
      await _checkDeviceCapabilities();
      
      // Define o estado final baseado nas capacidades do dispositivo
      if (_isDeviceSupported && _availableBiometrics.isNotEmpty) {
        _state = BiometricAuthState.available;
      } else {
        _state = BiometricAuthState.notAvailable;
      }
      
      // Notifica apenas uma vez após a inicialização completa
      notifyListeners();
    } catch (e) {
      _setError('Erro ao inicializar autenticação biométrica: $e');
    }
  }

  /// Carrega configurações salvas do SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isBiometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
      _authTimeoutMinutes = prefs.getInt(_keyAuthTimeout) ?? 5;
      
      final lastAuthTimestamp = prefs.getInt(_keyLastAuthTime);
      if (lastAuthTimestamp != null) {
        _lastAuthTime = DateTime.fromMillisecondsSinceEpoch(lastAuthTimestamp);
      }
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
    }
  }

  /// Verifica as capacidades do dispositivo
  Future<void> _checkDeviceCapabilities() async {
    _isDeviceSupported = await BiometricAuthService.isDeviceSupported();
    
    if (_isDeviceSupported) {
      final isAvailable = await BiometricAuthService.canCheckBiometrics();
      if (isAvailable) {
        _availableBiometrics = await BiometricAuthService.getAvailableBiometrics();
      }
    }
  }

  /// Habilita ou desabilita a autenticação biométrica
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled && !_isDeviceSupported) {
        _setError('Dispositivo não suporta autenticação biométrica');
        return false;
      }

      if (enabled && _availableBiometrics.isEmpty) {
        _setError('Nenhuma biometria cadastrada no dispositivo');
        return false;
      }

      // Se está habilitando, testa a autenticação primeiro
      if (enabled && !_isBiometricEnabled) {
        final result = await authenticate(
          reason: 'Confirme sua identidade para habilitar a autenticação biométrica',
        );
        
        if (!result) {
          return false;
        }
      }

      _isBiometricEnabled = enabled;
      await _saveSettings();
      
      if (!enabled) {
        _clearAuthenticationState();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao configurar autenticação biométrica: $e');
      return false;
    }
  }

  /// Define o timeout de autenticação em minutos
  Future<void> setAuthTimeout(int minutes) async {
    if (minutes < 1 || minutes > 60) {
      throw ArgumentError('Timeout deve estar entre 1 e 60 minutos');
    }
    
    _authTimeoutMinutes = minutes;
    await _saveSettings();
    notifyListeners();
  }

  /// Realiza a autenticação biométrica
  Future<bool> authenticate({
    String reason = 'Autentique-se para acessar o aplicativo',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    if (!canUseBiometric) {
      _setError('Autenticação biométrica não está disponível');
      return false;
    }

    _setState(BiometricAuthState.authenticating);
    _clearError();

    try {
      final result = await BiometricAuthService.authenticate(
        localizedReason: reason,
        useErrorDialogs: useErrorDialogs,
        stickyAuth: stickyAuth,
      );

      if (result.isSuccess) {
        _lastAuthTime = DateTime.now();
        await _saveLastAuthTime();
        _setState(BiometricAuthState.authenticated);
        return true;
      } else {
        _setError(
          result.errorMessage ?? 'Falha na autenticação',
          result.error,
        );
        return false;
      }
    } catch (e) {
      _setError('Erro inesperado na autenticação: $e');
      return false;
    }
  }

  /// Limpa o estado de autenticação (logout)
  void logout() {
    _lastAuthTime = null;
    _clearAuthenticationState();
    _saveLastAuthTime();
  }

  /// Verifica se precisa autenticar novamente
  bool shouldAuthenticate() {
    return _isBiometricEnabled && needsAuthentication;
  }

  /// Obtém descrição dos tipos de biometria disponíveis
  List<String> getAvailableBiometricDescriptions() {
    return BiometricAuthService.getBiometricTypeDescriptions(_availableBiometrics);
  }

  /// Verifica se há biometrias fortes disponíveis
  Future<bool> hasStrongBiometric() async {
    return await BiometricAuthService.hasStrongBiometric();
  }

  /// Salva configurações no SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBiometricEnabled, _isBiometricEnabled);
      await prefs.setInt(_keyAuthTimeout, _authTimeoutMinutes);
    } catch (e) {
      debugPrint('Erro ao salvar configurações: $e');
    }
  }

  /// Salva o timestamp da última autenticação
  Future<void> _saveLastAuthTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastAuthTime != null) {
        await prefs.setInt(_keyLastAuthTime, _lastAuthTime!.millisecondsSinceEpoch);
      } else {
        await prefs.remove(_keyLastAuthTime);
      }
    } catch (e) {
      debugPrint('Erro ao salvar timestamp de autenticação: $e');
    }
  }

  /// Define o estado atual
  void _setState(BiometricAuthState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Define uma mensagem de erro
  void _setError(String message, [BiometricAuthError? type]) {
    _errorMessage = message;
    _errorType = type;
    _setState(BiometricAuthState.error);
  }

  /// Limpa mensagens de erro
  void _clearError() {
    _errorMessage = null;
    _errorType = null;
  }

  /// Limpa o estado de autenticação
  void _clearAuthenticationState() {
    if (_state == BiometricAuthState.authenticated) {
      _setState(_isDeviceSupported && _availableBiometrics.isNotEmpty 
          ? BiometricAuthState.available 
          : BiometricAuthState.notAvailable);
    }
  }

  /// Cancela autenticação em andamento
  Future<void> cancelAuthentication() async {
    _clearAuthenticationState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
import 'package:flutter/material.dart';

/// Serviço para obter informações do aplicativo como versão e build
class AppInfoService {
  static AppInfoService? _instance;
  
  // Valores fixos para a versão do aplicativo
  final String _version = '1.0.0';
  final String _buildNumber = '1';
  final String _appName = 'Fluxo Família';
  
  /// Construtor privado
  AppInfoService._();
  
  /// Obtém a instância singleton do serviço
  static Future<AppInfoService> getInstance() async {
    if (_instance == null) {
      _instance = AppInfoService._();
    }
    return _instance!;
  }
  
  /// Obtém a versão do aplicativo no formato "x.y.z"
  String get appVersion => _version;
  
  /// Obtém o número de build do aplicativo
  String get buildNumber => _buildNumber;
  
  /// Obtém a versão completa do aplicativo no formato "x.y.z+build"
  String get fullVersion => '${appVersion}+${buildNumber}';
  
  /// Obtém o nome do aplicativo
  String get appName => _appName;
}
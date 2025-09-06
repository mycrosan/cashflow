import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class FirebaseConfig {
  static bool _initialized = false;

  /// Inicializa o Firebase
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // Configuração para web usando variáveis de ambiente
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: AppConfig.firebaseApiKey,
            authDomain: AppConfig.firebaseAuthDomain,
            projectId: AppConfig.firebaseProjectId,
            storageBucket: AppConfig.firebaseStorageBucket,
            messagingSenderId: AppConfig.firebaseMessagingSenderId,
            appId: AppConfig.firebaseAppId,
            measurementId: AppConfig.firebaseMeasurementId,
          ),
        );
      } else {
        // Configuração para mobile (Android/iOS) - usa arquivos google-services.json/GoogleService-Info.plist
        await Firebase.initializeApp();
      }

      _initialized = true;
    } catch (e) {
      throw Exception('Erro ao inicializar Firebase: $e');
    }
  }

  /// Verifica se o Firebase está inicializado
  static bool get isInitialized => _initialized;

  /// Configurações específicas por plataforma
  static Map<String, dynamic> get platformConfig {
    if (kIsWeb) {
      return {
        'platform': 'web',
        'useFirestore': AppConfig.enableFirebaseSync,
        'useSQLite': false,
        'enableSync': AppConfig.enableFirebaseSync,
        'environment': AppConfig.appEnvironment,
      };
    } else {
      return {
        'platform': 'mobile',
        'useFirestore': AppConfig.enableFirebaseSync,
        'useSQLite': true,
        'enableSync': AppConfig.enableFirebaseSync,
        'environment': AppConfig.appEnvironment,
      };
    }
  }

  /// Configurações de sincronização
  static Map<String, dynamic> get syncConfig {
    return {
      'autoSyncEnabled': true,
      'syncInterval': const Duration(minutes: 5),
      'retryAttempts': 3,
      'retryDelay': const Duration(seconds: 30),
      'batchSize': 50,
      'conflictResolution': 'latest_wins', // ou 'manual'
    };
  }

  /// Configurações de cache
  static Map<String, dynamic> get cacheConfig {
    return {
      'enableCache': true,
      'cacheExpiration': const Duration(hours: 1),
      'maxCacheSize': 1000,
      'clearCacheOnSync': false,
    };
  }
}

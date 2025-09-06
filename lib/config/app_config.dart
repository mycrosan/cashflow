import 'dart:io';

/// Configurações da aplicação baseadas em variáveis de ambiente
class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Firebase Configuration
  static String get firebaseProjectId => 
      _getEnv('FIREBASE_PROJECT_ID', 'seu-projeto-firebase');
  
  static String get firebaseApiKey => 
      _getEnv('FIREBASE_API_KEY', 'sua-api-key-firebase');
  
  static String get firebaseAuthDomain => 
      _getEnv('FIREBASE_AUTH_DOMAIN', 'seu-projeto.firebaseapp.com');
  
  static String get firebaseStorageBucket => 
      _getEnv('FIREBASE_STORAGE_BUCKET', 'seu-projeto.appspot.com');
  
  static String get firebaseMessagingSenderId => 
      _getEnv('FIREBASE_MESSAGING_SENDER_ID', '123456789');
  
  static String get firebaseAppId => 
      _getEnv('FIREBASE_APP_ID', '1:123456789:web:abcdef123456');
  
  static String get firebaseMeasurementId => 
      _getEnv('FIREBASE_MEASUREMENT_ID', 'G-XXXXXXXXXX');

  // Database Configuration
  static String get databaseName => 
      _getEnv('DATABASE_NAME', 'fluxo_familiar.db');
  
  static int get databaseVersion => 
      int.tryParse(_getEnv('DATABASE_VERSION', '8')) ?? 8;

  // App Configuration
  static String get appName => 
      _getEnv('APP_NAME', 'Fluxo Familiar');
  
  static String get appVersion => 
      _getEnv('APP_VERSION', '1.0.0');
  
  static String get appEnvironment => 
      _getEnv('APP_ENVIRONMENT', 'development');
  
  static String get apiBaseUrl => 
      _getEnv('API_BASE_URL', 'https://api.fluxofamiliar.com');

  // Feature Flags
  static bool get enableFirebaseSync => 
      _getEnv('ENABLE_FIREBASE_SYNC', 'true').toLowerCase() == 'true';
  
  static bool get enablePushNotifications => 
      _getEnv('ENABLE_PUSH_NOTIFICATIONS', 'true').toLowerCase() == 'true';
  
  static bool get enableAnalytics => 
      _getEnv('ENABLE_ANALYTICS', 'true').toLowerCase() == 'true';
  
  static bool get enableCrashReporting => 
      _getEnv('ENABLE_CRASH_REPORTING', 'true').toLowerCase() == 'true';

  // Security Configuration
  static String get encryptionKey => 
      _getEnv('ENCRYPTION_KEY', 'sua-chave-de-criptografia-32-chars');
  
  static String get passwordSalt => 
      _getEnv('PASSWORD_SALT', 'seu-salt-para-senhas');

  // External Services
  static String get googleMapsApiKey => 
      _getEnv('GOOGLE_MAPS_API_KEY', 'sua-google-maps-api-key');
  
  static String get sentryDsn => 
      _getEnv('SENTRY_DSN', 'https://sua-sentry-dsn@sentry.io/projeto');

  // Development Configuration
  static bool get enableDebugLogs => 
      _getEnv('ENABLE_DEBUG_LOGS', 'true').toLowerCase() == 'true';
  
  static String get devServerUrl => 
      _getEnv('DEV_SERVER_URL', 'http://localhost:3000');

  // Helper method to get environment variables
  static String _getEnv(String key, String defaultValue) {
    // Primeiro tenta pegar da variável de ambiente do sistema
    final systemEnv = Platform.environment[key];
    if (systemEnv != null && systemEnv.isNotEmpty) {
      return systemEnv;
    }
    
    // Se não encontrar, retorna o valor padrão
    return defaultValue;
  }

  /// Verifica se todas as configurações obrigatórias estão definidas
  static bool get isConfigured {
    return firebaseProjectId != 'seu-projeto-firebase' &&
           firebaseApiKey != 'sua-api-key-firebase' &&
           firebaseAuthDomain != 'seu-projeto.firebaseapp.com';
  }

  /// Retorna um mapa com todas as configurações (para debug)
  static Map<String, dynamic> getAllConfig() {
    return {
      'firebaseProjectId': firebaseProjectId,
      'firebaseApiKey': firebaseApiKey,
      'firebaseAuthDomain': firebaseAuthDomain,
      'firebaseStorageBucket': firebaseStorageBucket,
      'firebaseMessagingSenderId': firebaseMessagingSenderId,
      'firebaseAppId': firebaseAppId,
      'firebaseMeasurementId': firebaseMeasurementId,
      'databaseName': databaseName,
      'databaseVersion': databaseVersion,
      'appName': appName,
      'appVersion': appVersion,
      'appEnvironment': appEnvironment,
      'apiBaseUrl': apiBaseUrl,
      'enableFirebaseSync': enableFirebaseSync,
      'enablePushNotifications': enablePushNotifications,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enableDebugLogs': enableDebugLogs,
      'devServerUrl': devServerUrl,
      'isConfigured': isConfigured,
    };
  }
}

import 'app_config.dart';

/// Exemplo de como usar as configurações da aplicação
class ConfigExample {
  
  /// Exemplo de inicialização com verificação de configuração
  static Future<void> initializeApp() async {
    print('🚀 Inicializando Fluxo Familiar...');
    
    // Verificar se as configurações estão definidas
    if (!AppConfig.isConfigured) {
      print('⚠️  ATENÇÃO: Configurações não definidas!');
      print('📝 Copie o arquivo env.template para .env e configure as variáveis');
      print('🔧 Ou defina as variáveis de ambiente do sistema');
      return;
    }
    
    // Mostrar configurações (apenas em desenvolvimento)
    if (AppConfig.appEnvironment == 'development') {
      print('📋 Configurações carregadas:');
      print('   - Projeto Firebase: ${AppConfig.firebaseProjectId}');
      print('   - Ambiente: ${AppConfig.appEnvironment}');
      print('   - Sincronização Firebase: ${AppConfig.enableFirebaseSync}');
      print('   - Notificações: ${AppConfig.enablePushNotifications}');
    }
    
    // Configurar Firebase se habilitado
    if (AppConfig.enableFirebaseSync) {
      print('🔥 Configurando Firebase...');
      // await FirebaseConfig.initialize();
    }
    
    // Configurar banco de dados
    print('💾 Configurando banco de dados...');
    print('   - Nome: ${AppConfig.databaseName}');
    print('   - Versão: ${AppConfig.databaseVersion}');
    
    print('✅ Aplicação inicializada com sucesso!');
  }
  
  /// Exemplo de uso das configurações em diferentes contextos
  static void showUsageExamples() {
    print('📚 Exemplos de uso das configurações:');
    
    // Configurações de Firebase
    print('\n🔥 Firebase:');
    print('   - API Key: ${AppConfig.firebaseApiKey.substring(0, 10)}...');
    print('   - Project ID: ${AppConfig.firebaseProjectId}');
    print('   - Auth Domain: ${AppConfig.firebaseAuthDomain}');
    
    // Configurações de banco
    print('\n💾 Banco de Dados:');
    print('   - Nome: ${AppConfig.databaseName}');
    print('   - Versão: ${AppConfig.databaseVersion}');
    
    // Feature flags
    print('\n🎛️  Feature Flags:');
    print('   - Firebase Sync: ${AppConfig.enableFirebaseSync}');
    print('   - Push Notifications: ${AppConfig.enablePushNotifications}');
    print('   - Analytics: ${AppConfig.enableAnalytics}');
    print('   - Debug Logs: ${AppConfig.enableDebugLogs}');
    
    // Configurações de segurança
    print('\n🔐 Segurança:');
    print('   - Encryption Key: ${AppConfig.encryptionKey.substring(0, 10)}...');
    print('   - Password Salt: ${AppConfig.passwordSalt.substring(0, 10)}...');
    
    // Configurações externas
    print('\n🌐 Serviços Externos:');
    print('   - Google Maps: ${AppConfig.googleMapsApiKey.substring(0, 10)}...');
    print('   - Sentry DSN: ${AppConfig.sentryDsn.substring(0, 20)}...');
  }
  
  /// Exemplo de configuração condicional baseada no ambiente
  static Map<String, dynamic> getEnvironmentConfig() {
    switch (AppConfig.appEnvironment) {
      case 'development':
        return {
          'debugMode': true,
          'logLevel': 'verbose',
          'apiUrl': AppConfig.devServerUrl,
          'enableHotReload': true,
        };
      case 'staging':
        return {
          'debugMode': false,
          'logLevel': 'info',
          'apiUrl': 'https://staging-api.fluxofamiliar.com',
          'enableHotReload': false,
        };
      case 'production':
        return {
          'debugMode': false,
          'logLevel': 'error',
          'apiUrl': AppConfig.apiBaseUrl,
          'enableHotReload': false,
        };
      default:
        return {
          'debugMode': true,
          'logLevel': 'info',
          'apiUrl': AppConfig.apiBaseUrl,
          'enableHotReload': false,
        };
    }
  }
  
  /// Exemplo de validação de configurações
  static List<String> validateConfig() {
    List<String> errors = [];
    
    // Validar Firebase
    if (AppConfig.firebaseProjectId == 'seu-projeto-firebase') {
      errors.add('FIREBASE_PROJECT_ID não configurado');
    }
    
    if (AppConfig.firebaseApiKey == 'sua-api-key-firebase') {
      errors.add('FIREBASE_API_KEY não configurado');
    }
    
    // Validar chaves de segurança
    if (AppConfig.encryptionKey == 'sua-chave-de-criptografia-32-chars') {
      errors.add('ENCRYPTION_KEY não configurado');
    }
    
    // Validar configurações específicas do ambiente
    if (AppConfig.appEnvironment == 'production') {
      if (AppConfig.enableDebugLogs) {
        errors.add('Debug logs não devem estar habilitados em produção');
      }
    }
    
    return errors;
  }
}

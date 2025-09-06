# 🔧 Configuração do Fluxo Familiar

Este guia explica como configurar o projeto Fluxo Familiar para desenvolvimento e produção.

## 📋 Pré-requisitos

- Flutter SDK (versão 3.0 ou superior)
- Dart SDK
- Android Studio / Xcode (para desenvolvimento mobile)
- Conta no Firebase (para sincronização)

## 🚀 Configuração Inicial

### 1. Clone o Repositório

```bash
git clone https://github.com/seu-usuario/fluxo-familiar.git
cd fluxo-familiar
```

### 2. Instale as Dependências

```bash
flutter pub get
```

### 3. Configure as Variáveis de Ambiente

#### Opção A: Arquivo .env (Recomendado)

1. Copie o arquivo de template:
```bash
cp env.template .env
```

2. Edite o arquivo `.env` com suas configurações reais:
```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=meu-projeto-firebase
FIREBASE_API_KEY=AIzaSyC...
FIREBASE_AUTH_DOMAIN=meu-projeto.firebaseapp.com
# ... outras configurações
```

#### Opção B: Variáveis de Ambiente do Sistema

Defina as variáveis de ambiente no seu sistema:

```bash
# Linux/macOS
export FIREBASE_PROJECT_ID="meu-projeto-firebase"
export FIREBASE_API_KEY="AIzaSyC..."

# Windows
set FIREBASE_PROJECT_ID=meu-projeto-firebase
set FIREBASE_API_KEY=AIzaSyC...
```

### 4. Configure o Firebase

#### Android

1. Copie o template:
```bash
cp android/app/google-services.json.template android/app/google-services.json
```

2. Baixe o arquivo `google-services.json` do console do Firebase
3. Substitua o conteúdo do arquivo com o arquivo real

#### iOS

1. Copie o template:
```bash
cp ios/Runner/GoogleService-Info.plist.template ios/Runner/GoogleService-Info.plist
```

2. Baixe o arquivo `GoogleService-Info.plist` do console do Firebase
3. Substitua o conteúdo do arquivo com o arquivo real

### 5. Configure o Firebase no Console

1. Acesse o [Console do Firebase](https://console.firebase.google.com)
2. Crie um novo projeto ou use um existente
3. Adicione os apps Android e iOS
4. Baixe os arquivos de configuração
5. Configure as regras de segurança do Firestore

## 🔐 Configurações de Segurança

### Firebase Security Rules

Configure as regras do Firestore no console do Firebase:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários podem acessar apenas seus próprios dados
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Transações do usuário
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### Chaves de Criptografia

Gere chaves seguras para produção:

```bash
# Gerar chave de criptografia (32 caracteres)
openssl rand -hex 16

# Gerar salt para senhas
openssl rand -base64 32
```

## 🏗️ Estrutura de Configuração

```
lib/
├── config/
│   └── app_config.dart          # Configurações centralizadas
├── services/
│   └── database_service.dart    # Configuração do banco local
└── core/
    └── firebase_config.dart     # Configuração do Firebase

# Arquivos de configuração
.env                            # Variáveis de ambiente (não commitar)
env.template                    # Template das variáveis
android/app/google-services.json # Configuração Firebase Android
ios/Runner/GoogleService-Info.plist # Configuração Firebase iOS
```

## 🚦 Ambientes

### Development
- Banco local SQLite
- Firebase em modo de desenvolvimento
- Logs detalhados habilitados

### Staging
- Banco local + sincronização Firebase
- Dados de teste
- Logs moderados

### Production
- Sincronização completa com Firebase
- Logs mínimos
- Configurações otimizadas

## 🔍 Verificação da Configuração

Execute o comando para verificar se tudo está configurado:

```bash
flutter run --debug
```

Verifique no console se aparecem as mensagens:
- ✅ Firebase inicializado
- ✅ Banco de dados criado
- ✅ Configurações carregadas

## 🐛 Solução de Problemas

### Erro: "Firebase not configured"
- Verifique se os arquivos `google-services.json` e `GoogleService-Info.plist` estão corretos
- Confirme se as variáveis de ambiente estão definidas

### Erro: "Database not found"
- Execute `flutter clean` e `flutter pub get`
- Verifique se a versão do banco está correta

### Erro: "API Key invalid"
- Verifique se a API Key do Firebase está correta
- Confirme se o projeto Firebase está ativo

## 📚 Recursos Adicionais

- [Documentação do Firebase](https://firebase.google.com/docs)
- [Flutter Environment Variables](https://flutter.dev/docs/development/tools/pub/pubspec)
- [SQLite Flutter](https://pub.dev/packages/sqflite)

## 🤝 Contribuição

Ao contribuir com o projeto:

1. Nunca commite arquivos `.env` ou chaves reais
2. Use sempre os templates fornecidos
3. Documente novas configurações necessárias
4. Teste em diferentes ambientes

## 📞 Suporte

Se encontrar problemas na configuração:

1. Verifique este guia primeiro
2. Consulte os issues do GitHub
3. Entre em contato com a equipe de desenvolvimento

---

**⚠️ IMPORTANTE**: Nunca commite arquivos com chaves reais ou informações sensíveis!

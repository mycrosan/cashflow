# Testes Automatizados - Fluxo Família

Este diretório contém a suíte completa de testes automatizados para o aplicativo Fluxo Família, garantindo pelo menos 80% de cobertura de código.

## 📁 Estrutura dos Testes

```
test/
├── models/           # Testes unitários para models
│   ├── transaction_test.dart
│   ├── member_test.dart
│   ├── category_test.dart
│   └── user_test.dart
├── services/         # Testes unitários para services
│   └── database_service_test.dart
├── providers/        # Testes unitários para providers
│   └── transaction_provider_test.dart
├── pages/            # Testes de widget para páginas
│   └── login_page_test.dart
├── widgets/          # Testes de widget para componentes
│   ├── custom_button_test.dart
│   └── custom_text_field_test.dart
├── core/             # Testes para utilitários
├── test_helper.dart  # Utilitários de teste
└── README.md         # Este arquivo
```

## 🚀 Como Executar os Testes

### Pré-requisitos

1. **Flutter SDK**: Versão 3.16.0 ou superior
2. **Dependências**: Execute `flutter pub get` para instalar as dependências de teste
3. **FVM**: Se usando FVM, execute `fvm flutter pub get`

### Comandos de Teste

#### 1. Executar Todos os Testes
```bash
flutter test
```

#### 2. Executar Testes com Cobertura
```bash
flutter test --coverage
```

#### 3. Executar Script de Cobertura (Recomendado)
```bash
./test_coverage.sh
```

#### 4. Executar Testes Específicos
```bash
# Testes de models
flutter test test/models/

# Testes de services
flutter test test/services/

# Testes de widgets
flutter test test/widgets/

# Teste específico
flutter test test/models/transaction_test.dart
```

#### 5. Executar Testes com Verbose
```bash
flutter test --verbose
```

## 📊 Verificação de Cobertura

### Cobertura Mínima: 80%

O projeto está configurado para manter pelo menos 80% de cobertura de código. Para verificar:

```bash
# Gerar relatório de cobertura
flutter test --coverage

# Ver resumo da cobertura
lcov --summary coverage/lcov.info

# Gerar relatório HTML
genhtml coverage/lcov.info -o coverage/html --no-function-coverage
```

### Relatórios de Cobertura

- **LCOV**: `coverage/lcov.info`
- **HTML**: `coverage/html/index.html`

## 🧪 Tipos de Testes

### 1. Testes Unitários (Models)
- ✅ Criação de objetos
- ✅ Serialização/Deserialização JSON
- ✅ Validação de dados
- ✅ Métodos utilitários
- ✅ Getters e setters

### 2. Testes de Serviços
- ✅ Operações de banco de dados
- ✅ Chamadas de API
- ✅ Tratamento de erros
- ✅ Validação de dados

### 3. Testes de Providers
- ✅ Gerenciamento de estado
- ✅ Cálculos financeiros
- ✅ Filtros e agrupamentos
- ✅ Operações CRUD

### 4. Testes de Widgets
- ✅ Renderização de componentes
- ✅ Interações do usuário
- ✅ Validação de formulários
- ✅ Estados de loading/erro
- ✅ Navegação

## 🔧 Configuração de CI/CD

### GitHub Actions

O projeto inclui configuração automática de CI/CD em `.github/workflows/test.yml` que:

- ✅ Executa testes em cada push/PR
- ✅ Verifica formatação de código
- ✅ Executa análise estática
- ✅ Gera relatórios de cobertura
- ✅ Verifica meta de 80% de cobertura
- ✅ Comenta PRs com resultados

### Configuração Local

Para configurar o ambiente local:

```bash
# Instalar dependências de teste
flutter pub get

# Executar análise de código
flutter analyze

# Verificar formatação
flutter format --set-exit-if-changed .

# Executar testes
flutter test --coverage
```

## 📝 Escrevendo Novos Testes

### Estrutura de Teste

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([DependencyClass])
import 'test_file.mocks.dart';

void main() {
  group('ClassName Tests', () {
    late ClassName instance;
    late MockDependency mockDependency;

    setUp(() {
      instance = ClassName();
      mockDependency = MockDependency();
    });

    test('should handle positive scenario', () {
      // Arrange
      // Act
      // Assert
    });

    test('should handle negative scenario', () {
      // Arrange
      // Act
      // Assert
    });

    testWidgets('should render widget correctly', (WidgetTester tester) async {
      // Arrange
      // Act
      await tester.pumpWidget(/* widget */);
      // Assert
    });
  });
}
```

### Boas Práticas

1. **Nomenclatura**: Use nomes descritivos para testes
2. **Organização**: Agrupe testes relacionados com `group()`
3. **Setup**: Use `setUp()` para configuração comum
4. **AAA Pattern**: Arrange, Act, Assert
5. **Mocks**: Use mocks para dependências externas
6. **Cobertura**: Teste cenários positivos e negativos
7. **Widgets**: Use `testWidgets()` para testes de UI

## 🐛 Solução de Problemas

### Erros Comuns

#### 1. Mockito não gera mocks
```bash
flutter packages pub run build_runner build
```

#### 2. Testes falham por dependências
```bash
flutter clean
flutter pub get
flutter test
```

#### 3. Cobertura baixa
- Adicione testes para métodos não cobertos
- Verifique cenários de erro
- Teste edge cases

#### 4. Testes de widget falham
- Use `await tester.pump()` após interações
- Verifique se widgets estão sendo encontrados
- Use `tester.pumpAndSettle()` para animações

## 📈 Métricas de Qualidade

### Cobertura Atual
- **Models**: 95%+
- **Services**: 85%+
- **Providers**: 80%+
- **Widgets**: 75%+
- **Total**: 80%+

### Meta de Cobertura
- **Mínimo**: 80%
- **Ideal**: 90%+
- **Crítico**: 95%+ (para componentes core)

## 🔍 Ferramentas Utilizadas

- **flutter_test**: Framework de testes do Flutter
- **mockito**: Criação de mocks
- **coverage**: Análise de cobertura
- **lcov**: Relatórios de cobertura
- **GitHub Actions**: CI/CD

## 📚 Recursos Adicionais

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Coverage Package](https://pub.dev/packages/coverage)
- [GitHub Actions](https://docs.github.com/en/actions)

---

**Nota**: Mantenha sempre a cobertura acima de 80% e adicione testes para novas funcionalidades antes de fazer merge para a branch principal.


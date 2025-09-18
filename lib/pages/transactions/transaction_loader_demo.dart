import 'package:flutter/material.dart';
import '../../widgets/transaction_loader.dart';

/// Página de demonstração do widget TransactionLoader com diferentes configurações
/// Esta página demonstra as animações premium de carregamento para telas de transação
class TransactionLoaderDemo extends StatefulWidget {
  const TransactionLoaderDemo({super.key});

  @override
  State<TransactionLoaderDemo> createState() => _TransactionLoaderDemoState();
}

class _TransactionLoaderDemoState extends State<TransactionLoaderDemo> {
  bool _showLoader1 = false;
  bool _showLoader2 = false;
  bool _showLoader3 = false;
  bool _showCompactLoader = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demonstração do Transaction Loader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              // Alternar tema (isso precisaria ser implementado no seu app)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alternância de tema seria implementada aqui'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Alternar Tema',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demonstração do Transaction Loader',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Animações premium de carregamento projetadas para telas de transação com tendências de design modernas incluindo glassmorfismo, gradientes e efeitos de movimento suaves.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Demo 1: Transaction Loader Padrão
            _buildDemoSection(
              title: 'Transaction Loader Padrão',
              description: 'Carregador completo com efeitos de glassmorfismo, gradientes e animações específicas para transações.',
              isActive: _showLoader1,
              onToggle: () => setState(() => _showLoader1 = !_showLoader1),
              child: _showLoader1
                  ? const TransactionLoader(
                      message: "Processando sua transação...",
                      size: 100.0,
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Toque para mostrar o carregador',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Demo 2: Cores Personalizadas
            _buildDemoSection(
              title: 'Cores Personalizadas',
              description: 'Carregador de transação com cores de gradiente roxo e rosa personalizadas.',
              isActive: _showLoader2,
              onToggle: () => setState(() => _showLoader2 = !_showLoader2),
              child: _showLoader2
                  ? const TransactionLoader(
                      message: "Salvando dados da transação...",
                      size: 90.0,
                      primaryColor: Color(0xFF8B5CF6),
                      secondaryColor: Color(0xFFEC4899),
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Toque para mostrar carregador personalizado',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Demo 3: Sem Efeito de Pulsação
            _buildDemoSection(
              title: 'Versão Minimalista',
              description: 'Carregador limpo sem efeitos de pulsação, perfeito para estados de carregamento sutis.',
              isActive: _showLoader3,
              onToggle: () => setState(() => _showLoader3 = !_showLoader3),
              child: _showLoader3
                  ? const TransactionLoader(
                      message: "Atualizando transação...",
                      size: 80.0,
                      showPulseEffect: false,
                      primaryColor: Color(0xFF10B981),
                      secondaryColor: Color(0xFF059669),
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Toque para mostrar carregador minimalista',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Demo 4: Carregador Compacto
            _buildDemoSection(
              title: 'Carregador Compacto',
              description: 'Carregador eficiente em espaço para áreas menores como barras de navegação ou estados de carregamento inline.',
              isActive: _showCompactLoader,
              onToggle: () => setState(() => _showCompactLoader = !_showCompactLoader),
              child: _showCompactLoader
                  ? SizedBox(
                      height: 60,
                      child: const Center(
                        child: CompactTransactionLoader(
                          message: "Carregando...",
                          size: 20.0,
                        ),
                      ),
                    )
                  : Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Toque para mostrar carregador compacto',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ),
            
            const SizedBox(height: 32),
            
            // Features List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recursos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: Icons.gradient,
                      title: 'Gradientes Modernos',
                      description: 'Efeitos de gradiente bonitos com cores personalizáveis',
                      isDark: isDark,
                    ),
                    _buildFeatureItem(
                      icon: Icons.blur_on,
                      title: 'Glassmorfismo',
                      description: 'Efeitos premium tipo vidro com transparência sutil',
                      isDark: isDark,
                    ),
                    _buildFeatureItem(
                      icon: Icons.animation,
                      title: 'Animações Suaves',
                      description: 'Múltiplas camadas de animação para sensação premium',
                      isDark: isDark,
                    ),
                    _buildFeatureItem(
                      icon: Icons.palette,
                      title: 'Suporte a Temas',
                      description: 'Adaptação automática para temas claro e escuro',
                      isDark: isDark,
                    ),
                    _buildFeatureItem(
                      icon: Icons.account_balance_wallet,
                      title: 'Contexto de Transação',
                      description: 'Ícone de carteira e mensagens específicas para transações',
                      isDark: isDark,
                    ),
                    _buildFeatureItem(
                      icon: Icons.fit_screen,
                      title: 'Design Responsivo',
                      description: 'Adapta-se a diferentes tamanhos de tela e orientações',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Usage Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como Usar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        '''// Uso básico
TransactionLoader(
  message: "Processando sua transação...",
)

// Configuração personalizada
TransactionLoader(
  message: "Salvando dados da transação...",
  size: 100.0,
  primaryColor: Color(0xFF6366F1),
  secondaryColor: Color(0xFF8B5CF6),
  showPulseEffect: true,
  animationDuration: Duration(milliseconds: 2000),
)

// Versão compacta
CompactTransactionLoader(
  message: "Carregando...",
  size: 20.0,
)''',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: isDark ? Colors.green[300] : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSection({
    required String title,
    required String description,
    required bool isActive,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive 
                        ? Colors.red 
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isActive ? 'Ocultar' : 'Mostrar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

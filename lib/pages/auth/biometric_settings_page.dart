import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/biometric_auth_provider.dart';
import '../../services/biometric_auth_service.dart';

/// Tela de configuração da autenticação biométrica
/// Permite habilitar/desabilitar e configurar timeout
class BiometricSettingsPage extends StatefulWidget {
  const BiometricSettingsPage({super.key});

  @override
  State<BiometricSettingsPage> createState() => _BiometricSettingsPageState();
}

class _BiometricSettingsPageState extends State<BiometricSettingsPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeBiometric();
  }

  /// Inicializa o provider de autenticação biométrica
  Future<void> _initializeBiometric() async {
    setState(() => _isLoading = true);
    
    try {
      await context.read<BiometricAuthProvider>().initialize();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao inicializar autenticação biométrica: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticação Biométrica'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<BiometricAuthProvider>(
              builder: (context, biometricProvider, child) {
                return RefreshIndicator(
                  onRefresh: _initializeBiometric,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(biometricProvider),
                        const SizedBox(height: 16),
                        if (biometricProvider.isDeviceSupported) ...[
                          _buildBiometricToggleCard(biometricProvider),
                          const SizedBox(height: 16),
                          if (biometricProvider.isBiometricEnabled) ...[
                            _buildTimeoutCard(biometricProvider),
                            const SizedBox(height: 16),
                            _buildSecurityCard(biometricProvider),
                            const SizedBox(height: 16),
                          ],
                        ],
                        _buildInfoCard(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Card com status atual da autenticação biométrica
  Widget _buildStatusCard(BiometricAuthProvider provider) {
    IconData statusIcon;
    String statusText;
    Color statusColor;

    switch (provider.state) {
      case BiometricAuthState.available:
        statusIcon = Icons.check_circle;
        statusText = 'Disponível';
        statusColor = Colors.green;
        break;
      case BiometricAuthState.notAvailable:
        statusIcon = Icons.error;
        statusText = 'Não disponível';
        statusColor = Colors.red;
        break;
      case BiometricAuthState.authenticated:
        statusIcon = Icons.verified_user;
        statusText = 'Autenticado';
        statusColor = Colors.blue;
        break;
      case BiometricAuthState.error:
        statusIcon = Icons.warning;
        statusText = 'Erro';
        statusColor = Colors.orange;
        break;
      default:
        statusIcon = Icons.help;
        statusText = 'Verificando...';
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Status: $statusText',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
            if (provider.availableBiometrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Tipos disponíveis:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: provider.getAvailableBiometricDescriptions()
                    .map((description) => Chip(
                          label: Text(description),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card para habilitar/desabilitar autenticação biométrica
  Widget _buildBiometricToggleCard(BiometricAuthProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Habilitar Autenticação Biométrica',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: provider.isBiometricEnabled,
                  onChanged: provider.isLoading ? null : _toggleBiometric,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              provider.isBiometricEnabled
                  ? 'A autenticação biométrica está ativa. Você precisará autenticar-se para acessar o aplicativo.'
                  : 'Habilite para usar Face ID, Touch ID ou impressão digital para acessar o aplicativo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card para configurar timeout de autenticação
  Widget _buildTimeoutCard(BiometricAuthProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Timeout de Autenticação',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tempo para solicitar nova autenticação: ${provider.authTimeoutMinutes} minutos',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Slider(
              value: provider.authTimeoutMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '${provider.authTimeoutMinutes} min',
              onChanged: provider.isLoading ? null : _changeTimeout,
              activeColor: Theme.of(context).primaryColor,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 min', style: Theme.of(context).textTheme.bodySmall),
                Text('60 min', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card com informações de segurança
  Widget _buildSecurityCard(BiometricAuthProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Informações de Segurança',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.lastAuthTime != null) ...[
              _buildInfoRow(
                'Última autenticação:',
                _formatDateTime(provider.lastAuthTime!),
              ),
              const SizedBox(height: 8),
            ],
            _buildInfoRow(
              'Autenticação necessária:',
              provider.needsAuthentication ? 'Sim' : 'Não',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _testBiometric,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Testar Autenticação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card com informações gerais
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Informações',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• A autenticação biométrica usa os recursos de segurança do seu dispositivo\n'
              '• Seus dados biométricos não são armazenados pelo aplicativo\n'
              '• Você pode desabilitar a qualquer momento\n'
              '• Em caso de falha, você pode usar a autenticação tradicional',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para exibir informações em linha
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Alterna o estado da autenticação biométrica
  Future<void> _toggleBiometric(bool enabled) async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<BiometricAuthProvider>();
      final success = await provider.setBiometricEnabled(enabled);
      
      if (success) {
        _showSuccessSnackBar(
          enabled 
              ? 'Autenticação biométrica habilitada com sucesso!'
              : 'Autenticação biométrica desabilitada.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao configurar autenticação: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Altera o timeout de autenticação
  Future<void> _changeTimeout(double value) async {
    try {
      final provider = context.read<BiometricAuthProvider>();
      await provider.setAuthTimeout(value.round());
    } catch (e) {
      _showErrorSnackBar('Erro ao alterar timeout: $e');
    }
  }

  /// Testa a autenticação biométrica
  Future<void> _testBiometric() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<BiometricAuthProvider>();
      final success = await provider.authenticate(
        reason: 'Teste de autenticação biométrica',
      );
      
      if (success) {
        _showSuccessSnackBar('Autenticação realizada com sucesso!');
      }
    } catch (e) {
      _showErrorSnackBar('Erro no teste de autenticação: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Formata data e hora para exibição
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} às '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Exibe SnackBar de sucesso
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Exibe SnackBar de erro
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
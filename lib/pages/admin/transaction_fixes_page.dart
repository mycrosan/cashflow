import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../fixes/transaction_recurring_fixes.dart';

/// Página administrativa para executar correções na lógica de transações e recorrências
class TransactionFixesPage extends StatefulWidget {
  const TransactionFixesPage({super.key});

  @override
  State<TransactionFixesPage> createState() => _TransactionFixesPageState();
}

class _TransactionFixesPageState extends State<TransactionFixesPage> {
  bool _isRunningFixes = false;
  Map<String, dynamic>? _lastResults;
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correções de Transações'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMonthSelector(),
            const SizedBox(height: 24),
            _buildFixesSection(),
            const SizedBox(height: 24),
            if (_lastResults != null) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correções Disponíveis',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta página permite executar correções na lógica de sincronização '
              'entre transações e recorrências.',
            ),
            const SizedBox(height: 16),
            const Text('Problemas corrigidos:'),
            const SizedBox(height: 8),
            ...[
              '• Cache inconsistente entre providers',
              '• Transações órfãs não removidas',
              '• Duplicação de transações recorrentes',
              '• Status de sincronização inconsistente',
              '• Relacionamentos inconsistentes',
            ].map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(item, style: const TextStyle(fontSize: 14)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mês para Correção',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mês selecionado: ${_selectedMonth.month.toString().padLeft(2, '0')}/${_selectedMonth.year}',
                  ),
                ),
                ElevatedButton(
                  onPressed: _isRunningFixes ? null : _selectMonth,
                  child: const Text('Alterar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Executar Correções',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunningFixes ? null : _runAllFixes,
                icon: _isRunningFixes 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.build_circle),
                label: Text(_isRunningFixes 
                  ? 'Executando correções...' 
                  : 'Executar Todas as Correções'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Isso irá executar todas as correções disponíveis para o mês selecionado.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final results = _lastResults!;
    final success = results['success'] == true;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resultados da Última Execução',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (success) ...[
              _buildResultItem('Órfãs removidas', results['orphanedRemoved']),
              _buildResultItem('Duplicatas removidas', results['duplicatesRemoved']),
              _buildResultItem('Status de sync corrigidos', results['syncStatusFixed']),
              _buildResultItem('Relacionamentos validados', results['relationshipsValidated']),
              _buildResultItem('Cache limpo', results['cacheCleared']),
            ],
            if (results['errors'] != null && results['errors'].isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Erros encontrados:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ...results['errors'].map<Widget>((error) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  '• $error',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  Future<void> _runAllFixes() async {
    setState(() {
      _isRunningFixes = true;
      _lastResults = null;
    });

    try {
      final transactionProvider = context.read<TransactionProvider>();
      final results = await transactionProvider.runTransactionRecurringFixes(
        specificMonth: _selectedMonth,
      );

      setState(() {
        _lastResults = results;
      });

      if (results['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Correções executadas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao executar correções: ${results['error'] ?? 'Erro desconhecido'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _lastResults = {
          'success': false,
          'error': e.toString(),
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRunningFixes = false;
      });
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../models/recurring_transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_transaction_provider.dart';

/// Página para visualizar e restaurar itens excluídos (lixeira)
class DeletedItemsPage extends StatefulWidget {
  const DeletedItemsPage({super.key});

  @override
  State<DeletedItemsPage> createState() => _DeletedItemsPageState();
}

class _DeletedItemsPageState extends State<DeletedItemsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Transaction> _deletedTransactions = [];
  List<RecurringTransaction> _deletedRecurringTransactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeletedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeletedItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);

      final deletedTransactions = await transactionProvider.getDeletedTransactions();
      final deletedRecurringTransactions = await recurringProvider.getDeletedRecurringTransactions();

      setState(() {
        _deletedTransactions = deletedTransactions;
        _deletedRecurringTransactions = deletedRecurringTransactions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar itens excluídos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreTransaction(Transaction transaction) async {
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final success = await provider.restoreTransaction(transaction.id!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação restaurada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDeletedItems(); // Recarregar a lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao restaurar transação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao restaurar transação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreRecurringTransaction(RecurringTransaction recurringTransaction) async {
    try {
      final provider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      final success = await provider.restoreRecurringTransaction(recurringTransaction.id!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação recorrente restaurada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDeletedItems(); // Recarregar a lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao restaurar transação recorrente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao restaurar transação recorrente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itens Excluídos'),
        backgroundColor: Colors.red.shade100,
        foregroundColor: Colors.red.shade800,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade800,
          unselectedLabelColor: Colors.red.shade400,
          indicatorColor: Colors.red.shade800,
          tabs: const [
            Tab(
              icon: Icon(Icons.receipt_long),
              text: 'Transações',
            ),
            Tab(
              icon: Icon(Icons.repeat),
              text: 'Recorrentes',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeletedItems,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDeletedTransactionsList(),
                _buildDeletedRecurringTransactionsList(),
              ],
            ),
    );
  }

  Widget _buildDeletedTransactionsList() {
    if (_deletedTransactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma transação excluída',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _deletedTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildDeletedRecurringTransactionsList() {
    if (_deletedRecurringTransactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma transação recorrente excluída',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedRecurringTransactions.length,
      itemBuilder: (context, index) {
        final recurringTransaction = _deletedRecurringTransactions[index];
        return _buildRecurringTransactionCard(recurringTransaction);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            transaction.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responsável: ${transaction.associatedMember.name}'),
            Text('Data: ${dateFormat.format(transaction.date)}'),
            if (transaction.deletedAt != null)
              Text(
                'Excluído em: ${dateFormat.format(transaction.deletedAt!)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(transaction.value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.blue),
              onPressed: () => _restoreTransaction(transaction),
              tooltip: 'Restaurar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringTransactionCard(RecurringTransaction recurringTransaction) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: recurringTransaction.isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            Icons.repeat,
            color: recurringTransaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          recurringTransaction.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responsável: ${recurringTransaction.associatedMember.name}'),
            Text('Frequência: ${recurringTransaction.frequencyLabel}'),
            Text('Início: ${dateFormat.format(recurringTransaction.startDate)}'),
            if (recurringTransaction.deletedAt != null)
              Text(
                'Excluído em: ${dateFormat.format(recurringTransaction.deletedAt!)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(recurringTransaction.value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: recurringTransaction.isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.blue),
              onPressed: () => _restoreRecurringTransaction(recurringTransaction),
              tooltip: 'Restaurar',
            ),
          ],
        ),
      ),
    );
  }
}
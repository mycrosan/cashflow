import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../providers/sync_provider.dart';
import '../../models/transaction.dart';
import '../../models/recurring_transaction.dart';
import '../../models/recurring_operation_type.dart';
import '../../widgets/transaction_loader.dart';
import '../../widgets/recurring_operation_dialog.dart';
import 'add_transaction_page.dart';

class TransacoesMensaisPage extends StatefulWidget {
  const TransacoesMensaisPage({super.key});

  @override
  _TransacoesMensaisPageState createState() => _TransacoesMensaisPageState();
}

class _TransacoesMensaisPageState extends State<TransacoesMensaisPage> {
  DateTime _selectedMonth = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showIncome = true;
  bool _showExpense = true;
  bool _isLoadingMonth = false;
  bool _isSearchVisible = false;
  


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadMonthData() async {
    try {
      print('Carregando dados para o mês: ${_selectedMonth.month}/${_selectedMonth.year}');
      
      // Não ativar loading aqui, já foi ativado nos métodos de navegação
      
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      print('Providers obtidos com sucesso');
      
      // Usar o novo método que carrega transações com recorrências únicas
      await transactionProvider.loadTransactionsForMonthWithRecurring(_selectedMonth);
      
      print('Transações carregadas: ${transactionProvider.getFilteredTransactionsForMonth(_selectedMonth).length}');
      
    } catch (e) {
      print('Erro ao carregar dados: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Sempre desativar o loading ao final
      setState(() {
        _isLoadingMonth = false;
      });
    }
  }

  // Método para recarregar dados após operações de recorrência
  Future<void> _reloadDataAfterRecurringOperation() async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      print('=== MONTHLY TRANSACTIONS: Recarregando dados após operação de recorrência ===');
      
      // Limpar cache específico do mês atual para forçar recarga
      transactionProvider.clearMonthCacheFor(_selectedMonth);
      
      // Recarregar apenas o mês atual sem refresh completo
      await transactionProvider.loadTransactionsForMonthWithRecurring(_selectedMonth);
      
      print('=== MONTHLY TRANSACTIONS: Dados recarregados com sucesso ===');
      
    } catch (e) {
      print('=== MONTHLY TRANSACTIONS: Erro ao recarregar dados ===');
      print('Erro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao recarregar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Gerar transações recorrentes para o mês selecionado (SIMPLIFICADO)
  Future<void> _generateRecurringTransactionsForMonth() async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      
      print('=== MONTHLY TRANSACTIONS: Gerando recorrências para ${_selectedMonth.month}/${_selectedMonth.year} ===');
      
      // O TransactionProvider agora gerencia automaticamente as recorrências
      // Apenas recarregar os dados para garantir que tudo está atualizado
      await transactionProvider.loadTransactionsForMonthWithRecurring(_selectedMonth);
      
      print('=== MONTHLY TRANSACTIONS: Recorrências processadas com sucesso ===');
      
    } catch (e) {
      print('Erro ao gerar transações recorrentes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar transações recorrentes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previousMonth() {
    final syncProvider = SyncProvider.instance;
    
    if (!syncProvider.canNavigate()) {
      print('Navegação bloqueada pelo SyncProvider');
      return;
    }
    
    syncProvider.startNavigation();
    print('=== MONTHLY TRANSACTIONS: Navegação para mês anterior ===');
    
    // Ativar loading IMEDIATAMENTE
    setState(() {
      _isLoadingMonth = true;
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    
    syncProvider.debounceNavigation(() {
      try {
        _loadMonthData();
        print('=== MONTHLY TRANSACTIONS: Dados do mês anterior carregados com sucesso ===');
      } catch (e) {
        print('=== MONTHLY TRANSACTIONS: Erro ao carregar dados do mês anterior ===');
        print('Erro: $e');
      } finally {
        syncProvider.completeNavigation();
      }
    });
  }

  void _nextMonth() {
    final syncProvider = SyncProvider.instance;
    
    if (!syncProvider.canNavigate()) {
      print('Navegação bloqueada pelo SyncProvider');
      return;
    }
    
    syncProvider.startNavigation();
    print('=== MONTHLY TRANSACTIONS: Navegação para próximo mês ===');
    
    // Ativar loading IMEDIATAMENTE
    setState(() {
      _isLoadingMonth = true;
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    
    syncProvider.debounceNavigation(() {
      try {
        _loadMonthData();
        print('=== MONTHLY TRANSACTIONS: Dados do próximo mês carregados com sucesso ===');
      } catch (e) {
        print('=== MONTHLY TRANSACTIONS: Erro ao carregar dados do próximo mês ===');
        print('Erro: $e');
      } finally {
        syncProvider.completeNavigation();
      }
    });
  }

  void _goToCurrentMonth() {
    final syncProvider = SyncProvider.instance;
    
    if (!syncProvider.canNavigate()) {
      print('Navegação bloqueada pelo SyncProvider');
      return;
    }
    
    syncProvider.startNavigation();
    print('=== MONTHLY TRANSACTIONS: Navegação para mês atual ===');
    
    // Ativar loading IMEDIATAMENTE
    setState(() {
      _isLoadingMonth = true;
      _selectedMonth = DateTime.now();
    });
    
    syncProvider.debounceNavigation(() {
      try {
        _loadMonthData();
        print('=== MONTHLY TRANSACTIONS: Dados do mês atual carregados com sucesso ===');
      } catch (e) {
        print('=== MONTHLY TRANSACTIONS: Erro ao carregar dados do mês atual ===');
        print('Erro: $e');
      } finally {
        syncProvider.completeNavigation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: _isSearchVisible 
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar transações...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                autofocus: true,
              )
            : Row(
                children: [
                  // Botão mês anterior
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _isLoadingMonth ? null : _previousMonth,
                    tooltip: 'Mês Anterior',
                  ),
                  // Título com mês/ano
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Botão próximo mês
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _isLoadingMonth ? null : _nextMonth,
                    tooltip: 'Próximo Mês',
                  ),
                ],
              ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // Botão de pesquisa
            IconButton(
              icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
              tooltip: _isSearchVisible ? 'Fechar Pesquisa' : 'Pesquisar',
            ),
            // Botão mês atual
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: _isLoadingMonth ? null : _goToCurrentMonth,
              tooltip: 'Mês Atual',
            ),
          ],
        ),
        body: _isLoadingMonth
            ? TransactionLoader(
                message: "Carregando transações do mês...",
                size: 120.0,
                primaryColor: Theme.of(context).colorScheme.primary,
                secondaryColor: Theme.of(context).colorScheme.secondary,
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Saldo do mês
                    _buildMonthBalance(),
                    
                    // Lista de transações
                    _buildTransactionsList(),
                  ],
                ),
              ),
    );
  }


  Widget _buildMonthBalance() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        // Se está carregando o mês, não mostra dados
        if (_isLoadingMonth) {
          return SizedBox(
            height: 150,
            child: Center(
              child: Text(
                'Calculando saldo...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }
        
        final transactions = provider.getFilteredTransactionsForMonth(_selectedMonth);
        
        // Cálculos separados para receitas e despesas pagas/pendentes
        double totalIncomePaid = 0;
        double totalIncomePending = 0;
        double totalExpensePaid = 0;
        double totalExpensePending = 0;
        
        print('=== MONTHLY TRANSACTIONS: Calculando saldo para ${_selectedMonth.month}/${_selectedMonth.year} ===');
        print('Total de transações para cálculo: ${transactions.length}');
        
        for (final transaction in transactions) {
          print('Transação: ${transaction.category} - Valor: ${transaction.value} - Paga: ${transaction.isPaid}');
          
          if (transaction.value > 0) {
            // Receita
            if (transaction.isPaid) {
              totalIncomePaid += transaction.value;
              print('Receita paga adicionada: ${transaction.value}');
            } else {
              totalIncomePending += transaction.value;
              print('Receita pendente adicionada: ${transaction.value}');
            }
          } else {
            // Despesa
            if (transaction.isPaid) {
              totalExpensePaid += transaction.value.abs();
              print('Despesa paga adicionada: ${transaction.value.abs()}');
            } else {
              totalExpensePending += transaction.value.abs();
              print('Despesa pendente adicionada: ${transaction.value.abs()}');
            }
          }
        }
        
        print('Totais calculados:');
        print('- Receitas pagas: $totalIncomePaid');
        print('- Receitas pendentes: $totalIncomePending');
        print('- Despesas pagas: $totalExpensePaid');
        print('- Despesas pendentes: $totalExpensePending');
        
        final totalIncome = totalIncomePaid + totalIncomePending;
        final totalExpense = totalExpensePaid + totalExpensePending;
        final balancePaid = totalIncomePaid - totalExpensePaid; // Saldo apenas dos pagos
        final balancePending = totalIncomePending - totalExpensePending; // Saldo pendente
        final balanceTotal = balancePaid + balancePending; // Saldo total
        
        print('Saldo final calculado:');
        print('- Saldo pago: $balancePaid');
        print('- Saldo pendente: $balancePending');
        print('- Saldo total: $balanceTotal');
        print('- Total receitas: $totalIncome');
        print('- Total despesas: $totalExpense');
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saldo principal
                Center(
                  child: Text(
                    'Saldo: ${_formatCurrency(balanceTotal)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: balanceTotal >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Resumo detalhado
                Row(
                  children: [
                    // Receitas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showIncome = !_showIncome;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _showIncome ? Colors.green.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _showIncome ? Colors.green : Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Receitas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (_showIncome) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recebidas:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            _formatCurrency(totalIncomePaid),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          if (totalIncomePending > 0) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Falta receber:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalIncomePending),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Despesas
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showExpense = !_showExpense;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _showExpense ? Colors.red.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _showExpense ? Colors.red : Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Despesas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                  if (_showExpense) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pagas:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                          Text(
                            _formatCurrency(totalExpensePaid),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          if (totalExpensePending > 0) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Falta pagar:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalExpensePending),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildTransactionsList() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        // Se está carregando o mês, não mostra nada (já está sendo mostrado o loader em tela cheia)
        if (_isLoadingMonth) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Aguarde o carregamento...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }
        
        if (provider.isLoading) {
          return SizedBox(
            height: 200,
            child: const TransactionLoader(
              message: "Carregando transações...",
              size: 80.0,
            ),
          );
        }

        if (provider.error != null) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro: ${provider.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadMonthData(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = provider.getFilteredTransactionsForMonth(_selectedMonth);
        final filteredTransactions = _filterTransactions(transactions);

        if (filteredTransactions.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma transação encontrada',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione transações ou verifique os filtros',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transações (${filteredTransactions.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...filteredTransactions.map((transaction) => _buildTransactionItem(transaction)),
          ],
        );
      },
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((transaction) {
      // Filtro por tipo
      if (transaction.value > 0 && !_showIncome) return false;
      if (transaction.value < 0 && !_showExpense) return false;
      
      // Filtro por busca
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = 
          transaction.category.toLowerCase().contains(query) ||
          (transaction.notes?.toLowerCase().contains(query) ?? false) ||
          transaction.associatedMember.name.toLowerCase().contains(query);
        
        if (!matchesSearch) return false;
      }
      
      return true;
    }).toList();
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.value > 0;
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: () => _showTransactionEditMode(transaction),
        onLongPress: () => _showTransactionOptions(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Informações principais - organizadas em 2 linhas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Linha 1: Categoria + Status badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badges compactos
                        if (transaction.isPaid) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Pago',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (transaction.recurringTransactionId != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Recorrente',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    
                    // Linha 2: ID + Responsável + Data
                    Text(
                      'ID: ${transaction.id} • ${transaction.associatedMember.name} • ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Status de pagamento e valor - lado direito compacto
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone de status de pagamento - menor
                  GestureDetector(
                    onTap: () => _togglePaymentStatus(transaction),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: transaction.isPaid 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        transaction.isPaid 
                          ? Icons.check_circle
                          : Icons.pending,
                        color: transaction.isPaid 
                          ? Colors.green
                          : Colors.orange,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Valor - menor
                  Text(
                    _formatCurrency(transaction.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    ).format(value);
  }

  void _showTransactionEditMode(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              transaction.value > 0 ? Icons.trending_up : Icons.trending_down,
              color: transaction.value > 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Editar Transação'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações da transação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoria: ${transaction.category}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Valor: ${_formatCurrency(transaction.value)}'),
                    Text('Membro: ${transaction.associatedMember.name}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                    if (transaction.notes != null) Text('Observações: ${transaction.notes}'),
                    if (transaction.recurringTransactionId != null) 
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Transação Recorrente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Escolha uma ação:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTransactionDialog(transaction);
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          if (transaction.recurringTransactionId != null)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                _showRecurringDeleteOptions(transaction);
              },
              icon: const Icon(Icons.delete),
              tooltip: 'Remover',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            )
          else
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(transaction);
              },
              icon: const Icon(Icons.delete),
              tooltip: 'Remover',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showTransactionOptions(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              _showEditTransactionDialog(transaction);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Excluir', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(transaction);
            },
          ),
        ],
      ),
    );
  }


  void _showAddTransactionDialog(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionPage(),
      ),
    );
    
    if (result == true) {
      _loadMonthData();
    }
  }

  void _togglePaymentStatus(Transaction transaction) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    if (transaction.isPaid) {
      // Se está pago, marcar como não pago
      await transactionProvider.markTransactionAsUnpaid(transaction.id!);
    } else {
      // Se não está pago, mostrar opções de pagamento
      await _showPaymentDateDialog(transaction);
    }
  }

  Future<void> _showPaymentDateDialog(Transaction transaction) async {
    DateTime? selectedDate = DateTime.now();
    
    // Determinar se é receita ou despesa
    final isIncome = transaction.isIncome;
    final title = isIncome ? 'Data de Recebimento' : 'Data de Pagamento';
    final description = isIncome ? 'Selecione a data do recebimento:' : 'Selecione a data do pagamento:';
    final todayButtonText = isIncome ? 'Receber Hoje' : 'Pagar Hoje';
    
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(description),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  selectedDate = date;
                  Navigator.of(context).pop(date);
                }
              },
              child: const Text('Selecionar Data'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(DateTime.now());
              },
              child: Text(todayButtonText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (result != null) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.markTransactionAsPaid(
        transaction.id!,
        paidDate: result,
      );
    }
  }

  void _showEditTransactionDialog(Transaction transaction) async {
    // Se é uma transação recorrente, mostrar diálogo de opções
    if (transaction.recurringTransactionId != null) {
      try {
        final operationType = await showDialog<RecurringOperationType>(
           context: context,
           builder: (context) => RecurringOperationDialog(
             transaction: transaction,
             operationType: 'edit',
           ),
         );
        
        if (operationType != null && mounted) {
          await _handleRecurringEdit(transaction, operationType);
        }
      } catch (e) {
        print('Erro ao editar transação recorrente: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao editar transação recorrente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Transação normal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTransactionPage(
            transactionToEdit: transaction,
          ),
        ),
      ).then((_) {
        _loadMonthData();
      });
    }
  }

  Future<void> _handleRecurringEdit(Transaction transaction, RecurringOperationType operationType) async {
    try {
      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      
      switch (operationType) {
        case RecurringOperationType.thisOnly:
          // Editar apenas esta transação - usar método específico do provider
          // Primeiro, navegar para edição normal para obter os novos dados
          final result = await Navigator.push<Transaction>(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(
                transactionToEdit: transaction,
              ),
            ),
          );
          
          if (result != null && mounted) {
            // Usar o método específico para editar apenas esta transação
            final success = await recurringProvider.editSingleRecurringTransaction(
              originalTransaction: transaction,
              updatedTransaction: result,
            );
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transação editada com sucesso!')),
              );
              _loadMonthData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: ${recurringProvider.error}')),
              );
            }
          }
          break;
          
        case RecurringOperationType.thisAndFuture:
          // Editar esta e futuras - buscar recorrência e navegar para edição
          await recurringProvider.loadRecurringTransactions();
          
          final recurringTransaction = recurringProvider.recurringTransactions.firstWhere(
            (rt) => rt.id == transaction.recurringTransactionId,
            orElse: () => throw Exception('Transação recorrente não encontrada'),
          );
          
          if (mounted) {
            final result = await Navigator.push<Transaction>(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransactionPage(
                  transactionToEdit: transaction,
                ),
              ),
            );
            
            if (result != null && mounted) {
              // Usar o método específico para editar esta e futuras transações
              final success = await recurringProvider.editThisAndFutureRecurringTransactions(
                originalTransaction: transaction,
                updatedTransaction: result,
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transação atual e futuras editadas com sucesso!')),
                );
                _loadMonthData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: ${recurringProvider.error}')),
                );
              }
            }
          }
          break;
          
        case RecurringOperationType.allOccurrences:
          // Editar todas as ocorrências - buscar recorrência e navegar para edição
          await recurringProvider.loadRecurringTransactions();
          
          final recurringTransaction = recurringProvider.recurringTransactions.firstWhere(
            (rt) => rt.id == transaction.recurringTransactionId,
            orElse: () => throw Exception('Transação recorrente não encontrada'),
          );
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransactionPage(
                  recurringTransactionToEdit: recurringTransaction,
                ),
              ),
            ).then((_) {
              _loadMonthData();
            });
          }
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao editar transação: $e')),
      );
    }
  }

  void _showRecurringDeleteOptions(Transaction transaction) async {
    print('🔄 DEBUG: _showRecurringDeleteOptions chamada');
    print('🔄 DEBUG: Transaction ID: ${transaction.id}');
    print('🔄 DEBUG: Recurring ID: ${transaction.recurringTransactionId}');
    print('🔄 DEBUG: Category: ${transaction.category}');
    print('🔄 DEBUG: Value: ${transaction.value}');
    print('🔄 DEBUG: Date: ${transaction.date}');
    
    try {
      final operationType = await showDialog<RecurringOperationType>(
        context: context,
        builder: (context) => RecurringOperationDialog(
          transaction: transaction,
          operationType: 'delete',
          showAllOccurrencesOption: true, // Mostrar opção de exclusão completa
        ),
      );
      
      if (operationType != null && mounted) {
        await _handleRecurringDelete(transaction, operationType);
      }
    } catch (e) {
      print('Erro ao excluir transação recorrente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir transação recorrente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRecurringDelete(Transaction transaction, RecurringOperationType operationType) async {
    try {
      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      
      switch (operationType) {
        case RecurringOperationType.thisOnly:
          // Excluir apenas esta transação (soft delete)
          print('🔄 DEBUG: Excluindo apenas esta transação');
          final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
          final success = await transactionProvider.deleteTransaction(transaction.id!);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transação removida com sucesso!')),
            );
            _loadMonthData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao remover transação')),
            );
          }
          break;
          
        case RecurringOperationType.thisAndFuture:
          // Excluir esta e futuras transações
          print('🔄 DEBUG: Excluindo transação atual e futuras');
          if (transaction.recurringTransactionId != null) {
            final success = await recurringProvider.deleteCurrentAndFutureTransactions(
              transaction.recurringTransactionId!,
              transaction.date,
            );
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transação atual e futuras removidas com sucesso!')),
              );
              _loadMonthData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: ${recurringProvider.error}')),
              );
            }
          }
          break;
          
        case RecurringOperationType.allOccurrences:
          // Excluir completamente a recorrência (hard delete)
          print('🔄 DEBUG: Excluindo recorrência completamente');
          if (transaction.recurringTransactionId != null) {
            final success = await recurringProvider.deleteRecurringTransaction(transaction.recurringTransactionId!);
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recorrência removida completamente!')),
              );
              _loadMonthData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: ${recurringProvider.error}')),
              );
            }
          }
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir transação: $e')),
      );
    }
  }

  void _showOldRecurringDeleteOptions(Transaction transaction) {
    print('🔄 DEBUG: _showOldRecurringDeleteOptions chamada');
    print('🔄 DEBUG: Transaction ID: ${transaction.id}');
    print('🔄 DEBUG: Recurring ID: ${transaction.recurringTransactionId}');
    print('🔄 DEBUG: Category: ${transaction.category}');
    print('🔄 DEBUG: Value: ${transaction.value}');
    print('🔄 DEBUG: Date: ${transaction.date}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Remover'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta é uma transação recorrente. Escolha como deseja removê-la:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transação: ${transaction.category}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Valor: ${_formatCurrency(transaction.value)}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Opções de remoção:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              print('🔄 DEBUG: Usuário escolheu "Apenas este"');
              Navigator.pop(context);
              _deleteSingleTransaction(transaction);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Apenas este'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              print('🔄 DEBUG: Usuário escolheu "Este e futuros"');
              Navigator.pop(context);
              _deleteRecurringTransaction(transaction);
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Este e futuros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Transaction transaction) {
    print('🗑️ DEBUG: _showDeleteConfirmation chamada');
    print('🗑️ DEBUG: Transaction ID: ${transaction.id}');
    print('🗑️ DEBUG: Category: ${transaction.category}');
    print('🗑️ DEBUG: Value: ${transaction.value}');
    print('🗑️ DEBUG: Date: ${transaction.date}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir esta transação?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transação: ${transaction.category}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Valor: ${_formatCurrency(transaction.value)}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          IconButton(
            onPressed: () {
              print('🗑️ DEBUG: Usuário confirmou exclusão');
              Navigator.pop(context);
              _deleteSingleTransaction(transaction);
            },
            icon: const Icon(Icons.delete),
            tooltip: 'Excluir',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSingleTransaction(Transaction transaction) async {
    print('🔥 DEBUG: _deleteSingleTransaction iniciada');
    print('🔥 DEBUG: Transaction ID: ${transaction.id}');
    print('🔥 DEBUG: Recurring ID: ${transaction.recurringTransactionId}');
    
    try {
      bool success = false;
      
      // Se é uma transação recorrente, usar o método específico para não afetar a recorrência
      if (transaction.recurringTransactionId != null) {
        final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        success = await recurringProvider.deleteSingleRecurringTransaction(
          transaction.id!, 
          transactionProvider: transactionProvider
        );
        print('Removendo apenas esta transação recorrente: ${transaction.category} - ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}');
      } else {
        // Se não é recorrente, usar o método normal
        final provider = Provider.of<TransactionProvider>(context, listen: false);
        success = await provider.deleteTransaction(transaction.id!);
        print('Removendo transação normal: ${transaction.category}');
      }
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMonthData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir transação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir transação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRecurringTransaction(Transaction transaction) async {
    try {
      print('=== DEBUG: Iniciando _deleteRecurringTransaction ===');
      print('Transaction ID: ${transaction.id}');
      print('Recurring Transaction ID: ${transaction.recurringTransactionId}');
      print('Transaction Date: ${transaction.date}');
      print('Transaction Category: ${transaction.category}');
      
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      
      // Mostrar diálogo de confirmação final
      print('=== DEBUG: Mostrando diálogo de confirmação ===');
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmação Final'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta ação irá:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Remover esta transação'),
              Text('• Remover todas as transações futuras desta recorrência'),
              Text('• Manter as transações passadas'),
              Text('• Manter a recorrência ativa'),
              SizedBox(height: 16),
              Text(
                'Esta ação não pode ser desfeita!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Confirmar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      print('=== DEBUG: Resultado da confirmação: $confirmed ===');
      if (confirmed != true) {
        print('=== DEBUG: Usuário cancelou a exclusão ===');
        return;
      }

      print('=== DEBUG: Usuário confirmou a exclusão ===');
      print('Iniciando remoção de transação recorrente: ${transaction.category}');
      print('ID da recorrência: ${transaction.recurringTransactionId}');

      // Se é uma transação recorrente, remover apenas esta e futuras transações (mantém as passadas)
      if (transaction.recurringTransactionId != null) {
        print('=== DEBUG: Removendo transação atual e futuras da recorrência... ===');
        
        final recurringDeleteResult = await recurringProvider.deleteCurrentAndFutureTransactions(
          transaction.recurringTransactionId!, 
          transaction.date
        );
        print('=== DEBUG: Resultado da exclusão: $recurringDeleteResult ===');
        if (!recurringDeleteResult) {
          throw Exception('Erro ao remover transações atuais e futuras');
        }
        print('=== DEBUG: Transação atual e futuras removidas com sucesso ===');
      } else {
        // Se não é recorrente, apenas remover a transação atual
        print('=== DEBUG: Removendo transação não recorrente... ===');
        final deleteResult = await transactionProvider.deleteTransaction(transaction.id!);
        print('=== DEBUG: Resultado da exclusão: $deleteResult ===');
        if (!deleteResult) {
          throw Exception('Erro ao remover transação');
        }
        print('=== DEBUG: Transação removida com sucesso ===');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transaction.recurringTransactionId != null 
            ? 'Recorrência e todas as transações associadas foram removidas'
            : 'Transação removida com sucesso'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      await _reloadDataAfterRecurringOperation();
      
    } catch (e) {
      print('Erro ao excluir transação recorrente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir transação recorrente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método legado para compatibilidade
  Future<void> _deleteTransaction(Transaction transaction) async {
    await _deleteSingleTransaction(transaction);
  }
}


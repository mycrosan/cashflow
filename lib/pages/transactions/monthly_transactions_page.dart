import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../providers/sync_provider.dart';
import '../../models/transaction.dart';
import '../../models/recurring_transaction.dart';
import '../../widgets/transaction_loader.dart';
import 'add_transaction_page.dart';

class TransacoesMensaisPage extends StatefulWidget {
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
      
      // Usar o novo método que inclui limpeza de transações órfãs
      await transactionProvider.refresh();
      
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
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar transações...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
            ),
            style: TextStyle(color: Colors.white, fontSize: 16),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: Icon(Icons.today),
              onPressed: _isLoadingMonth ? null : _goToCurrentMonth,
              tooltip: 'Mês Atual',
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _isLoadingMonth ? null : () => _showAddTransactionDialog(context),
              tooltip: 'Adicionar Transação',
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
                    // Controle de meses com setas
                    _buildMonthNavigation(),
                    
                    // Saldo do mês
                    _buildMonthBalance(),
                    
                    // Lista de transações
                    _buildTransactionsList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildMonthNavigation() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: _isLoadingMonth ? null : _previousMonth,
              tooltip: 'Mês Anterior',
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: _isLoadingMonth ? null : _nextMonth,
              tooltip: 'Próximo Mês',
            ),
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
          return Container(
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
          margin: EdgeInsets.symmetric(horizontal: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
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
                
                SizedBox(height: 16),
                
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
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  Text(
                                    'Receitas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (_showIncome) ...[
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pagas:',
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
                            SizedBox(height: 4),
                            Text(
                              'Falta receber:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalIncomePending),
                              style: TextStyle(
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
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  Text(
                                    'Despesas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                  if (_showExpense) ...[
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
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
                            SizedBox(height: 4),
                            Text(
                              'Falta pagar:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalExpensePending),
                              style: TextStyle(
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
          return Container(
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
          return Container(
            height: 200,
            child: TransactionLoader(
              message: "Carregando transações...",
              size: 80.0,
            ),
          );
        }

        if (provider.error != null) {
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro: ${provider.error}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadMonthData(),
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = provider.getFilteredTransactionsForMonth(_selectedMonth);
        final filteredTransactions = _filterTransactions(transactions);

        if (filteredTransactions.isEmpty) {
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma transação encontrada',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transações (${filteredTransactions.length})',
                    style: TextStyle(
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showTransactionEditMode(transaction),
        onLongPress: () => _showTransactionOptions(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Informações principais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoria
                    Text(
                      transaction.category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    
                    // Responsável e data
                    Text(
                      '${transaction.associatedMember.name} • ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Status de pagamento
                    if (transaction.isPaid) ...[
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          transaction.paymentStatus,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    
                    // Badge de recorrente
                    if (transaction.recurringTransactionId != null) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Recorrente',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(width: 12),
              
              // Checkbox e valor
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Ícone de status de pagamento
                  GestureDetector(
                    onTap: () => _togglePaymentStatus(transaction),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: transaction.isPaid 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        transaction.isPaid 
                          ? Icons.check_circle
                          : Icons.pending,
                        color: transaction.isPaid 
                          ? Colors.green
                          : Colors.orange,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Valor
                  Text(
                    _formatCurrency(transaction.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
            SizedBox(width: 8),
            Text('Editar Transação'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações da transação
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoria: ${transaction.category}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Valor: ${_formatCurrency(transaction.value)}'),
                    Text('Membro: ${transaction.associatedMember.name}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                    if (transaction.notes != null) Text('Observações: ${transaction.notes}'),
                    if (transaction.recurringTransactionId != null) 
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
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
            SizedBox(height: 16),
            Text(
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
            child: Text('Cancelar'),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTransactionDialog(transaction);
            },
            icon: Icon(Icons.edit),
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
              icon: Icon(Icons.delete),
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
              icon: Icon(Icons.delete),
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
            leading: Icon(Icons.edit),
            title: Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              _showEditTransactionDialog(transaction);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Excluir', style: TextStyle(color: Colors.red)),
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
        builder: (context) => AddTransactionPage(),
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
    
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Data de Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecione a data do pagamento:'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(Duration(days: 30)),
                );
                if (date != null) {
                  selectedDate = date;
                  Navigator.of(context).pop(date);
                }
              },
              child: Text('Selecionar Data'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(DateTime.now());
              },
              child: Text('Pagar Hoje'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
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

  void _showEditTransactionDialog(Transaction transaction) {
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

  void _showRecurringDeleteOptions(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Remover Transação Recorrente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta é uma transação recorrente. Escolha como deseja removê-la:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transação: ${transaction.category}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Valor: ${_formatCurrency(transaction.value)}'),
                    Text('Data: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
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
            child: Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteSingleTransaction(transaction);
            },
            icon: Icon(Icons.delete_outline),
            label: Text('Apenas este'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecurringTransaction(transaction);
            },
            icon: Icon(Icons.delete_forever),
            label: Text('Este e futuros'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
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
            Text(
              'Tem certeza que deseja excluir esta transação?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transação: ${transaction.category}',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
            child: Text('Cancelar'),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSingleTransaction(transaction);
            },
            icon: Icon(Icons.delete),
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
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final success = await provider.deleteTransaction(transaction.id!);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transação excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMonthData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final recurringProvider = Provider.of<RecurringTransactionProvider>(context, listen: false);
      
      // Mostrar diálogo de confirmação final
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmação Final'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta ação irá:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Remover esta transação'),
              Text('• Remover a recorrência associada'),
              Text('• Remover todas as transações futuras desta recorrência'),
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
              child: Text('Cancelar'),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(Icons.delete_forever),
              tooltip: 'Confirmar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      print('Iniciando remoção de transação recorrente: ${transaction.category}');
      print('ID da recorrência: ${transaction.recurringTransactionId}');

      // Remover a transação atual
      final deleteResult = await transactionProvider.deleteTransaction(transaction.id!);
      if (!deleteResult) {
        throw Exception('Erro ao remover transação atual');
      }
      print('Transação atual removida com sucesso');
      
      // Se é uma transação recorrente, remover a recorrência
      if (transaction.recurringTransactionId != null) {
        // Recarregar recorrências para garantir que temos os dados mais atualizados
        await recurringProvider.loadRecurringTransactions();
        
        // Encontrar a recorrência
        final recurringTransactions = recurringProvider.recurringTransactions;
        print('Recorrências disponíveis: ${recurringTransactions.length}');
        print('IDs das recorrências: ${recurringTransactions.map((rt) => rt.id).toList()}');
        
        RecurringTransaction? recurringTransaction;
        try {
          recurringTransaction = recurringTransactions.firstWhere(
            (rt) => rt.id == transaction.recurringTransactionId,
          );
        } catch (e) {
          print('Recorrência não encontrada no provider. Tentando remover apenas as transações futuras...');
          recurringTransaction = null;
        }
        
        if (recurringTransaction != null) {
          print('Recorrência encontrada: ${recurringTransaction.category}');
          
          // Remover todas as transações futuras desta recorrência primeiro
          final allTransactions = transactionProvider.transactions;
          final futureTransactions = allTransactions.where(
            (t) => t.recurringTransactionId == transaction.recurringTransactionId &&
                   t.date.isAfter(transaction.date)
          ).toList();
          
          print('Transações futuras encontradas: ${futureTransactions.length}');
          
          for (final futureTransaction in futureTransactions) {
            print('Removendo transação futura: ${futureTransaction.category} - ${DateFormat('dd/MM/yyyy').format(futureTransaction.date)}');
            await transactionProvider.deleteTransaction(futureTransaction.id!);
          }
          
          // Remover a recorrência
          final recurringDeleteResult = await recurringProvider.deleteRecurringTransaction(recurringTransaction.id!);
          if (!recurringDeleteResult) {
            throw Exception('Erro ao remover recorrência');
          }
          print('Recorrência removida com sucesso');
        } else {
          // Se a recorrência não foi encontrada, apenas remover as transações futuras
          print('Recorrência não encontrada, removendo apenas transações futuras...');
          
          final allTransactions = transactionProvider.transactions;
          final futureTransactions = allTransactions.where(
            (t) => t.recurringTransactionId == transaction.recurringTransactionId &&
                   t.date.isAfter(transaction.date)
          ).toList();
          
          print('Transações futuras encontradas: ${futureTransactions.length}');
          
          for (final futureTransaction in futureTransactions) {
            print('Removendo transação futura: ${futureTransaction.category} - ${DateFormat('dd/MM/yyyy').format(futureTransaction.date)}');
            await transactionProvider.deleteTransaction(futureTransaction.id!);
          }
          
          // Tentar remover a recorrência diretamente do banco se ela existir
          try {
            await recurringProvider.deleteRecurringTransaction(transaction.recurringTransactionId!);
            print('Recorrência removida diretamente do banco');
          } catch (e) {
            print('Recorrência já não existe no banco: $e');
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transação recorrente e todas as futuras foram removidas'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
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


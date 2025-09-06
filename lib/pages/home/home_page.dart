import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/transaction_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/quick_entry_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/loading_skeleton.dart';

import '../transactions/add_transaction_page.dart';
import '../transactions/monthly_transactions_page.dart';
import '../reports/reports_page.dart';
import '../members/members_page.dart';
import '../categories/categories_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoadingMonth = false;

  @override
  void initState() {
    super.initState();
    // Inicializar dados quando a página carregar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }



  Future<void> _initializeData() async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      final reportProvider = context.read<ReportProvider>();
      final quickEntryProvider = context.read<QuickEntryProvider>();
      
      print('Inicializando dados da tela inicial...');
      
      // Inicializar dados sequencialmente para evitar condições de corrida
      await transactionProvider.initialize();
      await reportProvider.generateMonthlyReport(_selectedMonth);
      await quickEntryProvider.loadRecentTransactions();
      
      print('Dados da tela inicial inicializados com sucesso');
    } catch (e) {
      print('Erro ao inicializar dados da tela inicial: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fluxo Família'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              // TODO: Implementar sincronização
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sincronização em desenvolvimento')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configurações'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Relatórios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Membros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorias',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return TransacoesMensaisPage();
      case 2:
        return ReportsPage();
      case 3:
        return MembersPage();
      case 4:
        return CategoriesPage();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Consumer2<TransactionProvider, ReportProvider>(
        builder: (context, transactionProvider, reportProvider, child) {
          if (transactionProvider.isLoading || reportProvider.isLoading) {
            return const HomePageSkeleton();
          }

          if (transactionProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro: ${transactionProvider.error}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refreshData(),
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refreshData(),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do mês
                  _buildMonthHeader(),
                  SizedBox(height: 24),
                  
                  
                  // Resumo financeiro
                  _buildFinancialSummary(),
                  SizedBox(height: 24),
                  
                  // Ações rápidas
                  _buildQuickActions(),
                ],
              ),
            ),
          );
        },
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: _isLoadingMonth ? null : () => _previousMonth(),
        ),
        Expanded(
          child: Center(
            child: _isLoadingMonth 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Carregando...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                )
              : Text(
                  DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: _isLoadingMonth ? null : () => _nextMonth(),
        ),
      ],
    );
  }


  Widget _buildFinancialSummary() {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        // Log para debug
        print('=== CONSUMER REPORT PROVIDER ===');
        print('Receitas: ${reportProvider.totalIncome}');
        print('Despesas: ${reportProvider.totalExpense}');
        print('Saldo: ${reportProvider.balance}');
        print('Loading: ${reportProvider.isLoading}');
        print('Error: ${reportProvider.error}');
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo do Mês',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Receitas',
                        reportProvider.totalIncome,
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryItem(
                        'Despesas',
                        reportProvider.totalExpense,
                        Colors.red,
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      reportProvider.formatCurrency(reportProvider.balance),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: reportProvider.balance >= 0 ? Colors.green : Colors.red,
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

  Widget _buildSummaryItem(String label, double value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
            decimalDigits: 2,
          ).format(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

 



  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Adicionar Receita',
                    Icons.add_circle,
                    Colors.green,
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTransactionPage()),
                      );
                      
                      // Se retornou com sucesso, atualizar dados
                      if (result == true) {
                        await _refreshData();
                      }
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Adicionar Despesa',
                    Icons.remove_circle,
                    Colors.red,
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTransactionPage()),
                      );
                      
                      // Se retornou com sucesso, atualizar dados
                      if (result == true) {
                        await _refreshData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        // TODO: Implementar página de perfil
        break;
      case 'settings':
        // TODO: Implementar configurações
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sair'),
        content: Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _previousMonth() {
    final syncProvider = SyncProvider.instance;
    
    if (!syncProvider.canNavigate()) {
      print('Navegação bloqueada pelo SyncProvider');
      return;
    }
    
    syncProvider.startNavigation();
    print('=== HOME: Navegação para mês anterior ===');
    
    // Ativar loading IMEDIATAMENTE
    setState(() {
      _isLoadingMonth = true;
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    
    syncProvider.debounceNavigation(() async {
      try {
        await _refreshMonthData();
        print('=== HOME: Dados do mês anterior carregados com sucesso ===');
      } catch (e) {
        print('=== HOME: Erro ao carregar dados do mês anterior ===');
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
    print('=== HOME: Navegação para próximo mês ===');
    
    // Ativar loading IMEDIATAMENTE
    setState(() {
      _isLoadingMonth = true;
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    
    syncProvider.debounceNavigation(() async {
      try {
        await _refreshMonthData();
        print('=== HOME: Dados do próximo mês carregados com sucesso ===');
      } catch (e) {
        print('=== HOME: Erro ao carregar dados do próximo mês ===');
        print('Erro: $e');
      } finally {
        syncProvider.completeNavigation();
      }
    });
  }

  Future<void> _refreshMonthData() async {
    try {
      print('=== HOME: Atualizando dados do mês ${_selectedMonth.month}/${_selectedMonth.year} ===');
      
      // Não ativar loading aqui, já foi ativado nos métodos de navegação
      
      // Usar o método melhorado que inclui recorrências únicas
      await context.read<ReportProvider>().generateMonthlyReport(_selectedMonth);
      
      print('=== HOME: Dados do mês atualizados com sucesso ===');
    } catch (e) {
      print('=== HOME: Erro ao atualizar dados do mês ===');
      print('Erro: $e');
    } finally {
      // Sempre desativar o loading ao final
      setState(() {
        _isLoadingMonth = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final reportProvider = context.read<ReportProvider>();
    final quickEntryProvider = context.read<QuickEntryProvider>();
    
    try {
      print('=== HOME: INICIANDO ATUALIZAÇÃO DA TELA INICIAL ===');
      print('Mês selecionado: ${_selectedMonth.month}/${_selectedMonth.year}');
      
      // Usar os novos métodos que evitam duplicação de recorrências
      await transactionProvider.refresh();
      await reportProvider.generateMonthlyReport(_selectedMonth);
      await quickEntryProvider.loadRecentTransactions();
      
      print('=== HOME: Todas as operações concluídas ===');
      print('Transações carregadas: ${transactionProvider.transactions.length}');
      print('Transações filtradas do mês: ${transactionProvider.getFilteredTransactionsForMonth(_selectedMonth).length}');
      print('Relatório gerado para: ${reportProvider.totalIncome} receitas, ${reportProvider.totalExpense} despesas');
      
      // Forçar atualização da UI
      if (mounted) {
        setState(() {});
        print('UI atualizada com setState()');
      }
      
      print('=== HOME: ATUALIZAÇÃO DA TELA INICIAL CONCLUÍDA ===');
    } catch (e) {
      print('=== HOME: Erro ao atualizar dados da tela inicial ===');
      print('Erro: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/transaction_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/quick_entry_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/database_service.dart';
import '../../models/transaction.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/draggable_fab.dart';

import '../transactions/add_transaction_page.dart';
import '../transactions/monthly_transactions_page.dart';
import '../reports/reports_page.dart';
import '../members/members_page.dart';
import '../categories/categories_page.dart';
import '../profile/profile_page.dart';
import '../backup/backup_page.dart';
import '../../widgets/transaction_loader.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoadingMonth = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicializar dados quando a página carregar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verificar se os providers foram inicializados e forçar atualização se necessário
    if (!_isInitialLoading) {
      final transactionProvider = context.read<TransactionProvider>();
      final reportProvider = context.read<ReportProvider>();
      
      // Se não há dados mas os providers não estão carregando, pode ser que a inicialização não funcionou
      if (transactionProvider.transactions.isEmpty && 
          reportProvider.totalIncome == 0 && 
          reportProvider.totalExpense == 0 &&
          !transactionProvider.isLoading && 
          !reportProvider.isLoading) {
        print('Detectado providers sem dados - tentando reinicializar...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeData();
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Método de debug para verificar transações no banco
  Future<void> _debugDatabaseTransactions() async {
    try {
      final databaseService = context.read<DatabaseService>();
      final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      print('=== DEBUG: Verificando transações no banco ===');
      print('Mês: ${_selectedMonth.month}/${_selectedMonth.year}');
      print('Período: ${startOfMonth.toIso8601String()} até ${endOfMonth.toIso8601String()}');
      
      final transactions = await databaseService.getTransactions(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      
      print('Transações encontradas no banco: ${transactions.length}');
      
      if (transactions.isNotEmpty) {
        print('Primeiras 5 transações:');
        for (int i = 0; i < transactions.length && i < 5; i++) {
          final t = transactions[i];
          print('${i+1}. ${t.category} - ${t.value} - ${t.date.day}/${t.date.month}/${t.date.year}');
        }
      } else {
        print('Nenhuma transação encontrada para este mês');
        
        // Verificar se há transações em outros meses
        final allTransactions = await databaseService.getTransactions();
        print('Total de transações no banco: ${allTransactions.length}');
        
        if (allTransactions.isNotEmpty) {
          print('Transações em outros meses:');
          final monthGroups = <String, List<Transaction>>{};
          for (final t in allTransactions) {
            final monthKey = '${t.date.month}/${t.date.year}';
            monthGroups[monthKey] = (monthGroups[monthKey] ?? [])..add(t);
          }
          
          for (final entry in monthGroups.entries) {
            print('${entry.key}: ${entry.value.length} transações');
          }
        }
      }
      
      print('=== FIM DEBUG ===');
    } catch (e) {
      print('Erro no debug: $e');
    }
  }



  Future<void> _initializeData() async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      final reportProvider = context.read<ReportProvider>();
      final quickEntryProvider = context.read<QuickEntryProvider>();
      final memberProvider = context.read<MemberProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final databaseService = context.read<DatabaseService>();
      final authProvider = context.read<AuthProvider>();
      
      print('Inicializando dados da tela inicial...');
      print('Usuário logado: ${authProvider.currentUser?.name} (ID: ${authProvider.currentUser?.id})');
      
      // Configurar AuthProvider nos providers
      transactionProvider.setAuthProvider(authProvider);
      memberProvider.setAuthProvider(authProvider);
      categoryProvider.setAuthProvider(authProvider);
      
      // Remover tabelas duplicadas primeiro
      print('Verificando e removendo tabelas duplicadas...');
      await databaseService.removeDuplicateTables();
      
      // Inicializar dados sequencialmente para evitar condições de corrida
      print('Carregando membros...');
      await memberProvider.loadMembers();
      
      print('Carregando categorias...');
      await categoryProvider.loadCategories();
      
      print('Inicializando transações...');
      await transactionProvider.initialize();
      
      // Aguardar um pouco para garantir que o TransactionProvider esteja completamente pronto
      await Future.delayed(Duration(milliseconds: 100));
      
      // Definir o TransactionProvider no ReportProvider
      reportProvider.setTransactionProvider(transactionProvider);
      
      print('Gerando relatório mensal...');
      print('Mês selecionado para relatório: ${_selectedMonth.month}/${_selectedMonth.year}');
      
      // Debug: Verificar transações diretamente no banco
      await _debugDatabaseTransactions();
      
      await reportProvider.generateMonthlyReport(_selectedMonth);
      
      print('Carregando transações recentes...');
      await quickEntryProvider.loadRecentTransactions();
      
      print('Dados da tela inicial inicializados com sucesso');
      print('Membros carregados: ${memberProvider.members.length}');
      print('Categorias carregadas: ${categoryProvider.categories.length}');
      print('Transações carregadas: ${transactionProvider.transactions.length}');
      
      // Forçar atualização da UI após inicialização
      if (mounted) {
        setState(() {});
        print('UI forçada a atualizar após inicialização');
      }
    } catch (e) {
      print('Erro ao inicializar dados da tela inicial: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
        print('Loading inicial desativado');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableFABWrapper(
      child: Scaffold(
      appBar: AppBar(
        title: Consumer<SyncProvider>(
          builder: (context, syncProvider, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Fluxo Família'),
                if (syncProvider.lastSyncTime != null) ...[
                  SizedBox(width: 8),
                  Icon(
                    Icons.cloud_done,
                    size: 16,
                    color: Colors.greenAccent,
                  ),
                ],
              ],
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<SyncProvider>(
            builder: (context, syncProvider, child) {
              return IconButton(
                icon: syncProvider.isSyncing 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.sync),
                onPressed: syncProvider.isSyncing ? null : _handleSync,
                tooltip: syncProvider.isSyncing 
                  ? 'Sincronizando...' 
                  : 'Sincronizar com Firebase',
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
                    Icon(Icons.person, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.backup, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Backup & Restore'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Configurações'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
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
    ),
    );
  }

  Widget _buildBody() {
    // Se está carregando inicialmente, mostra o loader em tela cheia
    if (_isInitialLoading) {
      return TransactionLoader(
        message: "Carregando dados iniciais...",
        size: 120.0,
        primaryColor: Theme.of(context).colorScheme.primary,
        secondaryColor: Theme.of(context).colorScheme.secondary,
      );
    }
    
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
    // Se está carregando o mês, mostra o loader em tela cheia
    if (_isLoadingMonth) {
      return TransactionLoader(
        message: "Carregando dados do mês...",
        size: 120.0,
        primaryColor: Theme.of(context).colorScheme.primary,
        secondaryColor: Theme.of(context).colorScheme.secondary,
      );
    }
    
    return Consumer2<TransactionProvider, ReportProvider>(
        builder: (context, transactionProvider, reportProvider, child) {
          // Log para debug
          print('=== BUILD HOME TAB ===');
          print('TransactionProvider isLoading: ${transactionProvider.isLoading}');
          print('ReportProvider isLoading: ${reportProvider.isLoading}');
          print('TransactionProvider error: ${transactionProvider.error}');
          print('ReportProvider error: ${reportProvider.error}');
          print('Transações carregadas: ${transactionProvider.transactions.length}');
          print('Total receitas: ${reportProvider.totalIncome}');
          print('Total despesas: ${reportProvider.totalExpense}');

          // Se ainda está carregando inicialmente E não há dados, mostrar skeleton
          if ((transactionProvider.isLoading || reportProvider.isLoading) && 
              transactionProvider.transactions.isEmpty && 
              reportProvider.totalIncome == 0 && 
              reportProvider.totalExpense == 0) {
            print('Mostrando skeleton - ainda carregando e sem dados');
            return const HomePageSkeleton();
          }

          // Se há erro, mostrar tela de erro
          if (transactionProvider.error != null || reportProvider.error != null) {
            print('Mostrando tela de erro');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro: ${transactionProvider.error ?? reportProvider.error}',
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

          // Se chegou até aqui, mostrar dados (mesmo que sejam zeros)
          print('Mostrando dados da tela inicial');
          print('Dados finais - Receitas: ${reportProvider.totalIncome}, Despesas: ${reportProvider.totalExpense}');
          
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
                  
                  // Se não há transações, mostrar mensagem
                  if (transactionProvider.transactions.isEmpty) ...[
                    SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma transação encontrada',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Adicione sua primeira transação usando os botões acima',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
        print('Mês atual: ${_selectedMonth.month}/${_selectedMonth.year}');
        print('Receitas: ${reportProvider.totalIncome}');
        print('Despesas: ${reportProvider.totalExpense}');
        print('Saldo: ${reportProvider.balance}');
        print('Loading: ${reportProvider.isLoading}');
        print('Error: ${reportProvider.error}');
        print('Transações mensais: ${reportProvider.monthlyTransactions.length}');
        
        // Log detalhado das transações
        for (int i = 0; i < reportProvider.monthlyTransactions.length && i < 5; i++) {
          final t = reportProvider.monthlyTransactions[i];
          print('Transação ${i+1}: ${t.category} - ${t.value} - ${t.date.day}/${t.date.month}/${t.date.year}');
        }
        
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
        );
        break;
      case 'backup':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BackupPage(),
          ),
        );
        break;
      case 'settings':
        // TODO: Implementar configurações
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configurações em breve!'),
            backgroundColor: Colors.orange,
          ),
        );
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

  /// Executa sincronização com Firebase
  Future<void> _handleSync() async {
    try {
      final syncProvider = context.read<SyncProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final memberProvider = context.read<MemberProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final authProvider = context.read<AuthProvider>();

      // Obter ID do usuário logado
      final localUserId = authProvider.currentUser?.id ?? 1;
      print('Iniciando sincronização para usuário: $localUserId');

      // Mostrar diálogo de confirmação
      final shouldSync = await showDialog<bool>(
        context: context,
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: transactionProvider),
            ChangeNotifierProvider.value(value: memberProvider),
            ChangeNotifierProvider.value(value: categoryProvider),
          ],
          child: AlertDialog(
            title: Text('Sincronizar com Firebase'),
            content: Consumer3<TransactionProvider, MemberProvider, CategoryProvider>(
              builder: (context, transactionProvider, memberProvider, categoryProvider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Esta ação irá sincronizar todos os seus dados com a nuvem:'),
                    SizedBox(height: 16),
                    Text('• ${transactionProvider.transactions.length} transações'),
                    Text('• ${memberProvider.members.length} membros'),
                    Text('• ${categoryProvider.categories.length} categorias'),
                    SizedBox(height: 16),
                    Text('Usuário: ${authProvider.currentUser?.name ?? 'Desconhecido'}'),
                    SizedBox(height: 16),
                    Text('Deseja continuar?'),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sincronizar'),
              ),
            ],
          ),
        ),
      );

      if (shouldSync != true) return;

      // Executar sincronização
      final result = await syncProvider.syncWithFirebase(
        transactions: transactionProvider.transactions,
        members: memberProvider.members,
        categories: categoryProvider.categories,
        localUserId: localUserId,
      );

      // Mostrar resultado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] 
                ? 'Sincronização concluída com sucesso!' 
                : 'Erro na sincronização: ${result['error']}',
            ),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na sincronização: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
    final memberProvider = context.read<MemberProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final authProvider = context.read<AuthProvider>();
    
    try {
      print('=== HOME: INICIANDO ATUALIZAÇÃO DA TELA INICIAL ===');
      print('Mês selecionado: ${_selectedMonth.month}/${_selectedMonth.year}');
      print('Usuário logado: ${authProvider.currentUser?.name} (ID: ${authProvider.currentUser?.id})');
      
      // Configurar AuthProvider nos providers
      transactionProvider.setAuthProvider(authProvider);
      memberProvider.setAuthProvider(authProvider);
      categoryProvider.setAuthProvider(authProvider);
      
      // Atualizar todos os providers
      await memberProvider.loadMembers();
      await categoryProvider.loadCategories();
      await transactionProvider.refresh();
      
      // Definir o TransactionProvider no ReportProvider
      reportProvider.setTransactionProvider(transactionProvider);
      
      await reportProvider.generateMonthlyReport(_selectedMonth);
      await quickEntryProvider.loadRecentTransactions();
      
      print('=== HOME: Todas as operações concluídas ===');
      print('Membros carregados: ${memberProvider.members.length}');
      print('Categorias carregadas: ${categoryProvider.categories.length}');
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


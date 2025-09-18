import '../services/database_service.dart';

class DebugDatabase {
  static final DatabaseService _databaseService = DatabaseService();

  /// Verifica se o campo excluido_em existe na tabela
  static Future<void> checkTableStructure() async {
    try {
      final db = await _databaseService.database;
      
      // Verificar estrutura da tabela
      final tableInfo = await db.rawQuery("PRAGMA table_info(transactions)");
      
      print('\n📋 ESTRUTURA DA TABELA TRANSACTIONS:');
      for (final column in tableInfo) {
        final name = column['name'];
        final type = column['type'];
        final notNull = column['notnull'] == 1 ? 'NOT NULL' : 'NULL';
        print('   $name ($type) - $notNull');
      }
      
      // Verificar se o campo excluido_em existe
      final hasExcluidoEm = tableInfo.any((col) => col['name'] == 'excluido_em');
      print('\n🔍 Campo excluido_em existe: ${hasExcluidoEm ? '✅ SIM' : '❌ NÃO'}');
      
    } catch (e) {
      print('❌ Erro ao verificar estrutura da tabela: $e');
    }
  }

  /// Lista todas as transações com seus campos de exclusão
  static Future<void> listAllTransactions() async {
    try {
      final db = await _databaseService.database;
      
      final transactions = await db.query('transactions', 
        columns: ['id', 'categoria', 'valor', 'criado_em', 'atualizado_em', 'excluido_em'],
        orderBy: 'id DESC',
        limit: 10
      );
      
      print('\n📊 ÚLTIMAS 10 TRANSAÇÕES:');
      print('ID | Categoria | Valor | Criado | Atualizado | Excluído');
      print('---|-----------|-------|--------|------------|----------');
      
      for (final transaction in transactions) {
        final id = transaction['id'];
        final categoria = transaction['categoria'];
        final valor = transaction['valor'];
        final criado = transaction['criado_em'];
        final atualizado = transaction['atualizado_em'];
        final excluido = transaction['excluido_em'] ?? 'NULL';
        
        print('$id | $categoria | R\$ $valor | $criado | $atualizado | $excluido');
      }
      
    } catch (e) {
      print('❌ Erro ao listar transações: $e');
    }
  }

  /// Verifica transações excluídas
  static Future<void> checkDeletedTransactions() async {
    try {
      final db = await _databaseService.database;
      
      final deletedTransactions = await db.query('transactions', 
        where: 'excluido_em IS NOT NULL',
        columns: ['id', 'categoria', 'valor', 'excluido_em'],
        orderBy: 'excluido_em DESC'
      );
      
      print('\n🗑️ TRANSAÇÕES EXCLUÍDAS:');
      if (deletedTransactions.isEmpty) {
        print('   Nenhuma transação excluída encontrada');
      } else {
        print('ID | Categoria | Valor | Data de Exclusão');
        print('---|-----------|-------|------------------');
        
        for (final transaction in deletedTransactions) {
          final id = transaction['id'];
          final categoria = transaction['categoria'];
          final valor = transaction['valor'];
          final excluido = transaction['excluido_em'];
          
          print('$id | $categoria | R\$ $valor | $excluido');
        }
      }
      
    } catch (e) {
      print('❌ Erro ao verificar transações excluídas: $e');
    }
  }

  /// Executa todas as verificações
  static Future<void> runFullDiagnostic() async {
    print('🔍 INICIANDO DIAGNÓSTICO COMPLETO DO BANCO DE DADOS\n');
    
    await checkTableStructure();
    await listAllTransactions();
    await checkDeletedTransactions();
    
    print('\n✅ DIAGNÓSTICO CONCLUÍDO');
  }
}
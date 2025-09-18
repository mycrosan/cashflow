import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/member.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';
import '../config/app_config.dart';

class DatabaseService {
  static Database? _database;
  static String get _databaseName => AppConfig.databaseName;
  static int get _databaseVersion => 14;

  // Tabelas
  static const String _tableUsers = 'usuarios';
  static const String _tableMembers = 'responsaveis';
  static const String _tableCategories = 'categorias';
  static const String _tableTransactions = 'lancamentos';
  static const String _tableRecurringTransactions = 'recorrencias';
  static const String _tableSyncLog = 'log_sincronizacao';

  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE $_tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL,
        foto_perfil TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL
      )
    ''');

    // Tabela de membros
    await db.execute('''
      CREATE TABLE $_tableMembers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        relacao TEXT NOT NULL,
        foto_perfil TEXT,
        usuario_id INTEGER NOT NULL,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES $_tableUsers (id)
      )
    ''');

    // Tabela de categorias
    await db.execute('''
      CREATE TABLE $_tableCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        icone TEXT,
        cor TEXT,
        usuario_id INTEGER NOT NULL,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES $_tableUsers (id)
      )
    ''');

    // Tabela de transações
    await db.execute('''
      CREATE TABLE $_tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        categoria TEXT NOT NULL,
        responsavel_id INTEGER NOT NULL,
        observacoes TEXT,
        imagem_recibo TEXT,
        recorrencia_id INTEGER,
        status_sincronizacao TEXT NOT NULL DEFAULT 'synced',
        pago INTEGER NOT NULL DEFAULT 0,
        data_pagamento TEXT,
        usuario_id INTEGER NOT NULL,
        excluido_em TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (responsavel_id) REFERENCES $_tableMembers (id),
        FOREIGN KEY (recorrencia_id) REFERENCES $_tableRecurringTransactions (id),
        FOREIGN KEY (usuario_id) REFERENCES $_tableUsers (id)
      )
    ''');

    // Tabela de transações recorrentes
    await db.execute('''
      CREATE TABLE $_tableRecurringTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        frequencia TEXT NOT NULL,
        categoria TEXT NOT NULL,
        valor REAL NOT NULL,
        responsavel_id INTEGER NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        max_ocorrencias INTEGER,
        ativo INTEGER NOT NULL DEFAULT 1,
        observacoes TEXT,
        usuario_id INTEGER NOT NULL,
        excluido_em TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (responsavel_id) REFERENCES $_tableMembers (id),
        FOREIGN KEY (usuario_id) REFERENCES $_tableUsers (id)
      )
    ''');

    // Tabela de log de sincronização
    await db.execute('''
      CREATE TABLE $_tableSyncLog (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_tabela TEXT NOT NULL,
        id_registro INTEGER NOT NULL,
        acao TEXT NOT NULL,
        status_sincronizacao TEXT NOT NULL DEFAULT 'pending',
        criado_em TEXT NOT NULL,
        sincronizado_em TEXT
      )
    ''');

    // Índices para melhor performance
    await _createIndexIfNotExists(db, 'idx_transactions_date', _tableTransactions, 'data');
    await _createIndexIfNotExists(db, 'idx_transactions_category', _tableTransactions, 'categoria');
    await _createIndexIfNotExists(db, 'idx_transactions_member', _tableTransactions, 'responsavel_id');
    await _createIndexIfNotExists(db, 'idx_transactions_sync', _tableTransactions, 'status_sincronizacao');
    await _createIndexIfNotExists(db, 'idx_sync_log_status', _tableSyncLog, 'status_sincronizacao');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        // Tentar adicionar campos de pagamento na tabela de transações
        try {
          await db.execute('ALTER TABLE $_tableTransactions ADD COLUMN is_paid INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE $_tableTransactions ADD COLUMN paid_date TEXT');
        } catch (e) {
          // Se falhar, recriar a tabela
          await _recreateTransactionsTable(db);
        }
      }
      
      if (oldVersion < 3) {
        // Versão 3: Campos de pagamento já estão na criação da tabela
        // Não precisa fazer nada, apenas incrementar a versão
      }
      
      if (oldVersion < 4) {
        // Versão 4: Recriar tabela de transações para resolver conflitos de colunas
        await _recreateTransactionsTable(db);
      }
      
      if (oldVersion < 5) {
        // Versão 5: Recriar tabela de transações com nomes de colunas corretos
        await _recreateTransactionsTable(db);
      }
      
      if (oldVersion < 6) {
        // Versão 6: Recriar tabela de transações e corrigir queries
        await _recreateTransactionsTable(db);
      }
      
      if (oldVersion < 7) {
        // Versão 7: Recriar todas as tabelas com nomes em português
        await _recreateAllTables(db);
      }
      
      if (oldVersion < 8) {
        // Versão 8: Corrigir índices duplicados
        await _recreateAllTables(db);
      }
      
      if (oldVersion < 9) {
        // Versão 9: Corrigir modelos para usar nomes de colunas em português
        await _recreateAllTables(db);
      }
      
      if (oldVersion < 10) {
        // Versão 10: Corrigir todas as tabelas para usar nomes em português
        await _recreateAllTables(db);
      }
      
      if (oldVersion < 11) {
        // Versão 11: Corrigir modelos User, Member e Category para usar nomes em português
        await _recreateAllTables(db);
      }
      
      if (oldVersion < 12) {
        // Versão 12: Corrigir consultas SQL para usar nomes em português
        await _recreateAllTables(db);
      }
      
      if (oldVersion < 13) {
        // Versão 13: Adicionar campo usuario_id na tabela de transações
        try {
          await db.execute('ALTER TABLE $_tableTransactions ADD COLUMN usuario_id INTEGER');
          print('Campo usuario_id adicionado na tabela $_tableTransactions');
          
          // Atualizar registros existentes com usuario_id = 1 (usuário padrão)
          await db.execute('UPDATE $_tableTransactions SET usuario_id = 1 WHERE usuario_id IS NULL');
          print('Registros existentes de transações atualizados com usuario_id = 1');
          
          print('Migração para versão 13 concluída com sucesso');
        } catch (e) {
          print('Erro na migração para versão 13: $e');
          // Se der erro, recriar todas as tabelas
          await _recreateAllTables(db);
        }
      }
      
      if (oldVersion < 14) {
        // Versão 14: Adicionar campo excluido_em para soft delete
        try {
          // Adicionar campo excluido_em na tabela de transações
          await db.execute('ALTER TABLE $_tableTransactions ADD COLUMN excluido_em TEXT');
          print('Campo excluido_em adicionado na tabela $_tableTransactions');
          
          // Adicionar campo excluido_em na tabela de transações recorrentes
          await db.execute('ALTER TABLE $_tableRecurringTransactions ADD COLUMN excluido_em TEXT');
          print('Campo excluido_em adicionado na tabela $_tableRecurringTransactions');
          
          print('Migração para versão 14 concluída com sucesso');
        } catch (e) {
          print('Erro na migração para versão 14: $e');
          // Se der erro, recriar todas as tabelas
          await _recreateAllTables(db);
        }
      }
    } catch (e) {
      // Em caso de erro, recriar todas as tabelas
      await _recreateAllTables(db);
    }
  }

  Future<void> _recreateTransactionsTable(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $_tableTransactions');
    await db.execute('''
      CREATE TABLE $_tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        categoria TEXT NOT NULL,
        responsavel_id INTEGER NOT NULL,
        observacoes TEXT,
        imagem_recibo TEXT,
        recorrencia_id INTEGER,
        status_sincronizacao TEXT NOT NULL DEFAULT 'synced',
        pago INTEGER NOT NULL DEFAULT 0,
        data_pagamento TEXT,
        usuario_id INTEGER NOT NULL,
        excluido_em TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (responsavel_id) REFERENCES $_tableMembers (id),
        FOREIGN KEY (recorrencia_id) REFERENCES $_tableRecurringTransactions (id),
        FOREIGN KEY (usuario_id) REFERENCES $_tableUsers (id)
      )
    ''');
  }

  Future<void> _createIndexIfNotExists(Database db, String indexName, String tableName, String columnName) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS $indexName ON $tableName ($columnName)');
    } catch (e) {
      // Ignorar erros de índice já existente
      print('Índice $indexName já existe ou erro ao criar: $e');
    }
  }

  Future<void> _recreateAllTables(Database db) async {
    // Dropar todas as tabelas
    await db.execute('DROP TABLE IF EXISTS $_tableTransactions');
    await db.execute('DROP TABLE IF EXISTS $_tableRecurringTransactions');
    await db.execute('DROP TABLE IF EXISTS $_tableCategories');
    await db.execute('DROP TABLE IF EXISTS $_tableMembers');
    await db.execute('DROP TABLE IF EXISTS $_tableUsers');
    await db.execute('DROP TABLE IF EXISTS $_tableSyncLog');
    
    // Recriar todas as tabelas usando o método _onCreate
    await _onCreate(db, _databaseVersion);
  }

  // === USERS ===

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(_tableUsers, user.toJson());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query(_tableUsers, orderBy: 'nome ASC');
    return maps.map((map) => User.fromJson(map)).toList();
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      _tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      _tableUsers,
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      _tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === MEMBERS ===

  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert(_tableMembers, member.toJson());
  }

  Future<List<Member>> getMembers({int? userId}) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause = 'usuario_id = ?';
      whereArgs.add(userId);
    }
    
    final maps = await db.query(
      _tableMembers,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'nome ASC',
    );
    return maps.map((map) => Member.fromJson(map)).toList();
  }

  Future<Member?> getMember(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableMembers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Member.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update(
      _tableMembers,
      member.toJson(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete(
      _tableMembers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === CATEGORIES ===

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert(_tableCategories, category.toJson());
  }

  Future<List<Category>> getCategories({int? userId}) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause = 'usuario_id = ?';
      whereArgs.add(userId);
    }
    
    final maps = await db.query(
      _tableCategories,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'nome ASC',
    );
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  Future<List<Category>> getCategoriesByType(String type, {int? userId}) async {
    final db = await database;
    
    String whereClause = 'tipo = ?';
    List<dynamic> whereArgs = [type];
    
    if (userId != null) {
      whereClause += ' AND usuario_id = ?';
      whereArgs.add(userId);
    }
    
    final maps = await db.query(
      _tableCategories,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'nome ASC',
    );
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  Future<Category?> getCategory(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      _tableCategories,
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      _tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === TRANSACTIONS ===

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    final data = transaction.toJson();
    
    return await db.insert(_tableTransactions, data);
  }

  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? memberId,
    int? userId,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += 'data >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'data <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'categoria = ?';
      whereArgs.add(category);
    }
    
    if (memberId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'responsavel_id = ?';
      whereArgs.add(memberId);
    }
    
    if (userId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'usuario_id = ?';
      whereArgs.add(userId);
    }

    // Filtrar registros não excluídos (soft delete)
    if (whereClause.isNotEmpty) whereClause += ' AND ';
    whereClause += 'excluido_em IS NULL';

    print('=== DATABASE SERVICE: Consultando transações ===');
    print('WHERE: $whereClause');
    print('WHERE ARGS: $whereArgs');
    print('StartDate: ${startDate?.toIso8601String()}');
    print('EndDate: ${endDate?.toIso8601String()}');
    print('UserId: $userId');

    final maps = await db.query(
      _tableTransactions,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'data DESC',
    );

    print('=== DATABASE SERVICE: Resultado da consulta ===');
    print('Registros encontrados: ${maps.length}');
    
    // Log das primeiras 5 transações encontradas
    for (int i = 0; i < maps.length && i < 5; i++) {
      final map = maps[i];
      print('Registro ${i+1}: ID=${map['id']}, Categoria=${map['categoria']}, Valor=${map['valor']}, Data=${map['data']}');
    }

    // Converter para objetos Transaction com relacionamentos
    final transactions = <Transaction>[];
    for (final map in maps) {
      final member = await getMember(map['responsavel_id'] as int);
      if (member != null) {
        final transaction = Transaction.fromJson({
          ...map,
          'responsavel': member.toJson(),
        });
        transactions.add(transaction);
      }
    }

    return transactions;
  }

  Future<Transaction?> getTransaction(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final map = maps.first;
      final member = await getMember(map['responsavel_id'] as int);
      if (member != null) {
        return Transaction.fromJson({
          ...map,
          'responsavel': member.toJson(),
        });
      }
    }
    return null;
  }

  // Verificar se existe transação recorrente ATIVA (não excluída)
  Future<bool> checkRecurringTransactionExistsIncludingDeleted({
    required int recurringTransactionId,
    required DateTime date,
  }) async {
    final db = await database;
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final maps = await db.query(
      _tableTransactions,
      where: 'recorrencia_id = ? AND data >= ? AND data <= ?',
      whereArgs: [
        recurringTransactionId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );
    
    print('=== DATABASE SERVICE: Verificando transação recorrente ===');
    print('RecurringTransactionId: $recurringTransactionId');
    print('Data: ${date.toIso8601String()}');
    print('Registros encontrados (incluindo excluídos): ${maps.length}');
    
    if (maps.isNotEmpty) {
      final transaction = maps.first;
      final isDeleted = transaction['excluido_em'] != null;
      print('Transação encontrada - ID: ${transaction['id']}, Excluída: $isDeleted');
      print('excluido_em: ${transaction['excluido_em']}');
      
      // Retorna true apenas se a transação NÃO foi excluída (está ativa)
      // Se foi excluída, permite criar uma nova transação
      return !isDeleted;
    }
    
    // Se não encontrou nenhuma transação, permite criar
    return false;
  }

  // Buscar transações excluídas (para funcionalidade de restaurar)
  Future<List<Transaction>> getDeletedTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    final db = await database;
    
    String whereClause = 'excluido_em IS NOT NULL';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += ' AND data >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND data <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (userId != null) {
      whereClause += ' AND usuario_id = ?';
      whereArgs.add(userId);
    }

    final maps = await db.query(
      _tableTransactions,
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'excluido_em DESC',
    );

    // Converter para objetos Transaction com relacionamentos
    final transactions = <Transaction>[];
    for (final map in maps) {
      final member = await getMember(map['responsavel_id'] as int);
      if (member != null) {
        final transaction = Transaction.fromJson({
          ...map,
          'responsavel': member.toJson(),
        });
        transactions.add(transaction);
      }
    }

    return transactions;
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    final data = transaction.toJson();
    
    // Debug: Verificar dados que serão salvos
    print('💾 DEBUG DATABASE - Atualizando transação ID: ${transaction.id}');
    print('💾 DEBUG DATABASE - Campo excluido_em: ${data['excluido_em']}');
    
    final result = await db.update(
      _tableTransactions,
      data,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    
    // Debug: Verificar se a atualização foi bem-sucedida
    print('💾 DEBUG DATABASE - Linhas afetadas: $result');
    
    // Debug: Verificar se o campo foi realmente salvo
    final savedTransaction = await db.query(
      _tableTransactions,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    if (savedTransaction.isNotEmpty) {
      print('💾 DEBUG DATABASE - Campo salvo: ${savedTransaction.first['excluido_em']}');
    }
    
    return result;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    
    print('=== DATABASE SERVICE: Soft delete da transação $id ===');
    
    // Fazer soft delete: apenas marcar como excluída
    final result = await db.update(
      _tableTransactions,
      {
        'excluido_em': DateTime.now().toIso8601String(),
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('=== DATABASE SERVICE: Transação $id marcada como excluída (soft delete) ===');
    print('=== DATABASE SERVICE: Linhas afetadas: $result ===');
    
    return result;
  }

  // Método para exclusão física (hard delete) - usar apenas quando necessário
  Future<int> deleteTransactionPhysically(int id) async {
    final db = await database;
    
    print('=== DATABASE SERVICE: Hard delete da transação $id ===');
    
    final result = await db.delete(
      _tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('=== DATABASE SERVICE: Transação $id removida fisicamente ===');
    print('=== DATABASE SERVICE: Linhas afetadas: $result ===');
    
    return result;
  }

  // === RECURRING TRANSACTIONS ===

  Future<int> insertRecurringTransaction(RecurringTransaction recurringTransaction) async {
    final db = await database;
    final data = recurringTransaction.toJson();
    data['responsavel_id'] = recurringTransaction.associatedMember.id;
    
    return await db.insert(_tableRecurringTransactions, data);
  }

  Future<List<RecurringTransaction>> getRecurringTransactions({int? userId}) async {
    final db = await database;
    
    String whereClause = 'ativo = 1 AND excluido_em IS NULL';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += ' AND usuario_id = ?';
      whereArgs.add(userId);
    }
    
    final maps = await db.query(
      _tableRecurringTransactions,
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'data_inicio ASC',
    );

    final recurringTransactions = <RecurringTransaction>[];
    for (final map in maps) {
      final member = await getMember(map['responsavel_id'] as int);
      if (member != null) {
        final recurringTransaction = RecurringTransaction.fromJson({
          ...map,
          'responsavel': member.toJson(),
        });
        recurringTransactions.add(recurringTransaction);
      }
    }

    return recurringTransactions;
  }

  // Buscar transações recorrentes excluídas (para funcionalidade de restaurar)
  Future<List<RecurringTransaction>> getDeletedRecurringTransactions({int? userId}) async {
    final db = await database;
    
    String whereClause = 'excluido_em IS NOT NULL';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += ' AND usuario_id = ?';
      whereArgs.add(userId);
    }
    
    final maps = await db.query(
      _tableRecurringTransactions,
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'excluido_em DESC',
    );

    final recurringTransactions = <RecurringTransaction>[];
    for (final map in maps) {
      final member = await getMember(map['responsavel_id'] as int);
      if (member != null) {
        final recurringTransaction = RecurringTransaction.fromJson({
          ...map,
          'responsavel': member.toJson(),
        });
        recurringTransactions.add(recurringTransaction);
      }
    }

    return recurringTransactions;
  }

  Future<int> updateRecurringTransaction(RecurringTransaction recurringTransaction) async {
    print('=== DATABASE SERVICE: Iniciando atualização de transação recorrente ID: ${recurringTransaction.id} ===');
    
    final db = await database;
    final data = recurringTransaction.toJson();
    data['responsavel_id'] = recurringTransaction.associatedMember.id;
    
    print('=== DATABASE SERVICE: Dados para atualização: $data ===');
    print('=== DATABASE SERVICE: WHERE id = ${recurringTransaction.id} ===');
    
    final result = await db.update(
      _tableRecurringTransactions,
      data,
      where: 'id = ?',
      whereArgs: [recurringTransaction.id],
    );
    
    print('=== DATABASE SERVICE: Resultado da atualização: $result ===');
    return result;
  }

  Future<int> deleteRecurringTransaction(int id) async {
    final db = await database;
    return await db.delete(
      _tableRecurringTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<RecurringTransaction?> getRecurringTransaction(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableRecurringTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final map = maps.first;
      final member = await getMember(map['responsavel_id'] as int);
      if (member != null) {
        return RecurringTransaction.fromJson({
          ...map,
          'responsavel': member.toJson(),
        });
      }
    }
    return null;
  }

  // === SYNC LOG ===

  Future<void> logSyncAction(String tableName, int recordId, String action) async {
    final db = await database;
    await db.insert(_tableSyncLog, {
      'nome_tabela': tableName,
      'id_registro': recordId,
      'acao': action,
      'status_sincronizacao': 'pending',
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    final db = await database;
    return await db.query(
      _tableSyncLog,
      where: 'status_sincronizacao = ?',
      whereArgs: ['pending'],
      orderBy: 'criado_em ASC',
    );
  }

  Future<void> markSyncActionAsSynced(int id) async {
    final db = await database;
    await db.update(
      _tableSyncLog,
      {
        'status_sincronizacao': 'synced',
        'sincronizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> markTransactionAsPaid(int transactionId, {DateTime? paidDate}) async {
    final db = await database;
    final now = DateTime.now();
    
    final result = await db.update(
      _tableTransactions,
      {
        'pago': 1,
        'data_pagamento': paidDate?.toIso8601String() ?? now.toIso8601String(),
        'atualizado_em': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    
    return result > 0;
  }

  Future<bool> markTransactionAsUnpaid(int transactionId) async {
    final db = await database;
    final now = DateTime.now();
    
    final result = await db.update(
      _tableTransactions,
      {
        'pago': 0,
        'data_pagamento': null,
        'atualizado_em': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    
    return result > 0;
  }

  // === UTILITIES ===

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(_tableSyncLog);
    await db.delete(_tableTransactions);
    await db.delete(_tableRecurringTransactions);
    await db.delete(_tableCategories);
    await db.delete(_tableMembers);
    await db.delete(_tableUsers);
  }

  // Método para remover tabelas duplicadas (sem migrar dados)
  Future<void> removeDuplicateTables() async {
    final db = await database;
    
    // Lista de tabelas duplicadas para remover
    final duplicateTables = ['members', 'users', 'sync_log'];
    
    for (final tableName in duplicateTables) {
      try {
        // Verificar se a tabela existe
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
        );
        
        if (result.isNotEmpty) {
          print('Tabela $tableName encontrada, removendo...');
          
          // Verificar se há dados na tabela
          final dataCount = await db.rawQuery("SELECT COUNT(*) as count FROM $tableName");
          final count = dataCount.first['count'] as int;
          
          if (count > 0) {
            print('Tabela $tableName tem $count registros - removendo sem migrar dados.');
            
            // Migração desabilitada - apenas removendo tabelas
            // if (tableName == 'members') {
            //   // Código de migração comentado
            // }
            
            // Para users, migrar para usuarios se necessário
            if (tableName == 'users') {
              final usuariosData = await db.rawQuery("SELECT COUNT(*) as count FROM usuarios");
              final usuariosCount = usuariosData.first['count'] as int;
              
              if (usuariosCount == 0 && count > 0) {
                print('Migrando dados de users para usuarios...');
                
                await db.rawQuery('''
                  INSERT INTO usuarios (id, nome, email, senha, foto_perfil, criado_em, atualizado_em)
                  SELECT id, nome, email, senha, foto_perfil, criado_em, atualizado_em 
                  FROM users
                ''');
                
                print('Dados migrados com sucesso!');
              }
            }
          }
          
          // Remover a tabela
          await db.execute('DROP TABLE IF EXISTS $tableName');
          print('Tabela $tableName removida com sucesso!');
        } else {
          print('Tabela $tableName não encontrada.');
        }
      } catch (e) {
        print('Erro ao remover tabela $tableName: $e');
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ========== MÉTODOS PARA BACKUP ==========

  /// Limpa todos os dados do banco (para restore)
  Future<void> clearAllData() async {
    final db = await database;
    
    try {
      await db.transaction((txn) async {
        // Limpar todas as tabelas em ordem (respeitando foreign keys)
        await txn.delete(_tableRecurringTransactions);
        await txn.delete(_tableTransactions);
        await txn.delete(_tableCategories);
        await txn.delete(_tableMembers);
        await txn.delete(_tableUsers);
        await txn.delete(_tableSyncLog);
      });
      
      print('Todos os dados foram limpos com sucesso');
    } catch (e) {
      print('Erro ao limpar dados: $e');
      rethrow;
    }
  }

  /// Obtém todas as transações recorrentes (sem filtro de usuário)
  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableRecurringTransactions);
    
    return List.generate(maps.length, (i) {
      return RecurringTransaction.fromJson(maps[i]);
    });
  }

  /// Verifica se existe uma transação recorrente excluída (soft delete) para uma data específica
  Future<bool> hasDeletedRecurringTransactionForDate({
    required int recurringTransactionId,
    required DateTime date,
  }) async {
    final db = await database;
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final maps = await db.query(
      _tableTransactions,
      where: 'recorrencia_id = ? AND data >= ? AND data <= ? AND excluido_em IS NOT NULL',
      whereArgs: [
        recurringTransactionId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );
    
    print('=== DATABASE SERVICE: Verificando transação recorrente excluída ===');
    print('RecurringTransactionId: $recurringTransactionId');
    print('Data: ${date.toIso8601String()}');
    print('Transações excluídas encontradas: ${maps.length}');
    
    return maps.isNotEmpty;
  }
}

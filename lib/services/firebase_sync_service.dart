import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../models/member.dart';
import '../models/category.dart' as cat;
import '../core/firebase_config.dart';

/// Serviço de sincronização com Firebase Firestore
class FirebaseSyncService {
  static FirebaseSyncService? _instance;
  static FirebaseSyncService get instance {
    _instance ??= FirebaseSyncService._internal();
    return _instance!;
  }

  FirebaseSyncService._internal();

  late fs.FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  bool _initialized = false;

  /// Inicializa o serviço de sincronização
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Verificar se Firebase está inicializado
      if (!FirebaseConfig.isInitialized) {
        await FirebaseConfig.initialize();
      }

      _firestore = fs.FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _initialized = true;

      print('FirebaseSyncService inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar FirebaseSyncService: $e');
      throw Exception('Erro ao inicializar sincronização Firebase: $e');
    }
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  /// Obtém o ID do usuário atual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Obtém a coleção de transações do usuário
  fs.CollectionReference get _transactionsCollection {
    if (!isAuthenticated) throw Exception('Usuário não autenticado');
    return _firestore.collection('users').doc(currentUserId).collection('transactions');
  }

  /// Obtém a coleção de membros do usuário
  fs.CollectionReference get _membersCollection {
    if (!isAuthenticated) throw Exception('Usuário não autenticado');
    return _firestore.collection('users').doc(currentUserId).collection('members');
  }

  /// Obtém a coleção de categorias do usuário
  fs.CollectionReference get _categoriesCollection {
    if (!isAuthenticated) throw Exception('Usuário não autenticado');
    return _firestore.collection('users').doc(currentUserId).collection('categories');
  }

  /// Obtém o documento do usuário
  fs.DocumentReference get _userDocument {
    if (!isAuthenticated) throw Exception('Usuário não autenticado');
    return _firestore.collection('users').doc(currentUserId);
  }

  // === SINCRONIZAÇÃO DE TRANSAÇÕES ===

  /// Sincroniza transações locais com Firebase
  Future<void> syncTransactions(List<Transaction> transactions) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      print('Iniciando sincronização de ${transactions.length} transações...');

      // Obter transações do Firebase para comparação
      final firebaseTransactions = await _getFirebaseTransactions();
      final firebaseMap = {for (var t in firebaseTransactions) t.id: t};

      // Processar cada transação local
      for (final transaction in transactions) {
        if (transaction.id == null) continue;

        final firebaseTransaction = firebaseMap[transaction.id];
        
        if (firebaseTransaction == null) {
          // Nova transação - enviar para Firebase
          await _uploadTransaction(transaction);
          print('Transação ${transaction.id} enviada para Firebase');
        } else {
          // Transação existe - verificar se precisa atualizar
          if (transaction.updatedAt.isAfter(firebaseTransaction.updatedAt)) {
            await _updateTransaction(transaction);
            print('Transação ${transaction.id} atualizada no Firebase');
          }
        }
      }

      // Baixar novas transações do Firebase
      await _downloadNewTransactions(transactions);

      print('Sincronização de transações concluída');
    } catch (e) {
      print('Erro na sincronização de transações: $e');
      throw Exception('Erro na sincronização de transações: $e');
    }
  }

  /// Envia uma transação para Firebase
  Future<void> _uploadTransaction(Transaction transaction) async {
    final docRef = _transactionsCollection.doc(transaction.id.toString());
    await docRef.set(transaction.toFirestoreMap());
  }

  /// Atualiza uma transação no Firebase
  Future<void> _updateTransaction(Transaction transaction) async {
    final docRef = _transactionsCollection.doc(transaction.id.toString());
    await docRef.update(transaction.toFirestoreMap());
  }

  /// Obtém todas as transações do Firebase
  Future<List<Transaction>> _getFirebaseTransactions() async {
    final snapshot = await _transactionsCollection.get();
    return snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
  }

  /// Baixa novas transações do Firebase
  Future<void> _downloadNewTransactions(List<Transaction> localTransactions) async {
    final firebaseTransactions = await _getFirebaseTransactions();
    final localIds = localTransactions.map((t) => t.id).toSet();

    for (final firebaseTransaction in firebaseTransactions) {
      if (!localIds.contains(firebaseTransaction.id)) {
        // Nova transação do Firebase - adicionar localmente
        print('Nova transação ${firebaseTransaction.id} encontrada no Firebase');
        // Aqui você pode adicionar a transação ao banco local
        // await _databaseService.insertTransaction(firebaseTransaction);
      }
    }
  }

  // === SINCRONIZAÇÃO DE MEMBROS ===

  /// Sincroniza membros locais com Firebase
  Future<void> syncMembers(List<Member> members) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      print('Iniciando sincronização de ${members.length} membros...');

      for (final member in members) {
        if (member.id == null) continue;

        final docRef = _membersCollection.doc(member.id.toString());
        await docRef.set(member.toFirestoreMap());
        print('Membro ${member.id} sincronizado com Firebase');
      }

      print('Sincronização de membros concluída');
    } catch (e) {
      print('Erro na sincronização de membros: $e');
      throw Exception('Erro na sincronização de membros: $e');
    }
  }

  // === SINCRONIZAÇÃO DE CATEGORIAS ===

  /// Sincroniza categorias locais com Firebase
  Future<void> syncCategories(List<cat.Category> categories) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      print('Iniciando sincronização de ${categories.length} categorias...');

      for (final category in categories) {
        if (category.id == null) continue;

        final docRef = _categoriesCollection.doc(category.id.toString());
        await docRef.set(category.toFirestoreMap());
        print('Categoria ${category.id} sincronizada com Firebase');
      }

      print('Sincronização de categorias concluída');
    } catch (e) {
      print('Erro na sincronização de categorias: $e');
      throw Exception('Erro na sincronização de categorias: $e');
    }
  }

  // === SINCRONIZAÇÃO COMPLETA ===

  /// Executa sincronização completa de todos os dados
  Future<Map<String, dynamic>> syncAllData({
    required List<Transaction> transactions,
    required List<Member> members,
    required List<cat.Category> categories,
  }) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    final result = <String, dynamic>{
      'success': true,
      'transactions': <String, int>{'synced': 0, 'errors': 0},
      'members': <String, int>{'synced': 0, 'errors': 0},
      'categories': <String, int>{'synced': 0, 'errors': 0},
      'errors': <String>[],
    };

    try {
      print('Iniciando sincronização completa...');

      // Sincronizar transações
      try {
        await syncTransactions(transactions);
        (result['transactions'] as Map<String, int>)['synced'] = transactions.length;
      } catch (e) {
        (result['transactions'] as Map<String, int>)['errors'] = transactions.length;
        (result['errors'] as List<String>).add('Transações: $e');
      }

      // Sincronizar membros
      try {
        await syncMembers(members);
        (result['members'] as Map<String, int>)['synced'] = members.length;
      } catch (e) {
        (result['members'] as Map<String, int>)['errors'] = members.length;
        (result['errors'] as List<String>).add('Membros: $e');
      }

      // Sincronizar categorias
      try {
        await syncCategories(categories);
        (result['categories'] as Map<String, int>)['synced'] = categories.length;
      } catch (e) {
        (result['categories'] as Map<String, int>)['errors'] = categories.length;
        (result['errors'] as List<String>).add('Categorias: $e');
      }

      // Verificar se houve erros
      if ((result['errors'] as List<String>).isNotEmpty) {
        result['success'] = false;
      }

      print('Sincronização completa finalizada: $result');
      return result;

    } catch (e) {
      print('Erro na sincronização completa: $e');
      result['success'] = false;
      (result['errors'] as List<String>).add('Erro geral: $e');
      return result;
    }
  }

  // === STATUS DE SINCRONIZAÇÃO ===

  /// Obtém o status da última sincronização
  Future<Map<String, dynamic>> getSyncStatus() async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      final userDoc = await _userDocument.get();
      final data = userDoc.data() as Map<String, dynamic>?;

      return {
        'lastSync': data?['lastSync']?.toDate(),
        'syncCount': data?['syncCount'] ?? 0,
        'isOnline': true,
        'userId': currentUserId,
      };
    } catch (e) {
      return {
        'lastSync': null,
        'syncCount': 0,
        'isOnline': false,
        'error': e.toString(),
      };
    }
  }

  /// Atualiza o status da sincronização
  Future<void> updateSyncStatus() async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      await _userDocument.set({
        'lastSync': fs.FieldValue.serverTimestamp(),
        'syncCount': fs.FieldValue.increment(1),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      }, fs.SetOptions(merge: true));
    } catch (e) {
      print('Erro ao atualizar status de sincronização: $e');
    }
  }

  // === LIMPEZA ===

  /// Limpa todos os dados do usuário no Firebase
  Future<void> clearUserData() async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      // Deletar todas as subcoleções
      await _deleteCollection(_transactionsCollection);
      await _deleteCollection(_membersCollection);
      await _deleteCollection(_categoriesCollection);
      
      // Deletar documento do usuário
      await _userDocument.delete();

      print('Dados do usuário limpos no Firebase');
    } catch (e) {
      print('Erro ao limpar dados do usuário: $e');
      throw Exception('Erro ao limpar dados do usuário: $e');
    }
  }

  /// Deleta uma coleção recursivamente
  Future<void> _deleteCollection(fs.CollectionReference collection) async {
    final batch = _firestore.batch();
    final snapshot = await collection.limit(100).get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (snapshot.docs.length == 100) {
      // Mais documentos para deletar
      await _deleteCollection(collection);
    }
  }
}

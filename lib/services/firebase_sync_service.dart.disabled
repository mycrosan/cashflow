import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/transaction.dart';
import '../models/member.dart';
import '../models/category.dart' as cat;

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
      print('Inicializando FirebaseSyncService...');
      
      // Verificar se Firebase está inicializado
      try {
        _firestore = fs.FirebaseFirestore.instance;
        _auth = FirebaseAuth.instance;
        print('Firebase Auth e Firestore inicializados');
      } catch (e) {
        print('Erro ao acessar Firebase Auth/Firestore: $e');
        // Tentar reinicializar o Firebase
        try {
          print('Tentando reinicializar Firebase...');
          await Firebase.initializeApp();
          _firestore = fs.FirebaseFirestore.instance;
          _auth = FirebaseAuth.instance;
          print('Firebase reinicializado com sucesso');
        } catch (initError) {
          print('Erro ao reinicializar Firebase: $initError');
          throw Exception('Firebase não configurado corretamente. Verifique o arquivo google-services.json');
        }
      }
      
      // Fazer autenticação anônima se não estiver autenticado
      if (!isAuthenticated) {
        print('Fazendo autenticação anônima...');
        await _authenticateAnonymously();
      } else {
        print('Usuário já autenticado: ${_auth.currentUser?.uid}');
      }
      
      _initialized = true;

      print('FirebaseSyncService inicializado com sucesso');
      print('Usuário Firebase: ${_auth.currentUser?.uid}');
    } catch (e) {
      print('Erro ao inicializar FirebaseSyncService: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Erro ao inicializar sincronização Firebase: $e');
    }
  }
  
  /// Autentica anonimamente no Firebase
  Future<void> _authenticateAnonymously() async {
    try {
      print('Tentando autenticação anônima...');
      
      // Verificar se já existe um usuário anônimo
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        print('Usuário anônimo já existe: ${_auth.currentUser!.uid}');
        return;
      }
      
      final userCredential = await _auth.signInAnonymously();
      print('Autenticação anônima realizada com sucesso: ${userCredential.user?.uid}');
      
      // Verificar se a autenticação foi bem-sucedida
      if (userCredential.user == null) {
        throw Exception('Falha na autenticação anônima: usuário nulo');
      }
      
      print('Usuário anônimo criado: ${userCredential.user!.uid}');
    } catch (e) {
      print('Erro na autenticação anônima: $e');
      print('Tipo do erro: ${e.runtimeType}');
      
      // Se for erro de configuração, tentar uma abordagem diferente
      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        throw Exception('Firebase não configurado corretamente. Verifique o arquivo google-services.json');
      }
      
      throw Exception('Erro na autenticação anônima: $e');
    }
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  /// Obtém o ID do usuário atual
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Gera um ID único para o usuário local baseado em seu ID
  String _generateUserFirebaseId(int localUserId) {
    // Usar o ID do usuário local + timestamp para criar um ID único
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'user_${localUserId}_$timestamp';
  }
  
  /// Obtém ou cria o documento do usuário no Firebase
  Future<String> _getOrCreateUserDocument(int localUserId) async {
    final userFirebaseId = _generateUserFirebaseId(localUserId);
    final userDoc = _firestore.collection('users').doc(userFirebaseId);
    
    // Verificar se o documento existe
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      // Criar documento do usuário
      await userDoc.set({
        'localUserId': localUserId,
        'createdAt': fs.FieldValue.serverTimestamp(),
        'lastSync': fs.FieldValue.serverTimestamp(),
        'syncCount': 0,
      });
      print('Documento do usuário criado: $userFirebaseId');
    }
    
    return userFirebaseId;
  }

  /// Obtém a coleção de transações do usuário
  Future<fs.CollectionReference> _getTransactionsCollection(int localUserId) async {
    if (!isAuthenticated) throw Exception('Usuário não autenticado');
    final userFirebaseId = await _getOrCreateUserDocument(localUserId);
    return _firestore.collection('users').doc(userFirebaseId).collection('transactions');
  }

  /// Obtém a coleção de membros do usuário
  Future<fs.CollectionReference> _getMembersCollection(int localUserId) async {
    if (!isAuthenticated) throw Exception('Usuário não autenticado');
    final userFirebaseId = await _getOrCreateUserDocument(localUserId);
    return _firestore.collection('users').doc(userFirebaseId).collection('members');
  }

  /// Obtém a coleção de categorias do usuário
  Future<fs.CollectionReference> _getCategoriesCollection(int localUserId) async {
    if (!isAuthenticated) throw Exception('Usuário não autenticado');
    final userFirebaseId = await _getOrCreateUserDocument(localUserId);
    return _firestore.collection('users').doc(userFirebaseId).collection('categories');
  }

  /// Obtém o documento do usuário
  Future<fs.DocumentReference> _getUserDocument(int localUserId) async {
    if (!isAuthenticated) throw Exception('Usuário não autenticado');
    final userFirebaseId = await _getOrCreateUserDocument(localUserId);
    return _firestore.collection('users').doc(userFirebaseId);
  }

  // === SINCRONIZAÇÃO DE TRANSAÇÕES ===

  /// Sincroniza transações locais com Firebase
  Future<void> syncTransactions(List<Transaction> transactions, int localUserId) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      print('Iniciando sincronização de ${transactions.length} transações para usuário $localUserId...');

      // Obter coleção de transações do usuário
      final transactionsCollection = await _getTransactionsCollection(localUserId);
      
      // Obter transações do Firebase para comparação
      final firebaseTransactions = await _getFirebaseTransactions(transactionsCollection);
      final firebaseMap = {for (var t in firebaseTransactions) t.id: t};

      // Processar cada transação local
      for (final transaction in transactions) {
        if (transaction.id == null) continue;

        final firebaseTransaction = firebaseMap[transaction.id];
        
        if (firebaseTransaction == null) {
          // Nova transação - enviar para Firebase
          await _uploadTransaction(transaction, transactionsCollection);
          print('Transação ${transaction.id} enviada para Firebase');
        } else {
          // Transação existe - verificar se precisa atualizar
          if (transaction.updatedAt.isAfter(firebaseTransaction.updatedAt)) {
            await _updateTransaction(transaction, transactionsCollection);
            print('Transação ${transaction.id} atualizada no Firebase');
          }
        }
      }

      // Baixar novas transações do Firebase
      await _downloadNewTransactions(transactions, transactionsCollection);

      print('Sincronização de transações concluída');
    } catch (e) {
      print('Erro na sincronização de transações: $e');
      throw Exception('Erro na sincronização de transações: $e');
    }
  }

  /// Envia uma transação para Firebase
  Future<void> _uploadTransaction(Transaction transaction, fs.CollectionReference collection) async {
    final docRef = collection.doc(transaction.id.toString());
    await docRef.set(transaction.toFirestoreMap());
  }

  /// Atualiza uma transação no Firebase
  Future<void> _updateTransaction(Transaction transaction, fs.CollectionReference collection) async {
    final docRef = collection.doc(transaction.id.toString());
    await docRef.update(transaction.toFirestoreMap());
  }

  /// Obtém todas as transações do Firebase
  Future<List<Transaction>> _getFirebaseTransactions(fs.CollectionReference collection) async {
    final snapshot = await collection.get();
    return snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
  }

  /// Baixa novas transações do Firebase
  Future<void> _downloadNewTransactions(List<Transaction> localTransactions, fs.CollectionReference collection) async {
    final firebaseTransactions = await _getFirebaseTransactions(collection);
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
  Future<void> syncMembers(List<Member> members, int localUserId) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      print('Iniciando sincronização de ${members.length} membros para usuário $localUserId...');

      // Obter coleção de membros do usuário
      final membersCollection = await _getMembersCollection(localUserId);

      for (final member in members) {
        if (member.id == null) continue;

        final docRef = membersCollection.doc(member.id.toString());
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
  Future<void> syncCategories(List<cat.Category> categories, int localUserId) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      print('Iniciando sincronização de ${categories.length} categorias para usuário $localUserId...');

      // Obter coleção de categorias do usuário
      final categoriesCollection = await _getCategoriesCollection(localUserId);

      for (final category in categories) {
        if (category.id == null) continue;

        final docRef = categoriesCollection.doc(category.id.toString());
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
    required int localUserId,
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
      print('Iniciando sincronização completa para usuário $localUserId...');

      // Sincronizar transações
      try {
        await syncTransactions(transactions, localUserId);
        (result['transactions'] as Map<String, int>)['synced'] = transactions.length;
      } catch (e) {
        (result['transactions'] as Map<String, int>)['errors'] = transactions.length;
        (result['errors'] as List<String>).add('Transações: $e');
      }

      // Sincronizar membros
      try {
        await syncMembers(members, localUserId);
        (result['members'] as Map<String, int>)['synced'] = members.length;
      } catch (e) {
        (result['members'] as Map<String, int>)['errors'] = members.length;
        (result['errors'] as List<String>).add('Membros: $e');
      }

      // Sincronizar categorias
      try {
        await syncCategories(categories, localUserId);
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
  Future<Map<String, dynamic>> getSyncStatus(int localUserId) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      final userDoc = await _getUserDocument(localUserId);
      final docSnapshot = await userDoc.get();
      final data = docSnapshot.data() as Map<String, dynamic>?;

      return {
        'lastSync': data?['lastSync']?.toDate(),
        'syncCount': data?['syncCount'] ?? 0,
        'isOnline': true,
        'userId': currentUserId,
        'localUserId': localUserId,
      };
    } catch (e) {
      return {
        'lastSync': null,
        'syncCount': 0,
        'isOnline': false,
        'error': e.toString(),
        'localUserId': localUserId,
      };
    }
  }

  /// Atualiza o status da sincronização
  Future<void> updateSyncStatus(int localUserId) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      final userDoc = await _getUserDocument(localUserId);
      await userDoc.set({
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
  Future<void> clearUserData(int localUserId) async {
    if (!_initialized) await initialize();
    if (!isAuthenticated) throw Exception('Usuário não autenticado');

    try {
      // Obter coleções do usuário
      final transactionsCollection = await _getTransactionsCollection(localUserId);
      final membersCollection = await _getMembersCollection(localUserId);
      final categoriesCollection = await _getCategoriesCollection(localUserId);
      final userDoc = await _getUserDocument(localUserId);
      
      // Deletar todas as subcoleções
      await _deleteCollection(transactionsCollection);
      await _deleteCollection(membersCollection);
      await _deleteCollection(categoriesCollection);
      
      // Deletar documento do usuário
      await userDoc.delete();

      print('Dados do usuário $localUserId limpos no Firebase');
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

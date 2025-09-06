import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class SyncProvider extends ChangeNotifier {
  static SyncProvider? _instance;
  
  // Controle global de operações
  bool _isGlobalOperationInProgress = false;
  Completer<void>? _globalOperationCompleter;
  
  // Controle de navegação
  bool _isNavigating = false;
  Timer? _navigationDebounceTimer;
  
  // Controle de atualizações
  bool _isUpdating = false;
  Timer? _updateDebounceTimer;
  
  // Singleton pattern
  static SyncProvider get instance {
    _instance ??= SyncProvider._internal();
    return _instance!;
  }
  
  SyncProvider._internal();
  
  // Getters
  bool get isGlobalOperationInProgress => _isGlobalOperationInProgress;
  bool get isNavigating => _isNavigating;
  bool get isUpdating => _isUpdating;
  
  // Controle de operações globais
  Future<void> _cancelGlobalOperation() async {
    if (_isGlobalOperationInProgress && _globalOperationCompleter != null) {
      print('=== SYNC PROVIDER: Cancelando operação global anterior ===');
      _globalOperationCompleter!.complete();
      _globalOperationCompleter = null;
      _isGlobalOperationInProgress = false;
    }
  }
  
  void _startGlobalOperation() {
    _cancelGlobalOperation();
    _globalOperationCompleter = Completer<void>();
    _isGlobalOperationInProgress = true;
    print('=== SYNC PROVIDER: Iniciando operação global ===');
    notifyListeners();
  }
  
  void _completeGlobalOperation() {
    if (_globalOperationCompleter != null) {
      _globalOperationCompleter!.complete();
      _globalOperationCompleter = null;
      _isGlobalOperationInProgress = false;
      print('=== SYNC PROVIDER: Operação global concluída ===');
      notifyListeners();
    }
  }
  
  // Controle de navegação
  bool canNavigate() {
    if (_isNavigating) {
      print('=== SYNC PROVIDER: Navegação bloqueada - operação em andamento ===');
      return false;
    }
    return true;
  }
  
  void startNavigation() {
    _isNavigating = true;
    print('=== SYNC PROVIDER: Navegação iniciada ===');
    notifyListeners();
  }
  
  void completeNavigation() {
    _isNavigating = false;
    print('=== SYNC PROVIDER: Navegação concluída ===');
    notifyListeners();
  }
  
  // Controle de atualizações
  bool canUpdate() {
    if (_isUpdating) {
      print('=== SYNC PROVIDER: Atualização bloqueada - operação em andamento ===');
      return false;
    }
    return true;
  }
  
  void startUpdate() {
    _isUpdating = true;
    print('=== SYNC PROVIDER: Atualização iniciada ===');
    notifyListeners();
  }
  
  void completeUpdate() {
    _isUpdating = false;
    print('=== SYNC PROVIDER: Atualização concluída ===');
    notifyListeners();
  }
  
  // Debounce para navegação
  void debounceNavigation(Function callback, {Duration duration = const Duration(milliseconds: 500)}) {
    _navigationDebounceTimer?.cancel();
    _navigationDebounceTimer = Timer(duration, () {
      callback();
    });
  }
  
  // Debounce para atualizações
  void debounceUpdate(Function callback, {Duration duration = const Duration(milliseconds: 300)}) {
    _updateDebounceTimer?.cancel();
    _updateDebounceTimer = Timer(duration, () {
      callback();
    });
  }
  
  // Executar operação com controle global
  Future<T> executeWithGlobalControl<T>(Future<T> Function() operation) async {
    try {
      _startGlobalOperation();
      final result = await operation();
      return result;
    } finally {
      _completeGlobalOperation();
    }
  }
  
  // Limpar timers
  void dispose() {
    _navigationDebounceTimer?.cancel();
    _updateDebounceTimer?.cancel();
    _globalOperationCompleter?.complete();
  }
  
  // Reset de estado
  void reset() {
    super.dispose();
    _isGlobalOperationInProgress = false;
    _isNavigating = false;
    _isUpdating = false;
    _navigationDebounceTimer?.cancel();
    _updateDebounceTimer?.cancel();
    _globalOperationCompleter?.complete();
    print('=== SYNC PROVIDER: Estado resetado ===');
    notifyListeners();
  }
}

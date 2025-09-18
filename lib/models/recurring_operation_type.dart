/// Enum que define os tipos de operação para transações recorrentes
/// 
/// Usado para determinar o escopo de edição ou exclusão:
/// - [thisOnly]: Aplica apenas à transação específica
/// - [thisAndFuture]: Aplica à transação atual e todas as futuras
/// - [allOccurrences]: Aplica a todas as ocorrências (passadas, presente e futuras)
enum RecurringOperationType {
  /// Apenas esta transação específica
  thisOnly('apenas_esta', 'Apenas esta transação'),
  
  /// Esta transação e todas as futuras
  thisAndFuture('esta_e_futuras', 'Esta e futuras transações'),
  
  /// Todas as ocorrências da recorrência
  allOccurrences('todas_ocorrencias', 'Todas as ocorrências');

  const RecurringOperationType(this.value, this.displayName);

  /// Valor usado para persistência e identificação
  final String value;
  
  /// Nome amigável para exibição na interface
  final String displayName;

  /// Converte string para enum
  static RecurringOperationType fromString(String value) {
    return RecurringOperationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RecurringOperationType.thisOnly,
    );
  }

  /// Retorna descrição detalhada da operação
  String getDescription() {
    switch (this) {
      case RecurringOperationType.thisOnly:
        return 'Afeta apenas esta transação específica. A recorrência permanece ativa para outras datas.';
      case RecurringOperationType.thisAndFuture:
        return 'Afeta esta transação e todas as futuras. Transações passadas permanecem inalteradas.';
      case RecurringOperationType.allOccurrences:
        return 'Afeta todas as transações desta recorrência (passadas, presente e futuras).';
    }
  }

  /// Retorna ícone apropriado para cada tipo
  String getIconData() {
    switch (this) {
      case RecurringOperationType.thisOnly:
        return 'single_transaction';
      case RecurringOperationType.thisAndFuture:
        return 'forward_transactions';
      case RecurringOperationType.allOccurrences:
        return 'all_transactions';
    }
  }
}
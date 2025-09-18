import 'package:flutter/material.dart';
import '../models/recurring_operation_type.dart';
import '../models/transaction.dart';

/// Widget de diálogo para escolher o tipo de operação em transações recorrentes
/// 
/// Permite ao usuário escolher entre:
/// - Apenas esta transação
/// - Esta e futuras transações
/// - Todas as ocorrências (para exclusão completa)
class RecurringOperationDialog extends StatefulWidget {
  const RecurringOperationDialog({
    super.key,
    required this.transaction,
    required this.operationType,
    this.showAllOccurrencesOption = false,
  });

  /// Transação que será afetada pela operação
  final Transaction transaction;
  
  /// Tipo de operação (edição ou exclusão)
  final String operationType;
  
  /// Se deve mostrar a opção "Todas as ocorrências"
  final bool showAllOccurrencesOption;

  @override
  State<RecurringOperationDialog> createState() => _RecurringOperationDialogState();
}

class _RecurringOperationDialogState extends State<RecurringOperationDialog> {
  RecurringOperationType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.operationType.toLowerCase().contains('edit');
    final title = isEdit ? 'Editar Transação Recorrente' : 'Remover Transação Recorrente';
    final icon = isEdit ? Icons.edit : Icons.delete;
    final iconColor = isEdit ? Colors.blue : Colors.red;

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações da transação
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          widget.transaction.value > 0 
                            ? Icons.trending_up 
                            : Icons.trending_down,
                          color: widget.transaction.value > 0 
                            ? Colors.green 
                            : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'R\$ ${widget.transaction.value.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: widget.transaction.value > 0 
                              ? Colors.green 
                              : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Membro: ${widget.transaction.associatedMember.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Container(
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
            Text(
              'Como deseja ${isEdit ? 'editar' : 'remover'} esta transação?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Opções de operação
            _buildOperationOption(
              type: RecurringOperationType.thisOnly,
              icon: Icons.event,
              title: 'Apenas esta transação',
              description: isEdit 
                ? 'Edita apenas esta ocorrência específica. A recorrência permanece inalterada para outras datas.'
                : 'Remove apenas esta ocorrência. A recorrência continua ativa para outras datas.',
            ),
            
            const SizedBox(height: 8),
            
            _buildOperationOption(
              type: RecurringOperationType.thisAndFuture,
              icon: Icons.fast_forward,
              title: 'Esta e futuras transações',
              description: isEdit 
                ? 'Edita esta transação e atualiza todas as futuras. Transações passadas permanecem inalteradas.'
                : 'Remove esta transação e todas as futuras. Transações passadas permanecem inalteradas.',
            ),
            
            if (widget.showAllOccurrencesOption) ...[
              const SizedBox(height: 8),
              _buildOperationOption(
                type: RecurringOperationType.allOccurrences,
                icon: Icons.delete_forever,
                title: 'Todas as ocorrências',
                description: 'Remove completamente a recorrência e todas as suas transações (passadas, presente e futuras).',
                isDestructive: true,
              ),
            ],
            
            if (!isEdit) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta ação não pode ser desfeita!',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedType != null 
            ? () => Navigator.of(context).pop(_selectedType)
            : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEdit ? Colors.blue : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(isEdit ? 'Editar' : 'Remover'),
        ),
      ],
    );
  }

  Widget _buildOperationOption({
    required RecurringOperationType type,
    required IconData icon,
    required String title,
    required String description,
    bool isDestructive = false,
  }) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
              ? (isDestructive ? Colors.red : Theme.of(context).primaryColor)
              : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
            ? (isDestructive ? Colors.red.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1))
            : null,
        ),
        child: Row(
          children: [
            Radio<RecurringOperationType>(
              value: type,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
              activeColor: isDestructive ? Colors.red : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              color: isSelected 
                ? (isDestructive ? Colors.red : Theme.of(context).primaryColor)
                : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                        ? (isDestructive ? Colors.red : Theme.of(context).primaryColor)
                        : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Função utilitária para mostrar o diálogo de operação recorrente
Future<RecurringOperationType?> showRecurringOperationDialog({
  required BuildContext context,
  required Transaction transaction,
  required String operationType,
  bool showAllOccurrencesOption = false,
}) {
  return showDialog<RecurringOperationType>(
    context: context,
    builder: (context) => RecurringOperationDialog(
      transaction: transaction,
      operationType: operationType,
      showAllOccurrencesOption: showAllOccurrencesOption,
    ),
  );
}
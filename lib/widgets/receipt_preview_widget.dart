import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt.dart';

/// Widget que mostra o preview dos dados extraídos do cupom fiscal
class ReceiptPreviewWidget extends StatelessWidget {
  final Receipt receipt;
  final File? image;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const ReceiptPreviewWidget({
    super.key,
    required this.receipt,
    this.image,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com status
                _buildStatusHeader(context),
                const SizedBox(height: 16),

                // Imagem em miniatura
                if (image != null) ...[
                  _buildImageThumbnail(),
                  const SizedBox(height: 24),
                ],

                // Informações do estabelecimento
                _buildEstablishmentInfo(context),
                const SizedBox(height: 24),

                // Informações da transação
                _buildTransactionInfo(context),
                const SizedBox(height: 24),

                // Lista de itens
                if (receipt.items.isNotEmpty) ...[
                  _buildItemsList(context),
                  const SizedBox(height: 24),
                ],

                // Informações adicionais
                _buildAdditionalInfo(context),
              ],
            ),
          ),
        ),

        // Botões de ação
        const SizedBox(height: 16),
        _buildActionButtons(context),
      ],
    );
  }

  /// Constrói o header com status do processamento
  Widget _buildStatusHeader(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.status.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  _getStatusDescription(),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói miniatura da imagem
  Widget _buildImageThumbnail() {
    return Center(
      child: Container(
        height: 120,
        width: 90,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image!,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// Constrói informações do estabelecimento
  Widget _buildEstablishmentInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Estabelecimento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Nome', receipt.establishmentName),
            if (receipt.establishmentCnpj != null)
              _buildInfoRow('CNPJ', receipt.establishmentCnpj!),
            if (receipt.establishmentAddress != null)
              _buildInfoRow('Endereço', receipt.establishmentAddress!),
          ],
        ),
      ),
    );
  }

  /// Constrói informações da transação
  Widget _buildTransactionInfo(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Transação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Data/Hora', dateFormat.format(receipt.transactionDate)),
            _buildInfoRow('Valor Total', currencyFormat.format(receipt.totalAmount)),
            if (receipt.paymentMethod != null)
              _buildInfoRow('Pagamento', receipt.paymentMethod!),
            if (receipt.receiptNumber != null)
              _buildInfoRow('Número', receipt.receiptNumber!),
          ],
        ),
      ),
    );
  }

  /// Constrói lista de itens
  Widget _buildItemsList(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Itens (${receipt.items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...receipt.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}${item.unit != null ? ' ${item.unit}' : ''}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      currencyFormat.format(item.totalPrice),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Constrói informações adicionais
  Widget _buildAdditionalInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Informações Adicionais',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (receipt.fiscalKey != null)
              _buildInfoRow('Chave Fiscal', receipt.fiscalKey!),
            _buildInfoRow('Status', receipt.status.displayName),
            _buildInfoRow('Processado em', DateFormat('dd/MM/yyyy HH:mm').format(receipt.createdAt)),
          ],
        ),
      ),
    );
  }

  /// Constrói uma linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói botões de ação
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check),
            label: const Text('Confirmar e Salvar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Retorna a cor baseada no status
  Color _getStatusColor() {
    switch (receipt.status) {
      case ReceiptProcessingStatus.completed:
        return Colors.green;
      case ReceiptProcessingStatus.manualReview:
        return Colors.orange;
      case ReceiptProcessingStatus.error:
        return Colors.red;
      case ReceiptProcessingStatus.processing:
        return Colors.blue;
      case ReceiptProcessingStatus.pending:
        return Colors.grey;
    }
  }

  /// Retorna o ícone baseado no status
  IconData _getStatusIcon() {
    switch (receipt.status) {
      case ReceiptProcessingStatus.completed:
        return Icons.check_circle;
      case ReceiptProcessingStatus.manualReview:
        return Icons.warning;
      case ReceiptProcessingStatus.error:
        return Icons.error;
      case ReceiptProcessingStatus.processing:
        return Icons.hourglass_empty;
      case ReceiptProcessingStatus.pending:
        return Icons.pending;
    }
  }

  /// Retorna a descrição do status
  String _getStatusDescription() {
    switch (receipt.status) {
      case ReceiptProcessingStatus.completed:
        return 'Cupom processado com sucesso';
      case ReceiptProcessingStatus.manualReview:
        return 'Requer revisão manual dos dados';
      case ReceiptProcessingStatus.error:
        return 'Erro no processamento';
      case ReceiptProcessingStatus.processing:
        return 'Processando cupom fiscal';
      case ReceiptProcessingStatus.pending:
        return 'Aguardando processamento';
    }
  }
}
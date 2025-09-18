import 'dart:io';
import 'package:flutter/material.dart';

/// Widget que mostra o progresso do processamento do cupom fiscal
class ReceiptProcessingWidget extends StatelessWidget {
  final double progress;
  final File? image;

  const ReceiptProcessingWidget({
    super.key,
    required this.progress,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Imagem em miniatura
        if (image != null) ...[
          Container(
            height: 200,
            width: 150,
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
          const SizedBox(height: 32),
        ],

        // Indicador de progresso circular
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Texto de status
        Text(
          _getStatusText(progress),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Descrição do processo
        Text(
          _getDescriptionText(progress),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        // Indicador de atividade
        const SizedBox(
          width: 200,
          child: LinearProgressIndicator(),
        ),
      ],
    );
  }

  /// Retorna o texto de status baseado no progresso
  String _getStatusText(double progress) {
    if (progress < 0.3) {
      return 'Extraindo texto...';
    } else if (progress < 0.7) {
      return 'Analisando dados...';
    } else if (progress < 1.0) {
      return 'Finalizando...';
    } else {
      return 'Processamento concluído!';
    }
  }

  /// Retorna a descrição do processo baseado no progresso
  String _getDescriptionText(double progress) {
    if (progress < 0.3) {
      return 'Utilizando OCR para reconhecer o texto do cupom fiscal';
    } else if (progress < 0.7) {
      return 'Interpretando informações como valores, itens e estabelecimento';
    } else if (progress < 1.0) {
      return 'Organizando dados para criar a transação';
    } else {
      return 'Cupom processado com sucesso!';
    }
  }
}
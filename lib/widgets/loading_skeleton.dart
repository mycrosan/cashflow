import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    Key? key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class TransactionSkeleton extends StatelessWidget {
  const TransactionSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone skeleton
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Conteúdo skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 120, height: 16),
                  const SizedBox(height: 8),
                  LoadingSkeleton(width: 80, height: 14),
                ],
              ),
            ),
            // Valor skeleton
            LoadingSkeleton(width: 80, height: 18),
          ],
        ),
      ),
    );
  }
}

class FinancialSummarySkeleton extends StatelessWidget {
  const FinancialSummarySkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título skeleton
            LoadingSkeleton(width: 150, height: 20),
            const SizedBox(height: 24),
            // Cards de receitas e despesas
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCardSkeleton(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCardSkeleton(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Saldo skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LoadingSkeleton(width: 60, height: 16),
                LoadingSkeleton(width: 100, height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardSkeleton() {
    return Column(
      children: [
        // Ícone skeleton
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Label skeleton
        LoadingSkeleton(width: 60, height: 14),
        const SizedBox(height: 4),
        // Valor skeleton
        LoadingSkeleton(width: 80, height: 18),
      ],
    );
  }
}

class MonthHeaderSkeleton extends StatelessWidget {
  const MonthHeaderSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão anterior skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Mês skeleton
          LoadingSkeleton(width: 120, height: 24),
          // Botão próximo skeleton
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionsListSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionsListSkeleton({
    Key? key,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const TransactionSkeleton();
      },
    );
  }
}

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MonthHeaderSkeleton(),
          const SizedBox(height: 24),
          const FinancialSummarySkeleton(),
          const SizedBox(height: 24),
          // Ações rápidas skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 120, height: 18),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildActionButtonSkeleton()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildActionButtonSkeleton()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: LoadingSkeleton(width: 40, height: 40),
        ),
      ),
    );
  }
}

class MonthlyTransactionsSkeleton extends StatelessWidget {
  const MonthlyTransactionsSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MonthHeaderSkeleton(),
        const SizedBox(height: 16),
        // Filtros skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lista de transações skeleton
        const Expanded(
          child: TransactionsListSkeleton(itemCount: 8),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/transactions/add_transaction_page.dart';
import '../providers/floating_button_provider.dart';

class DraggableFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;

  const DraggableFAB({
    Key? key,
    this.onPressed,
    this.icon = Icons.add,
    this.tooltip = 'Adicionar Transação',
    this.backgroundColor = Colors.indigo,
    this.foregroundColor = Colors.white,
  }) : super(key: key);

  @override
  _DraggableFABState createState() => _DraggableFABState();
}

class _DraggableFABState extends State<DraggableFAB> {
  late Size _screenSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  void _updatePosition(Offset newPosition) {
    final provider = Provider.of<FloatingButtonProvider>(context, listen: false);
    final relativePosition = provider.getRelativePosition(newPosition, _screenSize);
    provider.setPosition(relativePosition);
  }

  Offset _getAbsolutePosition() {
    final provider = Provider.of<FloatingButtonProvider>(context, listen: false);
    return provider.getAbsolutePosition(_screenSize);
  }

  void _showTransactionOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Adicionar Transação',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    'Receita',
                    Icons.add_circle,
                    Colors.green,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionPage(
                            initialTransactionType: TransactionType.income,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionButton(
                    'Despesa',
                    Icons.remove_circle,
                    Colors.red,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionPage(
                            initialTransactionType: TransactionType.expense,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FloatingButtonProvider>(
      builder: (context, provider, child) {
        if (!provider.isVisible) {
          return const SizedBox.shrink();
        }

        final absolutePosition = provider.getAbsolutePosition(_screenSize);
        
        return Positioned(
          left: absolutePosition.dx - 28, // 28 é metade do tamanho do FAB
          top: absolutePosition.dy - 28,
          child: GestureDetector(
            onPanStart: (details) {
              provider.setDragging(true);
            },
            onPanUpdate: (details) {
              _updatePosition(details.globalPosition);
            },
            onPanEnd: (details) {
              provider.setDragging(false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()..scale(provider.isDragging ? 1.1 : 1.0),
              child: FloatingActionButton(
                onPressed: widget.onPressed ?? _showTransactionOptions,
                backgroundColor: widget.backgroundColor,
                foregroundColor: widget.foregroundColor,
                tooltip: widget.tooltip,
                child: Icon(widget.icon),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DraggableFABWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onFabPressed;
  final IconData fabIcon;
  final String fabTooltip;
  final Color fabBackgroundColor;
  final Color fabForegroundColor;

  const DraggableFABWrapper({
    Key? key,
    required this.child,
    this.onFabPressed,
    this.fabIcon = Icons.add,
    this.fabTooltip = 'Adicionar Transação',
    this.fabBackgroundColor = Colors.indigo,
    this.fabForegroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FloatingButtonProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            this.child,
            DraggableFAB(
              onPressed: onFabPressed,
              icon: fabIcon,
              tooltip: fabTooltip,
              backgroundColor: fabBackgroundColor,
              foregroundColor: fabForegroundColor,
            ),
          ],
        );
      },
    );
  }
}

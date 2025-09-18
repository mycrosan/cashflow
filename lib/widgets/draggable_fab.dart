import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../pages/transactions/add_transaction_page.dart';
import '../providers/floating_button_provider.dart';

class DraggableFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;

  const DraggableFAB({
    super.key,
    this.onPressed,
    this.icon = Icons.add,
    this.tooltip = 'Adicionar Transação',
    this.backgroundColor = Colors.indigo,
    this.foregroundColor = Colors.white,
  });

  @override
  _DraggableFABState createState() => _DraggableFABState();
}

class _DraggableFABState extends State<DraggableFAB> with TickerProviderStateMixin {
  late Size _screenSize;
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _updatePosition(Offset newPosition) {
    final provider = Provider.of<FloatingButtonProvider>(context, listen: false);
    final relativePosition = provider.getRelativePosition(newPosition, _screenSize);
    provider.setPosition(relativePosition);
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _showTransactionOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Adicionar Transação',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildAppleStyleOptionButton(
                        'Receita',
                        Icons.add_circle_outline,
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTransactionPage(
                                initialTransactionType: TransactionType.income,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAppleStyleOptionButton(
                        'Despesa',
                        Icons.remove_circle_outline,
                        Colors.red,
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTransactionPage(
                                initialTransactionType: TransactionType.expense,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleStyleOptionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
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
          left: absolutePosition.dx - 30,
          top: absolutePosition.dy - 30,
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
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleAnimation, _rippleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: provider.isDragging ? 1.05 : _scaleAnimation.value,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: provider.isDragging ? 20 : 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: provider.isDragging ? 30 : 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple effect
                        if (_rippleAnimation.value > 0)
                          Container(
                            width: 60 * (1 + _rippleAnimation.value * 0.5),
                            height: 60 * (1 + _rippleAnimation.value * 0.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.backgroundColor.withOpacity(0.3 * (1 - _rippleAnimation.value)),
                            ),
                          ),
                        // Main button
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.backgroundColor,
                                widget.backgroundColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onPressed ?? _showTransactionOptions,
                              borderRadius: BorderRadius.circular(30),
                              child: Center(
                                child: Icon(
                                  widget.icon,
                                  color: widget.foregroundColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
    super.key,
    required this.child,
    this.onFabPressed,
    this.fabIcon = Icons.add,
    this.fabTooltip = 'Adicionar Transação',
    this.fabBackgroundColor = Colors.indigo,
    this.fabForegroundColor = Colors.white,
  });

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

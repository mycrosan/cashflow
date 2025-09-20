import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../pages/transactions/add_transaction_page.dart';
import '../providers/floating_button_provider.dart';
import '../providers/transaction_preference_provider.dart';

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

  void _navigateToAddTransaction() {
    final transactionPreferenceProvider = Provider.of<TransactionPreferenceProvider>(context, listen: false);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          initialTransactionType: transactionPreferenceProvider.lastTransactionType,
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
                              onTap: widget.onPressed ?? _navigateToAddTransaction,
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

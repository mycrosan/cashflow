import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A premium, elegant loading animation specifically designed for transaction screens.
/// Features modern design trends including glassmorphism, gradients, and smooth animations
/// that visually imply transaction processing in progress.
class TransactionLoader extends StatefulWidget {
  /// A mensagem a ser exibida abaixo do carregador
  final String message;
  
  /// O tamanho do círculo principal do carregador
  final double size;
  
  /// Se deve mostrar o efeito de pulsação no fundo
  final bool showPulseEffect;
  
  /// Cores personalizadas para o carregador (opcional)
  final Color? primaryColor;
  final Color? secondaryColor;
  
  /// Duração da animação para a rotação principal
  final Duration animationDuration;

  const TransactionLoader({
    Key? key,
    this.message = "Processando sua transação...",
    this.size = 80.0,
    this.showPulseEffect = true,
    this.primaryColor,
    this.secondaryColor,
    this.animationDuration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  State<TransactionLoader> createState() => _TransactionLoaderState();
}

class _TransactionLoaderState extends State<TransactionLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Main rotation animation
    _rotationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Pulse animation for background effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Scale animation for the main loader
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() {
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Default colors based on theme
    final primaryColor = widget.primaryColor ?? 
        (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5));
    final secondaryColor = widget.secondaryColor ?? 
        (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main loader container with glassmorphism effect
          AnimatedBuilder(
            animation: Listenable.merge([
              _rotationAnimation,
              _pulseAnimation,
              _scaleAnimation,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Glassmorphism effect
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        primaryColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing background circle
                      if (widget.showPulseEffect)
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: widget.size * 0.8,
                            height: widget.size * 0.8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primaryColor.withOpacity(0.2),
                                  primaryColor.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Main rotating loader
                      Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _TransactionLoaderPainter(
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                            progress: (_rotationAnimation.value % (2 * math.pi)) / (2 * math.pi),
                          ),
                        ),
                      ),
                      
                      // Center icon with subtle animation
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (_scaleAnimation.value * 0.2),
                            child: Container(
                              width: widget.size * 0.3,
                              height: widget.size * 0.3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: primaryColor,
                                size: widget.size * 0.15,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Animated text with modern typography
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    // Main message
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[800],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Animated dots
                    _AnimatedDots(
                      color: isDark ? Colors.white70 : Colors.grey[600]!,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the main loader with gradient and modern design
class _TransactionLoaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double progress;

  _TransactionLoaderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    // Background circle with subtle gradient
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Main arc with gradient
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withOpacity(0.3),
          secondaryColor.withOpacity(0.8),
          primaryColor,
          secondaryColor.withOpacity(0.6),
          primaryColor.withOpacity(0.3),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    // Draw the main arc
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
    
    // Add a subtle inner arc for depth
    final innerArcPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      startAngle,
      sweepAngle * 0.7,
      false,
      innerArcPaint,
    );
    
    // Add sparkle effects at the end of the arc
    if (progress > 0.1) {
      final sparklePaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      final sparkleAngle = startAngle + sweepAngle;
      final sparkleX = center.dx + (radius - 4) * math.cos(sparkleAngle);
      final sparkleY = center.dy + (radius - 4) * math.sin(sparkleAngle);
      
      // Draw sparkle
      canvas.drawCircle(
        Offset(sparkleX, sparkleY),
        3.0,
        sparklePaint,
      );
      
      // Add glow effect
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(sparkleX, sparkleY),
        6.0,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _TransactionLoaderPainter &&
        oldDelegate.progress != progress;
  }
}

/// Animated dots component for loading text
class _AnimatedDots extends StatefulWidget {
  final Color color;

  const _AnimatedDots({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _animations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.2,
          0.6 + index * 0.2,
          curve: Curves.easeInOut,
        ),
      ));
    });
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: 0.5 + (_animations[index].value * 0.5),
                child: Opacity(
                  opacity: 0.3 + (_animations[index].value * 0.7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Uma versão simplificada do carregador para espaços menores
class CompactTransactionLoader extends StatelessWidget {
  final String message;
  final double size;
  final Color? color;

  const CompactTransactionLoader({
    Key? key,
    this.message = "Processando...",
    this.size = 40.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = color ?? 
        (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          message,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

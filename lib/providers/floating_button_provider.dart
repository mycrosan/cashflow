import 'package:flutter/material.dart';

class FloatingButtonProvider extends ChangeNotifier {
  bool _isVisible = true;
  Offset _position = const Offset(0.8, 0.8); // Posição relativa (0.0 a 1.0)
  bool _isDragging = false;
  bool _showTransactionOptions = true;

  // Getters
  bool get isVisible => _isVisible;
  Offset get position => _position;
  bool get isDragging => _isDragging;
  bool get showTransactionOptions => _showTransactionOptions;

  // Setters
  void setVisible(bool visible) {
    if (_isVisible != visible) {
      _isVisible = visible;
      notifyListeners();
    }
  }

  void setPosition(Offset position) {
    // Garantir que a posição esteja dentro dos limites (0.0 a 1.0)
    final clampedPosition = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );
    
    if (_position != clampedPosition) {
      _position = clampedPosition;
      notifyListeners();
    }
  }

  void setDragging(bool dragging) {
    if (_isDragging != dragging) {
      _isDragging = dragging;
      notifyListeners();
    }
  }

  void setShowTransactionOptions(bool show) {
    if (_showTransactionOptions != show) {
      _showTransactionOptions = show;
      notifyListeners();
    }
  }

  // Métodos de conveniência
  void hide() => setVisible(false);
  void show() => setVisible(true);
  void toggle() => setVisible(!_isVisible);

  // Resetar posição para o canto inferior direito
  void resetPosition() {
    setPosition(const Offset(0.8, 0.8));
  }

  // Converter posição relativa para absoluta
  Offset getAbsolutePosition(Size screenSize) {
    return Offset(
      _position.dx * screenSize.width,
      _position.dy * screenSize.height,
    );
  }

  // Converter posição absoluta para relativa
  Offset getRelativePosition(Offset absolutePosition, Size screenSize) {
    return Offset(
      absolutePosition.dx / screenSize.width,
      absolutePosition.dy / screenSize.height,
    );
  }
}

import 'package:flutter/foundation.dart';

/// Modelo que representa um dispositivo descoberto na rede local
class NetworkDevice {
  /// Nome do dispositivo (pode ser o nome do host ou um nome amigável)
  final String name;
  
  /// Endereço IP do dispositivo
  final String ipAddress;
  
  /// Porta em que o serviço está sendo executado
  final int? port;
  
  /// Identificador único do dispositivo (pode ser um UUID ou outro identificador)
  final String? deviceId;
  
  /// Informações adicionais sobre o dispositivo (versão do app, etc.)
  final Map<String, dynamic>? metadata;
  
  /// Timestamp da última vez que o dispositivo foi visto
  final DateTime lastSeen;
  
  /// Indica se o dispositivo está online
  final bool isOnline;

  NetworkDevice({
    required this.name,
    required this.ipAddress,
    this.port,
    this.deviceId,
    this.metadata,
    DateTime? lastSeen,
    this.isOnline = true,
  }) : lastSeen = lastSeen ?? DateTime.now();

  /// Cria uma cópia deste objeto com os campos especificados substituídos por novos valores
  NetworkDevice copyWith({
    String? name,
    String? ipAddress,
    int? port,
    String? deviceId,
    Map<String, dynamic>? metadata,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return NetworkDevice(
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      deviceId: deviceId ?? this.deviceId,
      metadata: metadata ?? this.metadata,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkDevice && 
           other.ipAddress == ipAddress && 
           other.port == port;
  }

  @override
  int get hashCode => Object.hash(ipAddress, port);

  @override
  String toString() {
    return 'NetworkDevice(name: $name, ipAddress: $ipAddress, port: $port, isOnline: $isOnline)';
  }
}
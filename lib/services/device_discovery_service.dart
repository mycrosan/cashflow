import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/network_device.dart';

/// Serviço responsável por descobrir dispositivos na rede local que executam o aplicativo
class DeviceDiscoveryService {
  static const String _serviceName = '_cashflow._tcp.local';
  static const String _serviceProtocol = '_tcp';
  static const String _serviceType = '_cashflow';
  static const Duration _discoveryTimeout = Duration(seconds: 5);
  static const Duration _advertisementInterval = Duration(seconds: 30);
  
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  final MDnsClient _mdnsClient = MDnsClient();
  
  /// Stream controller para emitir dispositivos descobertos
  final StreamController<List<NetworkDevice>> _devicesController = 
      StreamController<List<NetworkDevice>>.broadcast();
  
  /// Lista de dispositivos descobertos
  final List<NetworkDevice> _discoveredDevices = [];
  
  /// Timer para anunciar periodicamente este dispositivo
  Timer? _advertisementTimer;
  
  /// Indica se o serviço está em execução
  bool _isRunning = false;
  
  /// Stream de dispositivos descobertos
  Stream<List<NetworkDevice>> get devicesStream => _devicesController.stream;
  
  /// Lista atual de dispositivos descobertos
  List<NetworkDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  
  /// Verifica se o dispositivo está conectado a uma rede WiFi
  Future<bool> isWifiConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      debugPrint('Erro ao verificar conexão WiFi: $e');
      return false;
    }
  }
  
  /// Inicia o serviço de descoberta
  Future<void> startDiscovery() async {
    if (_isRunning) return;
    
    _isRunning = true;
    
    try {
      // Verifica se o dispositivo está conectado a uma rede WiFi
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) {
        throw Exception('O dispositivo não está conectado a uma rede WiFi');
      }
      
      // Inicializa o cliente mDNS
      await _mdnsClient.start();
      
      // Anuncia este dispositivo na rede
      await _advertiseService();
      
      // Configura o timer para anunciar periodicamente
      _advertisementTimer = Timer.periodic(
        _advertisementInterval, 
        (_) => _advertiseService()
      );
      
      // Inicia a descoberta de serviços
      _discoverServices();
    } catch (e) {
      _isRunning = false;
      rethrow;
    }
  }
  
  /// Para o serviço de descoberta
  Future<void> stopDiscovery() async {
    if (!_isRunning) return;
    
    _isRunning = false;
    _advertisementTimer?.cancel();
    _advertisementTimer = null;
    
    // Chamada void, não precisa de await
    _mdnsClient.stop();
    
    // Limpa a lista de dispositivos
    _discoveredDevices.clear();
    _devicesController.add(_discoveredDevices);
  }
  
  /// Anuncia este dispositivo na rede
  Future<void> _advertiseService() async {
    try {
      final String? ipAddress = await _networkInfo.getWifiIP();
      if (ipAddress == null) return;
      
      // Gera um ID único para este dispositivo se ainda não existir
      final String deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      
      // Cria um registro PTR para o serviço
      final ptrName = ResourceRecordQuery.serverPointer(_serviceName);
      final ptr = PtrResourceRecord(
        ptrName,
        _serviceName,
        ttl: const Duration(minutes: 1),
      );
      
      // Cria um registro SRV para o serviço
      final srvName = ResourceRecordQuery.service(_serviceName);
      final srv = SrvResourceRecord(
        srvName,
        priority: 0,
        weight: 0,
        port: 8090, // Porta padrão para o serviço
        target: 'device.$deviceId.local',
        ttl: const Duration(minutes: 1),
      );
      
      // Cria um registro TXT com metadados
      final txtName = ResourceRecordQuery.text(_serviceName);
      final txt = TxtResourceRecord(
        txtName,
        'id=$deviceId;version=${await _getAppVersion()};type=mobile',
        ttl: const Duration(minutes: 1),
      );
      
      // Registra os serviços no mDNS
      _mdnsClient.addResourceRecord(ptr);
      _mdnsClient.addResourceRecord(srv);
      _mdnsClient.addResourceRecord(txt);
      
      debugPrint('Serviço anunciado com sucesso: $ipAddress');
    } catch (e) {
      debugPrint('Erro ao anunciar serviço: $e');
    }
  }
  
  /// Obtém a versão do aplicativo
  Future<String> _getAppVersion() async {
    // Versão fixa do aplicativo
    return '1.0.0';
  }
  
  /// Descobre serviços na rede
  Future<void> _discoverServices() async {
    try {
      // Procura por serviços do tipo _cashflow._tcp
      final List<PtrResourceRecord> ptrRecords = await _mdnsClient
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(_serviceName),
          )
          .toList();
      
      for (var ptr in ptrRecords) {
        // Para cada serviço encontrado, busca informações adicionais
        final String serviceName = ptr.domainName;
        
        // Busca o endereço SRV (contém host e porta)
        final List<SrvResourceRecord> srvRecords = await _mdnsClient
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(serviceName),
            )
            .toList();
        
        // Busca o endereço IP
        for (var srv in srvRecords) {
          final List<IPAddressResourceRecord> ipRecords = await _mdnsClient
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )
              .toList();
          
          // Busca informações TXT (metadados)
          final List<TxtResourceRecord> txtRecords = await _mdnsClient
              .lookup<TxtResourceRecord>(
                ResourceRecordQuery.text(serviceName),
              )
              .toList();
          
          // Processa os registros encontrados
          _processRecords(srvRecords, ipRecords, txtRecords);
        }
      }
    } catch (e) {
      debugPrint('Erro ao descobrir serviços: $e');
    }
  }
  
  /// Processa os registros mDNS encontrados
  void _processRecords(
    List<SrvResourceRecord> srvRecords,
    List<IPAddressResourceRecord> ipRecords,
    List<TxtResourceRecord> txtRecords,
  ) {
    for (var srv in srvRecords) {
      for (var ip in ipRecords) {
        // Extrai metadados do registro TXT
        final Map<String, dynamic> metadata = {};
        for (var txt in txtRecords) {
          for (var item in txt.text.split(';')) {
            final parts = item.split('=');
            if (parts.length == 2) {
              metadata[parts[0]] = parts[1];
            }
          }
        }
        
        // Cria um objeto NetworkDevice
        final device = NetworkDevice(
          name: srv.target,
          ipAddress: ip.address.address,
          port: srv.port,
          deviceId: metadata['id'],
          metadata: metadata,
        );
        
        // Adiciona ou atualiza o dispositivo na lista
        _updateDeviceList(device);
      }
    }
  }
  
  /// Atualiza a lista de dispositivos
  void _updateDeviceList(NetworkDevice newDevice) {
    final index = _discoveredDevices.indexWhere((device) => device == newDevice);
    
    if (index >= 0) {
      // Atualiza um dispositivo existente
      _discoveredDevices[index] = newDevice;
    } else {
      // Adiciona um novo dispositivo
      _discoveredDevices.add(newDevice);
    }
    
    // Notifica os ouvintes sobre a mudança
    _devicesController.add(_discoveredDevices);
  }
  
  /// Realiza uma nova busca por dispositivos
  Future<void> refreshDevices() async {
    if (!_isRunning) {
      await startDiscovery();
    } else {
      await _discoverServices();
    }
  }
  
  /// Libera os recursos
  void dispose() {
    stopDiscovery();
    _devicesController.close();
  }
}
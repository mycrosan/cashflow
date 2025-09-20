import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/device_discovery_service.dart';
import '../../models/network_device.dart';

class DeviceDiscoveryPage extends StatefulWidget {
  const DeviceDiscoveryPage({Key? key}) : super(key: key);

  @override
  _DeviceDiscoveryPageState createState() => _DeviceDiscoveryPageState();
}

class _DeviceDiscoveryPageState extends State<DeviceDiscoveryPage> {
  final DeviceDiscoveryService _discoveryService = DeviceDiscoveryService();
  bool _isScanning = false;
  List<NetworkDevice> _discoveredDevices = [];
  String? _errorMessage;
  bool _isWifiConnected = false;

  @override
  void initState() {
    super.initState();
    _checkWifiAndStartDiscovery();
  }

  @override
  void dispose() {
    _discoveryService.stopDiscovery();
    super.dispose();
  }

  Future<void> _checkWifiAndStartDiscovery() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      _isWifiConnected = await _discoveryService.isWifiConnected();
      
      if (_isWifiConnected) {
        await _startDiscovery();
      } else {
        setState(() {
          _errorMessage = 'Conecte-se a uma rede Wi-Fi para descobrir dispositivos';
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao verificar conexão Wi-Fi: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _startDiscovery() async {
    try {
      setState(() {
        _isScanning = true;
        _errorMessage = null;
        _discoveredDevices = [];
      });

      _discoveryService.startDiscovery();
      
      // Ouvir por dispositivos descobertos
      _discoveryService.devicesStream.listen((devices) {
        setState(() {
          _discoveredDevices = devices;
        });
      });

      // Definir um tempo limite para a descoberta (30 segundos)
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _isScanning) {
          setState(() {
            _isScanning = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao iniciar descoberta: $e';
        _isScanning = false;
      });
    }
  }

  void _stopDiscovery() {
    _discoveryService.stopDiscovery();
    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos na Rede'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? _stopDiscovery : _checkWifiAndStartDiscovery,
            tooltip: _isScanning ? 'Parar busca' : 'Iniciar busca',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isWifiConnected) {
      return _buildErrorMessage('Conecte-se a uma rede Wi-Fi para descobrir dispositivos');
    }

    if (_errorMessage != null) {
      return _buildErrorMessage(_errorMessage!);
    }

    if (_isScanning && _discoveredDevices.isEmpty) {
      return _buildLoadingState();
    }

    return _buildDevicesList();
  }

  Widget _buildErrorMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkWifiAndStartDiscovery,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Buscando dispositivos na rede...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Isso pode levar até 30 segundos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList() {
    if (_discoveredDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum dispositivo encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkWifiAndStartDiscovery,
              icon: const Icon(Icons.refresh),
              label: const Text('Buscar Novamente'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = _discoveredDevices[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withOpacity(0.1),
              child: const Icon(
                Icons.smartphone,
                color: Colors.indigo,
              ),
            ),
            title: Text(
              device.name ?? 'Dispositivo ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(device.ipAddress ?? 'Endereço IP desconhecido'),
            trailing: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: device.isOnline ? Colors.green : Colors.grey,
              ),
            ),
            onTap: () {
              _showDeviceDetails(device);
            },
          ),
        );
      },
    );
  }

  void _showDeviceDetails(NetworkDevice device) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalhes do Dispositivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Nome', device.name ?? 'Desconhecido'),
              _buildDetailRow('Endereço IP', device.ipAddress ?? 'Desconhecido'),
              _buildDetailRow('Porta', device.port?.toString() ?? 'Padrão'),
              _buildDetailRow('ID do Dispositivo', device.deviceId ?? 'Desconhecido'),
              _buildDetailRow('Status', device.isOnline ? 'Online' : 'Offline'),
              _buildDetailRow('Última Visualização', device.lastSeen != null 
                ? '${device.lastSeen!.day}/${device.lastSeen!.month}/${device.lastSeen!.year} ${device.lastSeen!.hour}:${device.lastSeen!.minute}'
                : 'Desconhecido'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
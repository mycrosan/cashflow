import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/backup_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/transaction_loader.dart';

class BackupPage extends StatefulWidget {
  @override
  _BackupPageState createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupService _backupService = BackupService();
  
  List<BackupInfo> _backups = [];
  bool _isLoading = false;
  bool _isCreatingBackup = false;
  DateTime? _lastBackupDate;
  bool _backupEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        _backupService.getAvailableBackups(),
        _backupService.getLastBackupDate(),
        _backupService.isBackupEnabled(),
      ]);
      
      setState(() {
        _backups = futures[0] as List<BackupInfo>;
        _lastBackupDate = futures[1] as DateTime?;
        _backupEnabled = futures[2] as bool;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      _showErrorSnackBar('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup e Restore'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? TransactionLoader(message: 'Carregando backups...')
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status do backup
          _buildBackupStatus(),
          SizedBox(height: 24),

          // Criar novo backup
          _buildCreateBackup(),
          SizedBox(height: 24),

          // Lista de backups
          _buildBackupsList(),
        ],
      ),
    );
  }

  Widget _buildBackupStatus() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _backupEnabled ? Icons.cloud_done : Icons.cloud_off,
                  color: _backupEnabled ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  'Status do Backup',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (_lastBackupDate != null) ...[
              Text(
                'Último backup: ${_formatDate(_lastBackupDate!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 8),
            ],
            
            Text(
              'Backup ${_backupEnabled ? 'habilitado' : 'desabilitado'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _backupEnabled ? Colors.green : Colors.grey,
              ),
            ),
            
            SizedBox(height: 16),
            
            SwitchListTile(
              title: Text('Backup automático'),
              subtitle: Text('Fazer backup automaticamente'),
              value: _backupEnabled,
              onChanged: (value) async {
                await _backupService.setBackupEnabled(value);
                setState(() => _backupEnabled = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateBackup() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Criar Backup',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Faça backup de todos os seus dados para o Firestore',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            
            if (_isCreatingBackup)
              TransactionLoader(message: 'Criando backup...')
            else
              CustomButton(
                text: 'Criar Backup Agora',
                onPressed: _createBackup,
                backgroundColor: Colors.green,
                icon: Icons.backup,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupsList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backups Disponíveis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            if (_backups.isEmpty)
              _buildEmptyBackups()
            else
              ..._backups.map((backup) => _buildBackupItem(backup)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBackups() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.backup_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum backup encontrado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Crie seu primeiro backup para proteger seus dados',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupItem(BackupInfo backup) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.backup, color: Colors.white),
        ),
        title: Text('Backup ${backup.formattedDate}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${backup.dataCount} itens • ${backup.formattedSize}'),
            Text('ID: ${backup.id.substring(0, 8)}...'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleBackupAction(value, backup),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Restaurar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    
    try {
      final result = await _backupService.createBackup();
      
      if (result.success) {
        _showSuccessSnackBar(result.message);
        await _loadData(); // Recarregar lista de backups
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao criar backup: $e');
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  void _handleBackupAction(String action, BackupInfo backup) {
    switch (action) {
      case 'restore':
        _showRestoreConfirmation(backup);
        break;
      case 'delete':
        _showDeleteConfirmation(backup);
        break;
    }
  }

  void _showRestoreConfirmation(BackupInfo backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja restaurar este backup?'),
            SizedBox(height: 16),
            Text('Backup: ${backup.formattedDate}'),
            Text('Itens: ${backup.dataCount}'),
            SizedBox(height: 8),
            Text(
              'ATENÇÃO: Esta ação irá substituir todos os dados atuais!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restoreBackup(backup.id);
            },
            child: Text('Restaurar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BackupInfo backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir este backup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteBackup(backup.id);
            },
            child: Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(String backupId) async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _backupService.restoreFromBackup(backupId);
      
      if (result.success) {
        _showSuccessSnackBar(result.message);
        // Opcional: navegar de volta para a home
        Navigator.of(context).pop();
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao restaurar backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    try {
      final success = await _backupService.deleteBackup(backupId);
      
      if (success) {
        _showSuccessSnackBar('Backup excluído com sucesso');
        await _loadData(); // Recarregar lista
      } else {
        _showErrorSnackBar('Erro ao excluir backup');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao excluir backup: $e');
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}


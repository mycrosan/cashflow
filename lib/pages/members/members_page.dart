import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/custom_button.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().loadMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Membros da Família'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddMemberDialog(context);
              },
            ),
          ],
        ),
        body: Consumer<MemberProvider>(
          builder: (context, memberProvider, child) {
            if (memberProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (memberProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erro: ${memberProvider.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => memberProvider.loadMembers(),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }

            if (memberProvider.members.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum membro cadastrado',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicione os membros da sua família para começar',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Adicionar Primeiro Membro',
                      onPressed: () {
                        _showAddMemberDialog(context);
                      },
                      icon: Icons.add,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: memberProvider.members.length,
              itemBuilder: (context, index) {
                final member = memberProvider.members[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(member.relation),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        _handleMemberAction(value, member);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Excluir', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Membro'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: 'Relação (ex: Pai, Mãe, Filho)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Relação é obrigatória';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final memberProvider = Provider.of<MemberProvider>(context, listen: false);
                final success = await memberProvider.addMember(
                  nameController.text.trim(),
                  relationController.text.trim(),
                  null, // profilePicture
                );
                
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membro adicionado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao adicionar membro'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _handleMemberAction(String action, member) {
    switch (action) {
      case 'edit':
        _showEditMemberDialog(context, member);
        break;
      case 'delete':
        _showDeleteMemberDialog(context, member);
        break;
    }
  }

  void _showEditMemberDialog(BuildContext context, member) {
    final nameController = TextEditingController(text: member.name);
    final relationController = TextEditingController(text: member.relation);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Membro'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: 'Relação (ex: Pai, Mãe, Filho)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Relação é obrigatória';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final memberProvider = Provider.of<MemberProvider>(context, listen: false);
                final success = await memberProvider.updateMember(
                  member.copyWith(
                    name: nameController.text.trim(),
                    relation: relationController.text.trim(),
                  ),
                );
                
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membro atualizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao atualizar membro'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMemberDialog(BuildContext context, member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Membro'),
        content: Text('Tem certeza que deseja excluir "${member.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final memberProvider = Provider.of<MemberProvider>(context, listen: false);
              final success = await memberProvider.deleteMember(member.id!);
              
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Membro excluído com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao excluir membro'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

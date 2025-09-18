import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/custom_button.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Categorias'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddCategoryDialog(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'all',
                          label: Text('Todas'),
                        ),
                        ButtonSegment(
                          value: 'income',
                          label: Text('Receitas'),
                        ),
                        ButtonSegment(
                          value: 'expense',
                          label: Text('Despesas'),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Lista de categorias
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (categoryProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Erro: ${categoryProvider.error}',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => categoryProvider.loadCategories(),
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredCategories = _selectedType == 'all'
                      ? categoryProvider.categories
                      : categoryProvider.categories.where((cat) => cat.type == _selectedType).toList();

                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.category, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma categoria encontrada',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicione categorias para organizar suas transações',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'Adicionar Primeira Categoria',
                            onPressed: () {
                              _showAddCategoryDialog(context);
                            },
                            icon: Icons.add,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: category.type == 'income' 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            child: Icon(
                              category.type == 'income' ? Icons.trending_up : Icons.trending_down,
                              color: category.type == 'income' ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(category.type == 'income' ? 'Receita' : 'Despesa'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              _handleCategoryAction(value, category);
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
            ),
          ],
        ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'expense';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar Categoria'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Categoria',
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
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'income',
                      child: Text('Receita'),
                    ),
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text('Despesa'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
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
                  final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                  final success = await categoryProvider.addCategory(
                    nameController.text.trim(),
                    selectedType,
                    null, // icon
                    null, // color
                  );
                  
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Categoria adicionada com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao adicionar categoria'),
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
      ),
    );
  }

  void _handleCategoryAction(String action, category) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(context, category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(context, category);
        break;
    }
  }

  void _showEditCategoryDialog(BuildContext context, category) {
    final nameController = TextEditingController(text: category.name);
    String selectedType = category.type;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Categoria'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Categoria',
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
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'income',
                      child: Text('Receita'),
                    ),
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text('Despesa'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
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
                  final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                  final success = await categoryProvider.updateCategory(
                    category.copyWith(
                      name: nameController.text.trim(),
                      type: selectedType,
                    ),
                  );
                  
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Categoria atualizada com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao atualizar categoria'),
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
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Tem certeza que deseja excluir "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
              final success = await categoryProvider.deleteCategory(category.id!);
              
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Categoria excluída com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao excluir categoria'),
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

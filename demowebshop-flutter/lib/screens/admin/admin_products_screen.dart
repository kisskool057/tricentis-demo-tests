import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/database_service.dart';

/// Gestion des produits (back office)
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(context, null),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(productProvider),
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildProductList(productProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ProductProvider provider) {
    // Extraire les catégories uniques des produits
    final categoriesSet = provider.allProducts.map((p) => p.category).toSet();
    final categories = ['all', ...categoriesSet];
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category == 'all' ? 'Tous' : category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList(ProductProvider provider) {
    final products = _selectedCategory == 'all'
        ? provider.allProducts
        : provider.allProducts.where((p) => p.category == _selectedCategory).toList();

    if (products.isEmpty) {
      return const Center(
        child: Text('Aucun produit dans cette catégorie'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: product.imageUrl != null
              ? ClipOval(child: Image.network(product.imageUrl!, fit: BoxFit.cover))
              : Icon(Icons.shopping_bag, color: Colors.grey[400]),
        ),
        title: Text(product.name),
        subtitle: Text('${product.category} • ${product.formattedPrice}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showProductDialog(context, product),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(product),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProductDialog(BuildContext context, Product? product) async {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final categoryController = TextEditingController(text: product?.category ?? '');
    final imageController = TextEditingController(text: product?.imageUrl ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Modifier le produit' : 'Nouveau produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'URL Image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEdit ? 'Modifier' : 'Créer'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final newProduct = Product(
        id: product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text,
        description: descController.text,
        price: double.tryParse(priceController.text) ?? 0,
        category: categoryController.text,
        imageUrl: imageController.text.isEmpty ? null : imageController.text,
        isAvailable: product?.isAvailable ?? true,
        createdAt: product?.createdAt ?? DateTime.now(),
      );

      final dbService = DatabaseService.instance;
      if (isEdit) {
        await dbService.updateProduct(newProduct);
      } else {
        await dbService.addProduct(newProduct);
      }

      if (context.mounted) {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Produit modifié' : 'Produit créé')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final dbService = DatabaseService.instance;
      await dbService.deleteProduct(product.id);
      
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé')),
        );
      }
    }
  }
}

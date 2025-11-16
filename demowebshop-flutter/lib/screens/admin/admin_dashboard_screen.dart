import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/database_service.dart';
import '../../models/order.dart';

/// Tableau de bord administrateur
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final dbService = DatabaseService.instance;
    final orders = await dbService.getAllOrders();
    final products = await dbService.getProducts();
    
    setState(() {
      _stats = {
        'totalOrders': orders.length,
        'pendingOrders': orders.where((o) => o.status == OrderStatus.pending).length,
        'totalProducts': products.length,
        'totalRevenue': orders.fold(0.0, (sum, order) => sum + order.total),
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue ${authProvider.currentUser?.fullName ?? "Admin"}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Commandes totales',
          '${_stats['totalOrders']}',
          Icons.shopping_bag,
          Colors.blue,
        ),
        _buildStatCard(
          'En attente',
          '${_stats['pendingOrders']}',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Produits',
          '${_stats['totalProducts']}',
          Icons.inventory,
          Colors.green,
        ),
        _buildStatCard(
          'Revenu total',
          '€${(_stats['totalRevenue'] as double).toStringAsFixed(2)}',
          Icons.euro,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.shopping_bag, color: Colors.blue),
          title: const Text('Gérer les commandes'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Navigator.pushNamed(context, '/admin/orders'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.inventory, color: Colors.green),
          title: const Text('Gérer les produits'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Navigator.pushNamed(context, '/admin/products'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.people, color: Colors.purple),
          title: const Text('Gérer les utilisateurs'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Navigator.pushNamed(context, '/admin/users'),
        ),
      ],
    );
  }
}

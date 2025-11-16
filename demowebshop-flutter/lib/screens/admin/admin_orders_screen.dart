import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';

/// Gestion des commandes (back office)
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final dbService = DatabaseService.instance;
    final orders = await dbService.getAllOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  List<Order> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    final status = _parseOrderStatus(_filterStatus);
    return _orders.where((o) => o.status == status).toList();
  }

  OrderStatus _parseOrderStatus(String status) {
    switch (status) {
      case 'pending': return OrderStatus.pending;
      case 'processing': return OrderStatus.processing;
      case 'shipped': return OrderStatus.shipped;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des commandes'),
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = [
      {'value': 'all', 'label': 'Toutes'},
      {'value': 'pending', 'label': 'En attente'},
      {'value': 'confirmed', 'label': 'Confirmées'},
      {'value': 'shipped', 'label': 'Expédiées'},
      {'value': 'delivered', 'label': 'Livrées'},
      {'value': 'cancelled', 'label': 'Annulées'},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _filterStatus == status['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filterStatus = status['value']!;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return const Center(
        child: Text('Aucune commande'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          _getStatusIcon(order.status.name),
          color: _getStatusColor(order.status.name),
        ),
        title: Text('Commande #${order.id.substring(0, 8)}'),
        subtitle: Text(
          '${order.items.length} article(s) • ${order.formattedTotal}\n${_formatDate(order.createdAt)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client: ${order.userId}'),
                Text('Adresse: ${order.shippingAddress.address1}'),
                const Divider(height: 24),
                const Text(
                  'Articles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${item.product.name} x${item.quantity} (${item.formattedSubtotal})'),
                )),
                const Divider(height: 24),
                _buildStatusSelector(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(Order order) {
    return DropdownButtonFormField<OrderStatus>(
      value: order.status,
      decoration: const InputDecoration(
        labelText: 'Statut de la commande',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: OrderStatus.pending, child: Text('En attente')),
        DropdownMenuItem(value: OrderStatus.processing, child: Text('En traitement')),
        DropdownMenuItem(value: OrderStatus.shipped, child: Text('Expédiée')),
        DropdownMenuItem(value: OrderStatus.delivered, child: Text('Livrée')),
        DropdownMenuItem(value: OrderStatus.cancelled, child: Text('Annulée')),
      ],
      onChanged: (newStatus) {
        if (newStatus != null) {
          _updateOrderStatus(order, newStatus);
        }
      },
    );
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    final dbService = DatabaseService.instance;
    final updatedOrder = order.copyWith(status: newStatus);
    await dbService.updateOrderStatus(order.id, newStatus.name);
    
    setState(() {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut mis à jour')),
      );
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'confirmed': return Icons.check_circle;
      case 'shipped': return Icons.local_shipping;
      case 'delivered': return Icons.done_all;
      case 'cancelled': return Icons.cancel;
      default: return Icons.shopping_bag;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

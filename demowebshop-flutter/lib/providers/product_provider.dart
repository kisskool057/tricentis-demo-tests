import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/database_service.dart';

/// Provider pour la gestion des produits
///
/// Gère l'état du catalogue de produits et expose les méthodes
/// pour charger, filtrer et rechercher des produits
class ProductProvider with ChangeNotifier {
  final DatabaseService _dbService;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;

  ProductProvider(this._dbService);

  /// Liste de tous les produits
  List<Product> get allProducts => List.unmodifiable(_allProducts);

  /// Liste des produits filtrés/recherchés
  List<Product> get products => List.unmodifiable(_filteredProducts);

  /// Catégorie actuellement sélectionnée
  String? get selectedCategory => _selectedCategory;

  /// Requête de recherche actuelle
  String get searchQuery => _searchQuery;

  /// Indique si une opération est en cours
  bool get isLoading => _isLoading;

  /// Nombre total de produits
  int get totalProducts => _allProducts.length;

  /// Nombre de produits filtrés
  int get filteredProductsCount => _filteredProducts.length;

  /// Charge tous les produits depuis la base de données
  Future<void> loadProducts() async {
    print('📦 ProductProvider: Début du chargement des produits...');
    _isLoading = true;
    notifyListeners();

    try {
      print('🔍 ProductProvider: Appel de getProducts()...');
      _allProducts = await _dbService.getProducts();
      _filteredProducts = _allProducts;
      print('✅ ProductProvider: ${_allProducts.length} produits chargés');
    } catch (e, stackTrace) {
      print('❌ ProductProvider: Erreur lors du chargement des produits: $e');
      print('📋 Stack trace: $stackTrace');
      _allProducts = [];
      _filteredProducts = [];
    }

    _isLoading = false;
    notifyListeners();
    print('🏁 ProductProvider: Chargement terminé (isLoading=$_isLoading)');
  }

  /// Filtre les produits par catégorie
  Future<void> filterByCategory(String? category) async {
    _selectedCategory = category;
    _searchQuery = '';

    if (category == null) {
      _filteredProducts = _allProducts;
    } else {
      _isLoading = true;
      notifyListeners();

      try {
        _filteredProducts = await _dbService.getProductsByCategory(category);
      } catch (e) {
        debugPrint('Erreur lors du filtrage par catégorie: $e');
        _filteredProducts = [];
      }

      _isLoading = false;
    }

    notifyListeners();
  }

  /// Recherche des produits par nom ou description
  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();
    _selectedCategory = null;

    if (_searchQuery.isEmpty) {
      _filteredProducts = _allProducts;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _filteredProducts = await _dbService.searchProducts(_searchQuery);
    } catch (e) {
      debugPrint('Erreur lors de la recherche: $e');
      _filteredProducts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Réinitialise les filtres et affiche tous les produits
  void resetFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _filteredProducts = _allProducts;
    notifyListeners();
  }

  /// Récupère un produit par son ID
  Future<Product?> getProductById(String id) async {
    try {
      // D'abord chercher dans la liste en mémoire
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (e) {
      // Si pas trouvé, chercher dans la base de données
      return await _dbService.getProductById(id);
    }
  }

  /// Récupère les catégories uniques des produits
  List<String> getCategories() {
    final categories = _allProducts.map((p) => p.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Récupère le nombre de produits par catégorie
  Map<String, int> getProductCountByCategory() {
    final Map<String, int> counts = {};
    for (final product in _allProducts) {
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }
    return counts;
  }
}

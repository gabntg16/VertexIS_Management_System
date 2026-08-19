import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'sqlite_service.dart';

class DataService extends ChangeNotifier {
  static const _uuid = Uuid();

  List<UserModel> _users = [];
  List<Branch> _branches = [];
  List<Product> _products = [];
  List<Order> _orders = [];
  List<Payment> _payments = [];
  List<Delivery> _deliveries = [];
  List<Receiving> _receivings = [];
  List<InventoryItem> _inventory = [];
  List<Sale> _sales = [];
  List<Announcement> _announcements = [];
  List<CalendarEvent> _events = [];

  UserModel? currentUser;
  ThemeMode _themeMode = ThemeMode.system;

  // Navigation State
  int _adminTabIndex = 0;
  int _branchTabIndex = 0;

  ThemeMode get themeMode => _themeMode;
  int get adminTabIndex => _adminTabIndex;
  int get branchTabIndex => _branchTabIndex;

  void setAdminTab(int index) {
    _adminTabIndex = index;
    notifyListeners();
  }

  void setBranchTab(int index) {
    _branchTabIndex = index;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _themeMode.name);
    notifyListeners();
  }

  List<UserModel> get users => List.unmodifiable(_users);
  List<Branch> get branches => List.unmodifiable(_branches);
  List<Product> get products => List.unmodifiable(_products);
  List<Order> get orders {
    final sorted = List.of(_orders);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  String _normalizeBranchId(String name) {
    var slug = name.toLowerCase().trim().replaceAll(RegExp('[^a-z0-9]+'), '-');
    slug = slug.replaceAll(RegExp('^-+|-+\$'), '');
    if (slug.isEmpty) {
      slug = _uuid.v4().split('-').first;
    }
    return 'b-$slug';
  }

  Future<void> addBranch(String name, String location) async {
    final normalizedName = name.trim();
    final normalizedLocation = location.trim();
    if (normalizedName.isEmpty || normalizedLocation.isEmpty) return;

    var branchId = _normalizeBranchId(normalizedName);
    var suffix = 1;
    while (_branches.any((b) => b.id == branchId)) {
      branchId = '${_normalizeBranchId(normalizedName)}-${suffix++}';
    }

    final branch = Branch(
        id: branchId, name: normalizedName, location: normalizedLocation);
    _branches.add(branch);

    final user = UserModel(
      id: 'u-$branchId',
      name: '${branch.name} Manager',
      email: '${branchId.replaceFirst('b-', '')}@marshbites.com',
      password: 'branch123',
      role: 'branch',
      branchId: branch.id,
    );
    _users.add(user);

    for (final product in _products) {
      _inventory.add(InventoryItem(
        id: _uuid.v4(),
        branchId: branch.id,
        productId: product.id,
        productName: '${product.flavor} (${product.name})',
        stock: 0,
      ));
    }

    await _persist();
    notifyListeners();
  }

  List<CalendarEvent> get events => List.unmodifiable(_events);
  List<Sale> get sales => List.unmodifiable(_sales);

  List<CalendarEvent> get branchEvents {
    if (currentUser == null || currentUser!.branchId == null) {
      return [];
    }
    return _events.where((e) => e.branchId == currentUser!.branchId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Delivery> get deliveries => List.unmodifiable(_deliveries);
  List<Receiving> get receivings => List.unmodifiable(_receivings);
  List<Announcement> get announcements => List.unmodifiable(_announcements);

  List<Order> get allOrders {
    final sorted = List.of(_orders);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  // Admin Getters
  int get totalBranches => _branches.length;
  int get totalProducts => _products.length;
  int get pendingOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.waitingApproval).length;
  double get totalRevenue => _sales.fold(0, (sum, s) => sum + s.total);

  double branchRevenue(String branchId) =>
      getSalesForBranch(branchId).fold(0, (sum, s) => sum + s.total);

  int branchPendingApprovals(String branchId) => getOrdersForBranch(branchId)
      .where((o) => o.status == OrderStatus.waitingApproval)
      .length;

  int branchStockCount(String branchId) => _inventory
      .where((i) => i.branchId == branchId)
      .fold(0, (sum, i) => sum + i.stock);

  List<Branch> get topBranchesByRevenue {
    final branches = List.of(_branches);
    branches.sort((a, b) => branchRevenue(b.id).compareTo(branchRevenue(a.id)));
    return List.unmodifiable(branches);
  }

  List<Order> getOrdersForBranch(String branchId) =>
      _orders.where((o) => o.branchId == branchId).toList();

  List<Sale> getSalesForBranch(String branchId) =>
      _sales.where((s) => s.branchId == branchId).toList();

  List<Order> get branchOrders {
    if (currentUser == null) return [];
    return _orders.where((o) => o.branchId == currentUser!.branchId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Delivery> get branchDeliveries {
    if (currentUser == null || currentUser!.branchId == null) return [];
    return _deliveries
        .where((d) => d.branchId == currentUser!.branchId)
        .toList();
  }

  List<Delivery> orderDeliveries(String orderId) =>
      _deliveries.where((d) => d.orderId == orderId).toList();

  List<Receiving> orderReceivings(String orderId) =>
      _receivings.where((r) => r.orderId == orderId).toList();

  List<Receiving> get branchReceivings {
    if (currentUser == null || currentUser!.branchId == null) return [];
    return _receivings
        .where((r) => r.branchId == currentUser!.branchId)
        .toList();
  }

  List<InventoryItem> get branchInventory {
    if (currentUser == null) return [];
    return _inventory
        .where((i) => i.branchId == currentUser!.branchId)
        .toList();
  }

  List<Sale> get branchSales {
    if (currentUser == null) return [];
    return _sales.where((s) => s.branchId == currentUser!.branchId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Sale> salesForBranchProduct(String branchId, String productId) {
    return _sales
        .where(
            (sale) => sale.branchId == branchId && sale.productId == productId)
        .toList();
  }

  double averageDailyQuantityForProduct(
      String branchId, String productId, int days) {
    final sales =
        _salesInLastDays(salesForBranchProduct(branchId, productId), days);
    if (sales.isEmpty) return 0.0;
    final totalQuantity =
        sales.fold<int>(0, (sum, sale) => sum + sale.quantity);
    return totalQuantity / days;
  }

  List<RestockSuggestion> restockSuggestionsForBranch(String branchId) {
    final inventory = _inventory.where((i) => i.branchId == branchId).toList();
    if (inventory.isEmpty) return [];

    const historyDays = 14;
    const forecastDays = 7;
    const safetyBuffer = 5;

    return inventory
        .map((item) {
          final avgDaily = averageDailyQuantityForProduct(
              branchId, item.productId, historyDays);
          final expectedWeekly = avgDaily * forecastDays;
          final suggestedOrder =
              expectedWeekly.ceil() + safetyBuffer - item.stock;
          return RestockSuggestion(
            productId: item.productId,
            productName: item.productName,
            currentStock: item.stock,
            averageDailyQuantity: avgDaily,
            expectedWeeklyDemand: expectedWeekly,
            suggestedOrderQuantity: suggestedOrder > 0 ? suggestedOrder : 0,
          );
        })
        .where((suggestion) => suggestion.suggestedOrderQuantity > 0)
        .toList()
      ..sort((a, b) =>
          b.suggestedOrderQuantity.compareTo(a.suggestedOrderQuantity));
  }

  List<RestockSuggestion> get branchRestockSuggestions {
    if (currentUser == null || currentUser!.branchId == null) return [];
    return restockSuggestionsForBranch(currentUser!.branchId!);
  }

  /// Aggregates restock suggestions across all branches for Admin production planning.
  List<Map<String, dynamic>> get adminRestockInsights {
    final List<Map<String, dynamic>> insights = [];
    for (final branch in _branches) {
      final suggestions = restockSuggestionsForBranch(branch.id);
      if (suggestions.isNotEmpty) {
        for (final s in suggestions) {
          insights.add({
            'branchName': branch.name,
            'productName': s.productName,
            'suggested': s.suggestedOrderQuantity,
            'urgency': s.urgency,
          });
        }
      }
    }
    return insights
      ..sort(
          (a, b) => (b['suggested'] as int).compareTo(a['suggested'] as int));
  }

  List<Sale> _salesInLastDays(List<Sale> sales, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return sales.where((sale) => sale.date.isAfter(cutoff)).toList();
  }

  double _averageDailySales(List<Sale> sales, int days) {
    if (sales.isEmpty) return 0.0;
    final total = sales.fold(0.0, (sum, sale) => sum + sale.total);
    return total / days;
  }

  double get branchAverageDailySales =>
      _averageDailySales(_salesInLastDays(branchSales, 7), 7);

  double get branchWeeklyDemandForecast => branchAverageDailySales * 7;

  String get branchDemandForecast {
    if (currentUser == null) return 'No demand data';
    if (branchSales.isEmpty) return 'No demand data';
    final forecast = branchWeeklyDemandForecast;
    if (forecast >= 25000) return 'High demand';
    if (forecast >= 15000) return 'Growing demand';
    return 'Stable demand';
  }

  double get overallAverageDailySales =>
      _averageDailySales(_salesInLastDays(_sales, 7), 7);

  double get overallWeeklyDemandForecast => overallAverageDailySales * 7;

  String get overallDemandForecast {
    if (_sales.isEmpty) return 'No demand data';
    final forecast = overallWeeklyDemandForecast;
    if (forecast >= 80000) return 'High demand';
    if (forecast >= 40000) return 'Growing demand';
    return 'Stable demand';
  }

  String demandForecastForBranch(String branchId) {
    final branchSales = _sales.where((s) => s.branchId == branchId).toList();
    if (branchSales.isEmpty) return 'No demand data';
    final forecast =
        _averageDailySales(_salesInLastDays(branchSales, 7), 7) * 7;
    if (forecast >= 25000) return 'High demand';
    if (forecast >= 15000) return 'Growing demand';
    return 'Stable demand';
  }

  double weeklyDemandAmountForBranch(String branchId) {
    final branchSales = _sales.where((s) => s.branchId == branchId).toList();
    return _averageDailySales(_salesInLastDays(branchSales, 7), 7) * 7;
  }

  List<Payment> get allPayments => List.unmodifiable(_payments);

  double get branchTotalSales => branchSales.fold(0, (sum, s) => sum + s.total);

  int get branchPendingOrders =>
      branchOrders.where((o) => o.status == OrderStatus.pending).length;

  int get branchTotalInventory =>
      branchInventory.fold(0, (sum, i) => sum + i.stock);

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    await SqliteService.instance.init();

    // Load theme
    final savedTheme = prefs.getString('theme');
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    try {
      // Prefer SQLite-stored data. If not present, fall back to SharedPreferences and migrate.
      final rawSql = await SqliteService.instance.getString('db');
      String? raw = rawSql;
      if (raw == null) {
        raw = prefs.getString('db');
        if (raw != null) {
          // migrate into sqlite
          await SqliteService.instance.setString('db', raw);
          await prefs.remove('db');
        }
      }

      if (raw != null) {
        final Map<String, dynamic> data = jsonDecode(raw);
        _load(data);

        // Rebranding check: If we find "Milk Tea" in the products, wipe and re-seed
        final hasLegacyData = _products.any((p) =>
            p.name.contains('Milk Tea') || p.flavor.contains('Milk Tea'));
        if (hasLegacyData) {
          debugPrint(
              'DataService: Legacy milk tea data detected. Wiping for rebranding...');
          _users.clear(); // This will trigger _seed() below
        }
      }
    } catch (e) {
      debugPrint('DataService: Error loading persistent data: $e');
      // If parsing fails, _users remains empty, triggering _seed() below.
    }

    // Ensure we always have at least the admin user if something went wrong
    if (_users.isEmpty) {
      debugPrint('DataService: No users found, seeding default data...');
      _seed();
      await _persist(prefs);
    }
  }

  Future<void> _persist([SharedPreferences? prefs]) async {
    try {
      final dump = jsonEncode(_dump());
      // persist to sqlite
      await SqliteService.instance.setString('db', dump);
    } catch (e) {
      debugPrint('DataService: Error persisting data: $e');
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _users.clear();
    _branches.clear();
    _products.clear();
    _orders.clear();
    _payments.clear();
    _deliveries.clear();
    _receivings.clear();
    _inventory.clear();
    _sales.clear();
    _announcements.clear();
    _events.clear();
    _seed();
    await SqliteService.instance.deleteKey('db');
    await _persist();
    notifyListeners();
  }

  Map<String, dynamic> _dump() => {
        'users': _users.map((e) => e.toMap()).toList(),
        'branches': _branches.map((e) => e.toMap()).toList(),
        'products': _products.map((e) => e.toMap()).toList(),
        'orders': _orders.map((e) => e.toMap()).toList(),
        'payments': _payments.map((e) => e.toMap()).toList(),
        'deliveries': _deliveries.map((e) => e.toMap()).toList(),
        'receivings': _receivings.map((e) => e.toMap()).toList(),
        'inventory': _inventory.map((e) => e.toMap()).toList(),
        'sales': _sales.map((e) => e.toMap()).toList(),
        'announcements': _announcements.map((e) => e.toMap()).toList(),
        'events': _events.map((e) => e.toMap()).toList(),
      };

  void _load(Map<String, dynamic> data) {
    _users = _parseList(data['users'], UserModel.fromMap);
    _branches = _parseList(data['branches'], Branch.fromMap);
    _products = _parseList(data['products'], Product.fromMap);
    _orders = _parseList(data['orders'], Order.fromMap);
    _payments = _parseList(data['payments'], Payment.fromMap);
    _deliveries = _parseList(data['deliveries'], Delivery.fromMap);
    _receivings = _parseList(data['receivings'], Receiving.fromMap);
    _inventory = _parseList(data['inventory'], InventoryItem.fromMap);

    // Sanitize inventory: prevent duplicate products per branch
    final seenInv = <String>{};
    _inventory.retainWhere((i) => seenInv.add('${i.branchId}_${i.productId}'));

    _sales = _parseList(data['sales'], Sale.fromMap);
    _announcements = _parseList(data['announcements'], Announcement.fromMap);
    _events = _parseList(data['events'], CalendarEvent.fromMap);
  }

  List<T> _parseList<T>(
      dynamic data, T Function(Map<String, dynamic>) fromMap) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => fromMap(item))
          .toList();
    }
    return [];
  }

  void _seed() {
    _branches = [
      Branch(
          id: 'b-legazpi',
          name: 'Marsh Bites Legazpi',
          location: 'Legazpi City'),
      Branch(
          id: 'b-cabuyao',
          name: 'Marsh Bites Cabuyao',
          location: 'Cabuyao City'),
      Branch(
          id: 'b-mandaluyong',
          name: 'Marsh Bites Mandaluyong',
          location: 'Mandaluyong City'),
      Branch(
          id: 'b-binangonan',
          name: 'Marsh Bites Binangonan',
          location: 'Binangonan Rizal'),
      Branch(
          id: 'b-stotomas',
          name: 'Marsh Bites Santo Tomas',
          location: 'Santo Tomas City'),
      Branch(id: 'b-vigan', name: 'Marsh Bites Vigan', location: 'Vigan City'),
      Branch(
          id: 'b-laspinas',
          name: 'Marsh Bites Las Piñas',
          location: 'Las Piñas City'),
      Branch(
          id: 'b-dasmarinas',
          name: 'Marsh Bites Dasmariñas',
          location: 'Dasmariñas City'),
      Branch(id: 'b-imus', name: 'Marsh Bites Imus', location: 'Imus City'),
      Branch(
          id: 'b-bacolod',
          name: 'Marsh Bites Bacolod',
          location: 'Bacolod City'),
      Branch(
          id: 'b-gensan',
          name: 'Marsh Bites General Santos',
          location: 'General Santos City'),
      Branch(
          id: 'b-makati', name: 'Marsh Bites Makati', location: 'Makati City'),
      Branch(
          id: 'b-quezon',
          name: 'Marsh Bites Quezon City',
          location: 'Quezon City'),
      Branch(
          id: 'b-bauan', name: 'Marsh Bites Bauan', location: 'Bauan Batangas'),
      Branch(
          id: 'b-angono', name: 'Marsh Bites Angono', location: 'Angono Rizal'),
      Branch(
          id: 'b-sultankudarat',
          name: 'Marsh Bites Sultan Kudarat',
          location: 'Sultan Kudarat'),
      Branch(
          id: 'b-trece',
          name: 'Marsh Bites Trece Martires',
          location: 'Trece Martires City'),
      Branch(
          id: 'b-baguio', name: 'Marsh Bites Baguio', location: 'Baguio City'),
      Branch(
          id: 'b-cdo',
          name: 'Marsh Bites Cagayan de Oro',
          location: 'Cagayan de Oro City'),
    ];

    _users = [
      UserModel(
          id: 'u0',
          name: 'Super Admin',
          email: 'admin@marshbites.com',
          password: 'admin123',
          role: 'admin'),
      ..._branches.map((b) => UserModel(
          id: 'u-${b.id}',
          name: '${b.name} Manager',
          email: '${b.id.replaceAll('b-', '')}@marshbites.com',
          password: 'branch123',
          role: 'branch',
          branchId: b.id)),
    ];

    _products = [
      Product(
          id: 'p1',
          name: 'Gourmet Marshmallow',
          flavor: 'Oreo Cookies',
          price: 149),
      Product(
          id: 'p2',
          name: 'Gourmet Marshmallow',
          flavor: 'Dried Mango & Mango Flavor',
          price: 149),
      Product(
          id: 'p3',
          name: 'Gourmet Marshmallow',
          flavor: 'Caramel Macchiato Powder & Biscoff Cookies',
          price: 149),
      Product(
          id: 'p4',
          name: 'Gourmet Marshmallow',
          flavor: 'Strawberry & Cheesecake Flavor',
          price: 149),
      Product(
          id: 'p5',
          name: 'Gourmet Marshmallow',
          flavor: 'Ube Jam & Flavor',
          price: 149),
      Product(
          id: 'p6',
          name: 'Gourmet Marshmallow',
          flavor: 'Matcha Powder',
          price: 149),
      Product(
          id: 'p7',
          name: 'Gourmet Marshmallow',
          flavor: 'Blue Berry Powder & Sour Strips Candy',
          price: 149),
    ];

    _inventory = [];
    for (final b in _branches) {
      for (final p in _products) {
        _inventory.add(InventoryItem(
          id: _uuid.v4(),
          branchId: b.id,
          productId: p.id,
          productName: '${p.flavor} (${p.name})',
          stock: 0,
        ));
      }
    }

    final now = DateTime.now();
    _orders = [];
    _deliveries = [];
    _receivings = [];
    _sales = [];

    _announcements = [
      Announcement(
        id: _uuid.v4(),
        title: 'Proudly Made in Bicol',
        message:
            'Welcome to the official Marsh Bites Branch System. We are proud to serve gourmet marshmallows handmade in Bicol.',
        createdAt: now,
      ),
      Announcement(
        id: _uuid.v4(),
        title: 'Predictive Demand Analytics',
        message:
            'The system now includes predictive demand analytics so branches can forecast stock needs and reduce waste.',
        createdAt: now,
      ),
    ];

    _events = [
      CalendarEvent(
        id: _uuid.v4(),
        title: 'Batch Production',
        date: now.add(const Duration(days: 2)),
        description: 'Prepare fresh marshmallow batches',
        type: CalendarEventType.task,
      ),
    ];
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  UserModel? login(String email, String password) {
    debugPrint('Attempting login with: $email / $password');
    try {
      final user = _users.firstWhere(
        (u) =>
            u.email.toLowerCase() == email.toLowerCase() &&
            u.password == password,
      );
      debugPrint('User found: ${user.name}, role: ${user.role}');
      currentUser = user;
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  Branch? getBranch(String id) {
    try {
      return _branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Orders ─────────────────────────────────────────────────────────────────
  Future<Order> createOrder(List<OrderItem> items) async {
    final branch = getBranch(currentUser!.branchId!)!;
    final total = items.fold(0.0, (s, i) => s + i.subtotal);
    final order = Order(
      id: _uuid.v4(),
      branchId: branch.id,
      branchName: branch.name,
      status: OrderStatus.pending,
      totalAmount: total,
      createdAt: DateTime.now(),
      items: items,
    );
    _orders.insert(0, order);
    await _persist();
    notifyListeners();
    return order;
  }

  Future<void> uploadPaymentProof(String orderId, String imagePath) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        proofImagePath: imagePath,
        status: OrderStatus.waitingApproval,
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<Delivery> createDelivery(
    String orderId,
    String address, {
    String? courierName,
    String? trackingNumber,
    DateTime? scheduledAt,
    String? notes,
  }) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    final delivery = Delivery(
      id: _uuid.v4(),
      orderId: order.id,
      branchId: order.branchId,
      address: address,
      status: DeliveryStatus.pending,
      scheduledAt: scheduledAt ?? DateTime.now().add(const Duration(days: 2)),
      courierName: courierName,
      trackingNumber: trackingNumber,
      notes: notes,
    );
    _deliveries.add(delivery);
    await _persist();
    notifyListeners();
    return delivery;
  }

  Future<Receiving> createReceiving(
    String deliveryId, {
    String? receiverName,
    String? conditionNotes,
    String? notes,
    DateTime? receivedAt,
  }) async {
    final delivery = _deliveries.firstWhere((d) => d.id == deliveryId);
    final receiving = Receiving(
      id: _uuid.v4(),
      deliveryId: delivery.id,
      orderId: delivery.orderId,
      branchId: delivery.branchId,
      status: ReceivingStatus.pending,
      createdAt: DateTime.now(),
      receivedAt: receivedAt,
      receiverName: receiverName,
      conditionNotes: conditionNotes,
      notes: notes,
    );
    _receivings.add(receiving);
    await _persist();
    notifyListeners();
    return receiving;
  }

  Future<void> updateReceivingStatus(String receivingId, ReceivingStatus status,
      {DateTime? receivedAt,
      String? receiverName,
      String? conditionNotes,
      String? notes}) async {
    final idx = _receivings.indexWhere((r) => r.id == receivingId);
    if (idx != -1) {
      _receivings[idx] = _receivings[idx].copyWith(
        status: status,
        receivedAt: receivedAt ?? _receivings[idx].receivedAt,
        receiverName: receiverName ?? _receivings[idx].receiverName,
        conditionNotes: conditionNotes ?? _receivings[idx].conditionNotes,
        notes: notes ?? _receivings[idx].notes,
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> updateDeliveryStatus(String deliveryId, DeliveryStatus status,
      {DateTime? deliveredAt}) async {
    final idx = _deliveries.indexWhere((d) => d.id == deliveryId);
    if (idx != -1) {
      _deliveries[idx] = _deliveries[idx].copyWith(
        status: status,
        deliveredAt: deliveredAt ?? _deliveries[idx].deliveredAt,
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> approveOrder(String orderId) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final order = _orders[idx];
      _orders[idx] = order.copyWith(status: OrderStatus.approved);

      // Update inventory
      for (final item in order.items) {
        final invIdx = _inventory.indexWhere(
          (i) => i.branchId == order.branchId && i.productId == item.productId,
        );

        if (invIdx != -1) {
          _inventory[invIdx] = _inventory[invIdx].copyWith(
            stock: _inventory[invIdx].stock + item.quantity,
          );
        } else {
          _inventory.add(InventoryItem(
            id: _uuid.v4(),
            branchId: order.branchId,
            productId: item.productId,
            productName: item.productName,
            stock: item.quantity,
          ));
        }
      }
      await _persist();
      notifyListeners();
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        status: OrderStatus.rejected,
        rejectionReason: reason,
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String orderId) async {
    _orders.removeWhere((o) => o.id == orderId);
    await _persist();
    notifyListeners();
  }

  // ── Products ───────────────────────────────────────────────────────────────
  Future<void> addProduct(Product p) async {
    _products.add(p);
    await _persist();
    notifyListeners();
  }

  Future<void> updateProduct(Product p) async {
    final idx = _products.indexWhere((x) => x.id == p.id);
    if (idx >= 0) _products[idx] = p;
    await _persist();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    await _persist();
    notifyListeners();
  }

  // ── Inventory ──────────────────────────────────────────────────────────────
  Future<void> updateStock(String inventoryId, int newStock) async {
    final idx = _inventory.indexWhere((i) => i.id == inventoryId);
    if (idx != -1) {
      _inventory[idx] = _inventory[idx].copyWith(stock: newStock);
      await _persist();
      notifyListeners();
    }
  }

  // ── Sales ──────────────────────────────────────────────────────────────────
  Future<void> recordSale(String productId, int quantity,
      {DateTime? date, double? customTotal, String? receiptPath}) async {
    final product = _products.firstWhere((p) => p.id == productId);
    final invIdx = _inventory.indexWhere(
      (i) => i.branchId == currentUser!.branchId && i.productId == productId,
    );

    if (invIdx == -1) {
      throw Exception('Product not in inventory');
    }
    if (_inventory[invIdx].stock < quantity) {
      throw Exception('Insufficient stock');
    }

    _inventory[invIdx] = _inventory[invIdx].copyWith(
      stock: _inventory[invIdx].stock - quantity,
    );

    _sales.insert(
      0,
      Sale(
        id: _uuid.v4(),
        branchId: currentUser!.branchId!,
        productId: productId,
        productName: '${product.flavor} (${product.name})',
        quantity: quantity,
        total: customTotal ?? (product.price * quantity),
        date: date ?? DateTime.now(),
        receiptPath: receiptPath,
      ),
    );
    await _persist();
    notifyListeners();
  }

  // ── Announcements ──────────────────────────────────────────────────────────
  Future<void> addAnnouncement(String title, String message) async {
    _announcements.insert(
      0,
      Announcement(
        id: _uuid.v4(),
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> deleteAnnouncement(String id) async {
    _announcements.removeWhere((a) => a.id == id);
    await _persist();
    notifyListeners();
  }

  // ── Events ─────────────────────────────────────────────────────────────────
  Future<void> addEvent(
    String title,
    DateTime date,
    String description,
    CalendarEventType type, {
    String? branchId,
    String? branchName,
  }) async {
    _events.add(CalendarEvent(
      id: _uuid.v4(),
      title: title,
      date: date,
      description: description,
      type: type,
      branchId: branchId,
      branchName: branchName,
    ));
    await _persist();
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  // ── Production ────────────────────────────────────────────────────────────
  Future<void> logProduction(String productId, int quantity) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(
        adminStock: _products[idx].adminStock + quantity,
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> addProductionStock(
      String branchId, String productId, int quantity) async {
    final productIdx = _products.indexWhere((p) => p.id == productId);
    if (productIdx == -1) return;

    if (_products[productIdx].adminStock < quantity) {
      throw Exception('Insufficient Admin Stock');
    }

    // Deduct from Admin
    _products[productIdx] = _products[productIdx].copyWith(
      adminStock: _products[productIdx].adminStock - quantity,
    );

    // Add to Branch
    final invIdx = _inventory.indexWhere(
      (i) => i.branchId == branchId && i.productId == productId,
    );

    if (invIdx != -1) {
      _inventory[invIdx] = _inventory[invIdx].copyWith(
        stock: _inventory[invIdx].stock + quantity,
      );
    } else {
      _inventory.add(InventoryItem(
        id: _uuid.v4(),
        branchId: branchId,
        productId: productId,
        productName:
            '${_products[productIdx].flavor} (${_products[productIdx].name})',
        stock: quantity,
      ));
    }
    await _persist();
    notifyListeners();
  }
}

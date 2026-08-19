// lib/models/models.dart

// ─── USER ────────────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // 'admin' | 'branch'
  final String? branchId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.branchId,
  });

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? branchId,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        role: role ?? this.role,
        branchId: branchId ?? this.branchId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'branchId': branchId,
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'] ?? '',
        name: m['name'] ?? 'Unknown',
        email: m['email'] ?? '',
        password: m['password'] ?? '',
        role: m['role'] ?? 'branch',
        branchId: m['branchId'],
      );
}

// ─── BRANCH ──────────────────────────────────────────────────────────────────
class Branch {
  final String id;
  final String name;
  final String location;

  Branch({required this.id, required this.name, required this.location});

  Branch copyWith({String? id, String? name, String? location}) => Branch(
        id: id ?? this.id,
        name: name ?? this.name,
        location: location ?? this.location,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'location': location};

  factory Branch.fromMap(Map<String, dynamic> m) => Branch(
        id: m['id'] ?? '',
        name: m['name'] ?? 'Unknown Branch',
        location: m['location'] ?? '',
      );
}

// ─── PRODUCT ─────────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String name;
  final String flavor;
  final double price;
  final int adminStock;

  Product({
    required this.id,
    required this.name,
    required this.flavor,
    required this.price,
    this.adminStock = 0,
  });

  Product copyWith({
    String? id,
    String? name,
    String? flavor,
    double? price,
    int? adminStock,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        flavor: flavor ?? this.flavor,
        price: price ?? this.price,
        adminStock: adminStock ?? this.adminStock,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'flavor': flavor,
        'price': price,
        'adminStock': adminStock,
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] ?? '',
        name: m['name'] ?? 'Product',
        flavor: m['flavor'] ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
        adminStock: m['adminStock'] ?? 0,
      );
}

// ─── ORDER ───────────────────────────────────────────────────────────────────
enum OrderStatus { pending, waitingApproval, approved, rejected }

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;

  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
  }) =>
      OrderItem(
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        quantity: m['quantity'] ?? 0,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0.0,
      );
}

class Order {
  final String id;
  final String branchId;
  final String branchName;
  final OrderStatus status;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String? proofImagePath;
  final String? rejectionReason;

  Order({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    this.proofImagePath,
    this.rejectionReason,
  });

  Order copyWith({
    String? id,
    String? branchId,
    String? branchName,
    OrderStatus? status,
    double? totalAmount,
    DateTime? createdAt,
    List<OrderItem>? items,
    String? proofImagePath,
    String? rejectionReason,
  }) =>
      Order(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        branchName: branchName ?? this.branchName,
        status: status ?? this.status,
        totalAmount: totalAmount ?? this.totalAmount,
        createdAt: createdAt ?? this.createdAt,
        items: items ?? this.items,
        proofImagePath: proofImagePath ?? this.proofImagePath,
        rejectionReason: rejectionReason ?? this.rejectionReason,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'branchId': branchId,
        'branchName': branchName,
        'status': status.name,
        'totalAmount': totalAmount,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((e) => e.toMap()).toList(),
        'proofImagePath': proofImagePath,
        'rejectionReason': rejectionReason,
      };

  factory Order.fromMap(Map<String, dynamic> m) => Order(
        id: m['id'] ?? '',
        branchId: m['branchId'] ?? '',
        branchName: m['branchName'] ?? '',
        status: OrderStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => OrderStatus.pending,
        ),
        totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0.0,
        createdAt: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        items: (m['items'] as List?)
                ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        proofImagePath: m['proofImagePath'],
        rejectionReason: m['rejectionReason'],
      );
}

// ─── PAYMENT ─────────────────────────────────────────────────────────────────
enum PaymentStatus { pending, approved, rejected }

class Payment {
  final String id;
  final String orderId;
  final String branchId;
  final String proofImagePath;
  final PaymentStatus status;

  Payment({
    required this.id,
    required this.orderId,
    required this.branchId,
    required this.proofImagePath,
    required this.status,
  });

  Payment copyWith({
    String? id,
    String? orderId,
    String? branchId,
    String? proofImagePath,
    PaymentStatus? status,
  }) =>
      Payment(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        branchId: branchId ?? this.branchId,
        proofImagePath: proofImagePath ?? this.proofImagePath,
        status: status ?? this.status,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'branchId': branchId,
        'proofImagePath': proofImagePath,
        'status': status.name,
      };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'] ?? '',
        orderId: m['orderId'] ?? '',
        branchId: m['branchId'] ?? '',
        proofImagePath: m['proofImagePath'] ?? '',
        status: PaymentStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => PaymentStatus.pending,
        ),
      );
}

// ─── DELIVERY ───────────────────────────────────────────────────────────────
enum DeliveryStatus { pending, inTransit, delivered, canceled }

extension DeliveryStatusLabel on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.canceled:
        return 'Canceled';
      case DeliveryStatus.pending:
        return 'Pending';
    }
  }
}

class Delivery {
  final String id;
  final String orderId;
  final String branchId;
  final String address;
  final DeliveryStatus status;
  final DateTime scheduledAt;
  final DateTime? deliveredAt;
  final String? courierName;
  final String? trackingNumber;
  final String? notes;

  Delivery({
    required this.id,
    required this.orderId,
    required this.branchId,
    required this.address,
    required this.status,
    required this.scheduledAt,
    this.deliveredAt,
    this.courierName,
    this.trackingNumber,
    this.notes,
  });

  Delivery copyWith({
    String? id,
    String? orderId,
    String? branchId,
    String? address,
    DeliveryStatus? status,
    DateTime? scheduledAt,
    DateTime? deliveredAt,
    String? courierName,
    String? trackingNumber,
    String? notes,
  }) =>
      Delivery(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        branchId: branchId ?? this.branchId,
        address: address ?? this.address,
        status: status ?? this.status,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        courierName: courierName ?? this.courierName,
        trackingNumber: trackingNumber ?? this.trackingNumber,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'branchId': branchId,
        'address': address,
        'status': status.name,
        'scheduledAt': scheduledAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'courierName': courierName,
        'trackingNumber': trackingNumber,
        'notes': notes,
      };

  factory Delivery.fromMap(Map<String, dynamic> m) => Delivery(
        id: m['id'] ?? '',
        orderId: m['orderId'] ?? '',
        branchId: m['branchId'] ?? '',
        address: m['address'] ?? '',
        status: DeliveryStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => DeliveryStatus.pending,
        ),
        scheduledAt: m['scheduledAt'] != null
            ? DateTime.tryParse(m['scheduledAt']) ?? DateTime.now()
            : DateTime.now(),
        deliveredAt: m['deliveredAt'] != null
            ? DateTime.tryParse(m['deliveredAt'])
            : null,
        courierName: m['courierName'],
        trackingNumber: m['trackingNumber'],
        notes: m['notes'],
      );
}

// ─── RECEIVING ──────────────────────────────────────────────────────────────
enum ReceivingStatus { pending, received, damaged, returned }

extension ReceivingStatusLabel on ReceivingStatus {
  String get label {
    switch (this) {
      case ReceivingStatus.received:
        return 'Received';
      case ReceivingStatus.damaged:
        return 'Damaged';
      case ReceivingStatus.returned:
        return 'Returned';
      case ReceivingStatus.pending:
        return 'Pending';
    }
  }
}

class Receiving {
  final String id;
  final String deliveryId;
  final String orderId;
  final String branchId;
  final ReceivingStatus status;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final String? receiverName;
  final String? conditionNotes;
  final String? notes;

  Receiving({
    required this.id,
    required this.deliveryId,
    required this.orderId,
    required this.branchId,
    required this.status,
    required this.createdAt,
    this.receivedAt,
    this.receiverName,
    this.conditionNotes,
    this.notes,
  });

  Receiving copyWith({
    String? id,
    String? deliveryId,
    String? orderId,
    String? branchId,
    ReceivingStatus? status,
    DateTime? createdAt,
    DateTime? receivedAt,
    String? receiverName,
    String? conditionNotes,
    String? notes,
  }) =>
      Receiving(
        id: id ?? this.id,
        deliveryId: deliveryId ?? this.deliveryId,
        orderId: orderId ?? this.orderId,
        branchId: branchId ?? this.branchId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        receivedAt: receivedAt ?? this.receivedAt,
        receiverName: receiverName ?? this.receiverName,
        conditionNotes: conditionNotes ?? this.conditionNotes,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'deliveryId': deliveryId,
        'orderId': orderId,
        'branchId': branchId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'receivedAt': receivedAt?.toIso8601String(),
        'receiverName': receiverName,
        'conditionNotes': conditionNotes,
        'notes': notes,
      };

  factory Receiving.fromMap(Map<String, dynamic> m) => Receiving(
        id: m['id'] ?? '',
        deliveryId: m['deliveryId'] ?? '',
        orderId: m['orderId'] ?? '',
        branchId: m['branchId'] ?? '',
        status: ReceivingStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => ReceivingStatus.pending,
        ),
        createdAt: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        receivedAt: m['receivedAt'] != null
            ? DateTime.tryParse(m['receivedAt'])
            : null,
        receiverName: m['receiverName'],
        conditionNotes: m['conditionNotes'],
        notes: m['notes'],
      );
}

// ─── INVENTORY ───────────────────────────────────────────────────────────────
class InventoryItem {
  final String id;
  final String branchId;
  final String productId;
  final String productName;
  final int stock;

  InventoryItem({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.productName,
    required this.stock,
  });

  InventoryItem copyWith({
    String? id,
    String? branchId,
    String? productId,
    String? productName,
    int? stock,
  }) =>
      InventoryItem(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        stock: stock ?? this.stock,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'branchId': branchId,
        'productId': productId,
        'productName': productName,
        'stock': stock,
      };

  factory InventoryItem.fromMap(Map<String, dynamic> m) => InventoryItem(
        id: m['id'] ?? '',
        branchId: m['branchId'] ?? '',
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        stock: m['stock'] ?? 0,
      );
}

class RestockSuggestion {
  final String productId;
  final String productName;
  final int currentStock;
  final double averageDailyQuantity;
  final double expectedWeeklyDemand;
  final int suggestedOrderQuantity;

  RestockSuggestion({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.averageDailyQuantity,
    required this.expectedWeeklyDemand,
    required this.suggestedOrderQuantity,
  });

  String get urgency {
    if (suggestedOrderQuantity >= 20) return 'Urgent';
    if (suggestedOrderQuantity >= 10) return 'Review';
    return 'Monitor';
  }
}

// ─── SALE ────────────────────────────────────────────────────────────────────
class Sale {
  final String id;
  final String branchId;
  final String productId;
  final String productName;
  final int quantity;
  final double total;
  final DateTime date;
  final String? receiptPath;

  Sale({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.total,
    required this.date,
    this.receiptPath,
  });

  Sale copyWith({
    String? id,
    String? branchId,
    String? productId,
    String? productName,
    int? quantity,
    double? total,
    DateTime? date,
    String? receiptPath,
  }) =>
      Sale(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        total: total ?? this.total,
        date: date ?? this.date,
        receiptPath: receiptPath ?? this.receiptPath,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'branchId': branchId,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'total': total,
        'date': date.toIso8601String(),
        'receiptPath': receiptPath,
      };

  factory Sale.fromMap(Map<String, dynamic> m) => Sale(
        id: m['id'] ?? '',
        branchId: m['branchId'] ?? '',
        productId: m['productId'] ?? '',
        productName: m['productName'] ?? '',
        quantity: m['quantity'] ?? 0,
        total: (m['total'] as num?)?.toDouble() ?? 0.0,
        date: m['date'] != null
            ? DateTime.tryParse(m['date']) ?? DateTime.now()
            : DateTime.now(),
        receiptPath: m['receiptPath'],
      );
}

// ─── ANNOUNCEMENT ────────────────────────────────────────────────────────────
class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
  }) =>
      Announcement(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Announcement.fromMap(Map<String, dynamic> m) => Announcement(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        message: m['message'] ?? '',
        createdAt: m['createdAt'] != null
            ? DateTime.tryParse(m['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ─── CALENDAR EVENT ──────────────────────────────────────────────────────────
enum CalendarEventType { task, appointment }

extension CalendarEventTypeLabel on CalendarEventType {
  String get label {
    switch (this) {
      case CalendarEventType.appointment:
        return 'Appointment';
      case CalendarEventType.task:
        return 'Task';
    }
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final String description;
  final CalendarEventType type;
  final String? branchId;
  final String? branchName;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.type,
    this.branchId,
    this.branchName,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? description,
    CalendarEventType? type,
    String? branchId,
    String? branchName,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        date: date ?? this.date,
        description: description ?? this.description,
        type: type ?? this.type,
        branchId: branchId ?? this.branchId,
        branchName: branchName ?? this.branchName,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'description': description,
        'type': type.name,
        'branchId': branchId,
        'branchName': branchName,
      };

  factory CalendarEvent.fromMap(Map<String, dynamic> m) => CalendarEvent(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        date: m['date'] != null
            ? DateTime.tryParse(m['date']) ?? DateTime.now()
            : DateTime.now(),
        description: m['description'] ?? '',
        type: CalendarEventType.values.firstWhere(
          (t) => t.name == (m['type'] ?? 'task'),
          orElse: () => CalendarEventType.task,
        ),
        branchId: m['branchId'],
        branchName: m['branchName'],
      );
}

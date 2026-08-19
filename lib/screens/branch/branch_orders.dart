// lib/screens/branch/branch_orders.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class BranchOrders extends StatelessWidget {
  const BranchOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'branch_orders_fab',
        onPressed: () => _createOrder(context, svc),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('ORDER PRODUCTS'),
      ),
      body: svc.branchOrders.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No orders yet. Place your first order!')
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: svc.branchOrders.length,
              itemBuilder: (_, i) => OrderCard(
                order: svc.branchOrders[i],
                onTap: () =>
                    _showOrderActions(context, svc, svc.branchOrders[i]),
              ),
            ),
    );
  }

  void _showOrderActions(BuildContext context, DataService svc, Order order) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _OrderSheet(order: order),
    );
  }

  void _createOrder(BuildContext context, DataService svc) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateOrderSheet(),
    );
  }
}

class _CreateOrderSheet extends StatefulWidget {
  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  final Map<String, int> _cart = {};
  String? _selectedPackage;

  final Map<String, Map<String, dynamic>> _packages = {
    'Silver': {'min': 35, 'price': 3999.0, 'unitPrice': 114.257},
    'Gold': {'min': 55, 'price': 5775.0, 'unitPrice': 105.0},
    'Platinum': {'min': 70, 'price': 7000.0, 'unitPrice': 100.0},
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final totalPacks = _cart.values.fold<int>(0, (sum, q) => sum + q);

    double totalPrice = 0;
    int limit = 0;
    if (_selectedPackage != null) {
      final pkg = _packages[_selectedPackage]!;
      limit = pkg['min'] as int;
      totalPrice = totalPacks * (pkg['unitPrice'] as num).toDouble();
      if (totalPacks > 0 && totalPrice < (pkg['price'] as num).toDouble()) {
        totalPrice = (pkg['price'] as num).toDouble();
      }
    }

    final isOverLimit = _selectedPackage != null && totalPacks > limit;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.disabledColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('New Package Order', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('Choose a package and distribute flavors',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _packages.keys.map((pkg) {
                final isSelected = _selectedPackage == pkg;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPackage = pkg),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Text(pkg,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : theme.textTheme.titleSmall?.color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                              '₱${NumberFormat('#,##0').format(_packages[pkg]!['price'])}',
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white70
                                      : theme.textTheme.bodySmall?.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: svc.products.length,
              itemBuilder: (_, i) {
                final p = svc.products[i];
                final qty = _cart[p.id] ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.flavor, style: theme.textTheme.titleSmall),
                              Text(p.name, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _qtyBtn(theme, Icons.remove_rounded, () {
                              if (qty > 0) {
                                setState(() {
                                  if (qty == 1) {
                                    _cart.remove(p.id);
                                  } else {
                                    _cart[p.id] = qty - 1;
                                  }
                                });
                              }
                            }),
                            SizedBox(
                              width: 40,
                              child: Text(qty.toString(),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall),
                            ),
                            _qtyBtn(theme, Icons.add_rounded, () {
                              if (_selectedPackage == null) {
                                showSnack(
                                    context, 'Please select a package first',
                                    error: true);
                                return;
                              }
                              setState(() => _cart[p.id] = qty + 1);
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Column(
              children: [
                if (isOverLimit)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Alert: Total packs ($totalPacks) exceeds the $_selectedPackage limit ($limit). Excess packs will be charged at package rates.',
                      style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Packs: $totalPacks / $limit',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOverLimit ? AppTheme.error : null,
                                  fontWeight:
                                      isOverLimit ? FontWeight.w800 : null)),
                          Text(
                              '₱${NumberFormat('#,##0.00').format(totalPrice)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: (_selectedPackage == null || totalPacks == 0)
                            ? null
                            : () => _submit(context, svc, totalPrice),
                        child: const Text('PLACE ORDER'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(ThemeData theme, IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
      );

  Future<void> _submit(
      BuildContext context, DataService svc, double totalPrice) async {
    final totalQty = _cart.values.fold<int>(0, (sum, q) => sum + q);
    final calculatedUnitPrice = totalPrice / totalQty;

    final items = _cart.entries.map((e) {
      final p = svc.products.firstWhere((p) => p.id == e.key);
      return OrderItem(
        productId: p.id,
        productName: '${p.flavor} (${p.name})',
        quantity: e.value,
        unitPrice: calculatedUnitPrice,
      );
    }).toList();

    await svc.createOrder(items);

    if (mounted) {
      if (context.mounted) {
        Navigator.pop(context);
        showSnack(
            context, 'Package order placed! Please upload proof of payment.');
      }
    }
  }
}

class _OrderSheet extends StatelessWidget {
  final Order order;
  const _OrderSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final fresh = svc.branchOrders
        .firstWhere((o) => o.id == order.id, orElse: () => order);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.disabledColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child:
                      Text('Order Details', style: theme.textTheme.titleLarge),
                ),
                StatusBadge(
                    label: fresh.status.label, color: fresh.status.color),
              ],
            ),
            const SizedBox(height: 24),
            ...fresh.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(item.productName,
                              style: theme.textTheme.bodyMedium)),
                      Text('×${item.quantity}',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Text('₱${item.subtotal.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                )),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: theme.textTheme.titleMedium),
                Text('₱${NumberFormat('#,##0.00').format(fresh.totalAmount)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900)),
              ],
            ),
            if (fresh.rejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Rejected: ${fresh.rejectionReason}',
                          style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
            if (fresh.status == OrderStatus.pending) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _uploadProof(context, svc, fresh),
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('UPLOAD PAYMENT PROOF'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProof(
      BuildContext context, DataService svc, Order order) async {
    final theme = Theme.of(context);
    XFile? proofFile;

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: theme.disabledColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Upload Payment Proof',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                      'Please select a receipt screenshot to upload as proof of payment.',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 24),
                  if (proofFile == null)
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final selected = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1200,
                          imageQuality: 80,
                        );
                        if (selected != null) {
                          setState(() => proofFile = selected);
                        }
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: theme.dividerColor,
                              style: BorderStyle.solid),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_rounded,
                                color: AppTheme.accentOrange),
                            SizedBox(width: 12),
                            Text('Select Proof Image',
                                style: TextStyle(
                                    color: AppTheme.accentOrange,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppTheme.success),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.success),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(proofFile!.name,
                                style: theme.textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            onPressed: () => setState(() => proofFile = null),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: proofFile == null
                          ? null
                          : () async {
                              await svc.uploadPaymentProof(
                                  order.id, proofFile!.path);
                              if (context.mounted) {
                                Navigator.pop(context);
                                showSnack(context,
                                    'Payment proof uploaded! Waiting for admin approval.');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success),
                      child: const Text('CONFIRM UPLOAD'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

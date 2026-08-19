// lib/screens/admin/admin_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminMenu extends StatelessWidget {
  const AdminMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Menu / Products')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_menu_fab',
        onPressed: () => _editProduct(context, svc, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD PRODUCT'),
      ),
      body: svc.products.isEmpty
          ? const EmptyState(
              icon: Icons.menu_book_outlined, message: 'No products yet')
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: svc.products.length,
              itemBuilder: (_, i) {
                final p = svc.products[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.bubble_chart_rounded,
                              color: theme.colorScheme.tertiary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.flavor, style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Stock: ${p.adminStock}',
                                        style: TextStyle(
                                            color: theme.colorScheme.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text('₱${p.price.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w900,
                            )),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          color: theme.cardTheme.color,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          icon: Icon(Icons.more_vert_rounded,
                              color: theme.disabledColor),
                          onSelected: (val) {
                            if (val == 'edit') _editProduct(context, svc, p);
                            if (val == 'delete') _delete(context, svc, p);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  const Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded,
                                      size: 18, color: AppTheme.error),
                                  SizedBox(width: 12),
                                  Text('Delete',
                                      style: TextStyle(color: AppTheme.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editProduct(
      BuildContext context, DataService svc, Product? existing) async {
    final theme = Theme.of(context);
    final nameCtrl =
        TextEditingController(text: existing?.name ?? 'Gourmet Marshmallow');
    final flavorCtrl = TextEditingController(text: existing?.flavor ?? '');
    final priceCtrl =
        TextEditingController(text: existing?.price.toString() ?? '149');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Product' : 'Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: flavorCtrl,
              decoration: const InputDecoration(labelText: 'Flavor'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₱)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancel', style: TextStyle(color: theme.disabledColor))),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text) ?? 0;
              if (existing == null) {
                await svc.addProduct(Product(
                    id: const Uuid().v4(),
                    name: nameCtrl.text,
                    flavor: flavorCtrl.text,
                    price: price));
              } else {
                await svc.updateProduct(Product(
                    id: existing.id,
                    name: nameCtrl.text,
                    flavor: flavorCtrl.text,
                    price: price));
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (context.mounted) {
                  showSnack(context, 'Product saved!');
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, DataService svc, Product p) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete Product',
        message: 'Remove ${p.name} - ${p.flavor}?',
        confirmText: 'Delete',
        confirmColor: AppTheme.error);
    if (ok == true) {
      await svc.deleteProduct(p.id);
      if (context.mounted) showSnack(context, 'Deleted');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../inventory/data/models/inventory_model.dart';
import '../../../pharmacy/data/models/pharmacy_model.dart';
import '../../../product/data/models/product_model.dart';
import '../../data/models/admin_inventory_request_model.dart';
import '../../providers/admin_inventory_provider.dart';
import '../../providers/admin_pharmacy_provider.dart';
import '../../providers/admin_product_provider.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final _searchController = TextEditingController();
  bool _didStart = false;
  String? _pharmacyId;
  String? _productId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await Future.wait([
        context.read<AdminInventoryProvider>().loadInventories(),
        context.read<AdminPharmacyProvider>().loadPharmacies(),
        context.read<AdminProductProvider>().loadProducts(),
      ]);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() {
    return context.read<AdminInventoryProvider>().loadInventories(
      pharmacyId: _pharmacyId ?? '',
      productId: _productId ?? '',
      keyword: _searchController.text,
    );
  }

  Future<void> _openInventoryForm({InventoryModel? inventory}) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _InventoryFormSheet(inventory: inventory),
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu tồn kho thành công')));
    }
  }

  Future<void> _editQuantity(InventoryModel inventory) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => _QuantityDialog(inventory: inventory),
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật số lượng thành công')),
      );
    }
  }

  Future<void> _confirmDelete(InventoryModel inventory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa tồn kho'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa hoặc đưa tồn kho này về 0 không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminInventoryProvider>();
    final success = await provider.deleteInventory(inventory.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã xóa tồn kho'
              : provider.errorMessage ?? 'Không thể xóa tồn kho.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    final inventoryProvider = context.watch<AdminInventoryProvider>();
    final pharmacyProvider = context.watch<AdminPharmacyProvider>();
    final productProvider = context.watch<AdminProductProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý tồn kho')),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _applyFilters,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _FilterPanel(
              searchController: _searchController,
              pharmacyId: _pharmacyId,
              productId: _productId,
              pharmacies: pharmacyProvider.allPharmacies,
              products: productProvider.products,
              isLoading: inventoryProvider.isLoading,
              onPharmacyChanged: (value) {
                setState(() => _pharmacyId = _emptyToNull(value));
                _applyFilters();
              },
              onProductChanged: (value) {
                setState(() => _productId = _emptyToNull(value));
                _applyFilters();
              },
              onSearch: _applyFilters,
              onChanged: () => setState(() {}),
              onAdd: () => _openInventoryForm(),
            ),
            const SizedBox(height: 16),
            if (inventoryProvider.isLoading &&
                inventoryProvider.inventories.isEmpty)
              const SizedBox(
                height: 360,
                child: AppLoading(message: 'Đang tải tồn kho...'),
              )
            else if (inventoryProvider.errorMessage != null &&
                inventoryProvider.inventories.isEmpty)
              _InventoryErrorView(
                message: inventoryProvider.errorMessage!,
                onRetry: _applyFilters,
              )
            else if (inventoryProvider.inventories.isEmpty)
              const _InventoryEmptyView()
            else ...[
              if (inventoryProvider.isLoading ||
                  inventoryProvider.isSaving ||
                  inventoryProvider.isDeleting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ...inventoryProvider.inventories.map(
                (inventory) => _InventoryCard(
                  inventory: inventory,
                  isBusy:
                      inventoryProvider.isSaving ||
                      inventoryProvider.isDeleting,
                  onEditQuantity: () => _editQuantity(inventory),
                  onDelete: () => _confirmDelete(inventory),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.searchController,
    required this.pharmacyId,
    required this.productId,
    required this.pharmacies,
    required this.products,
    required this.isLoading,
    required this.onPharmacyChanged,
    required this.onProductChanged,
    required this.onSearch,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController searchController;
  final String? pharmacyId;
  final String? productId;
  final List<PharmacyModel> pharmacies;
  final List<ProductModel> products;
  final bool isLoading;
  final ValueChanged<String?> onPharmacyChanged;
  final ValueChanged<String?> onProductChanged;
  final Future<void> Function() onSearch;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _safeValue(pharmacyId, pharmacies.map((item) => item.id)),
          items: [
            const DropdownMenuItem(value: '', child: Text('Tất cả nhà thuốc')),
            ...pharmacies.map(
              (pharmacy) => DropdownMenuItem(
                value: pharmacy.id,
                child: Text(pharmacy.name),
              ),
            ),
          ],
          onChanged: isLoading ? null : onPharmacyChanged,
          decoration: const InputDecoration(
            labelText: 'Nhà thuốc',
            prefixIcon: Icon(Icons.local_pharmacy_rounded),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _safeValue(productId, products.map((item) => item.id)),
          items: [
            const DropdownMenuItem(value: '', child: Text('Tất cả sản phẩm')),
            ...products.map(
              (product) => DropdownMenuItem(
                value: product.id,
                child: Text(product.name),
              ),
            ),
          ],
          onChanged: isLoading ? null : onProductChanged,
          decoration: const InputDecoration(
            labelText: 'Sản phẩm',
            prefixIcon: Icon(Icons.medication_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Tìm SKU/tên sản phẩm',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      searchController.clear();
                      onSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('+ Cập nhật tồn kho'),
        ),
      ],
    );
  }

  String _safeValue(String? value, Iterable<String> options) {
    final selected = value?.trim();
    if (selected == null || selected.isEmpty) {
      return '';
    }

    return options.contains(selected) ? selected : '';
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.inventory,
    required this.isBusy,
    required this.onEditQuantity,
    required this.onDelete,
  });

  final InventoryModel inventory;
  final bool isBusy;
  final VoidCallback onEditQuantity;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fallback(inventory.pharmacyName, 'Chưa có nhà thuốc'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _fallback(inventory.productName, 'Chưa có sản phẩm'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: ${_fallback(inventory.productSku, 'Chưa có')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.inventory_2_rounded,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  label: Text('Tồn: ${inventory.quantity}'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: const Icon(
                    Icons.update_rounded,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  label: Text(_formatDate(inventory.updatedAt)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onEditQuantity,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Sửa số lượng'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton.icon(
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fallback(String? value, String fallback) {
    final text = value?.trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  String _formatDate(DateTime? value) {
    return value == null
        ? 'Chưa cập nhật'
        : DateFormatter.formatDateTime(value);
  }
}

class _InventoryFormSheet extends StatefulWidget {
  const _InventoryFormSheet({this.inventory});

  final InventoryModel? inventory;

  @override
  State<_InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends State<_InventoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  String? _pharmacyId;
  String? _productId;

  @override
  void initState() {
    super.initState();
    final inventory = widget.inventory;
    if (inventory != null) {
      _pharmacyId = inventory.pharmacyId;
      _productId = inventory.productId;
      _quantityController.text = inventory.quantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<AdminInventoryProvider>();
    final success = await provider.saveInventory(
      AdminInventoryRequestModel(
        pharmacyId: _pharmacyId!.trim(),
        productId: _productId!.trim(),
        quantity: int.parse(_quantityController.text.trim()),
      ),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không thể lưu tồn kho.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<AdminInventoryProvider>();
    final pharmacyProvider = context.watch<AdminPharmacyProvider>();
    final productProvider = context.watch<AdminProductProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cập nhật tồn kho',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _safeValue(
                _pharmacyId,
                pharmacyProvider.allPharmacies.map((item) => item.id),
              ),
              items: pharmacyProvider.allPharmacies
                  .map(
                    (pharmacy) => DropdownMenuItem(
                      value: pharmacy.id,
                      child: Text(pharmacy.name),
                    ),
                  )
                  .toList(),
              onChanged: inventoryProvider.isSaving
                  ? null
                  : (value) => setState(() => _pharmacyId = value),
              decoration: const InputDecoration(labelText: 'Chọn nhà thuốc'),
              validator: (value) => _emptyToNull(value) == null
                  ? 'Nhà thuốc không được rỗng'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _safeValue(
                _productId,
                productProvider.products.map((item) => item.id),
              ),
              items: productProvider.products
                  .map(
                    (product) => DropdownMenuItem(
                      value: product.id,
                      child: Text(product.name),
                    ),
                  )
                  .toList(),
              onChanged: inventoryProvider.isSaving
                  ? null
                  : (value) => setState(() => _productId = value),
              decoration: const InputDecoration(labelText: 'Chọn sản phẩm'),
              validator: (value) => _emptyToNull(value) == null
                  ? 'Sản phẩm không được rỗng'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số lượng'),
              validator: _quantityValidator,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: inventoryProvider.isSaving ? null : _submit,
              icon: inventoryProvider.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(inventoryProvider.isSaving ? 'Đang lưu...' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  String? _quantityValidator(String? value) {
    final quantity = int.tryParse(value?.trim() ?? '');
    if (quantity == null || quantity < 0) {
      return 'Số lượng phải lớn hơn hoặc bằng 0';
    }

    return null;
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  String? _safeValue(String? value, Iterable<String> options) {
    final selected = _emptyToNull(value);
    if (selected == null) {
      return null;
    }

    return options.contains(selected) ? selected : null;
  }
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.inventory});

  final InventoryModel inventory;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.inventory.quantity.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<AdminInventoryProvider>();
    final success = await provider.updateQuantity(
      widget.inventory.id,
      int.parse(_controller.text.trim()),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không thể sửa số lượng.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminInventoryProvider>();

    return AlertDialog(
      title: const Text('Sửa số lượng tồn'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số lượng'),
          validator: (value) {
            final quantity = int.tryParse(value?.trim() ?? '');
            if (quantity == null || quantity < 0) {
              return 'Số lượng phải lớn hơn hoặc bằng 0';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: provider.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: provider.isSaving ? null : _submit,
          child: Text(provider.isSaving ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }
}

class _InventoryErrorView extends StatelessWidget {
  const _InventoryErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.error,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryEmptyView extends StatelessWidget {
  const _InventoryEmptyView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(
        child: Text('Chưa có tồn kho phù hợp.', textAlign: TextAlign.center),
      ),
    );
  }
}

class _NoPermissionView extends StatelessWidget {
  const _NoPermissionView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Bạn không có quyền truy cập khu vực Admin.')),
    );
  }
}

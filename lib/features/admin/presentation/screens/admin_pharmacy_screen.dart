import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../pharmacy/data/models/pharmacy_model.dart';
import '../../providers/admin_pharmacy_provider.dart';

class AdminPharmacyScreen extends StatefulWidget {
  const AdminPharmacyScreen({super.key});

  @override
  State<AdminPharmacyScreen> createState() => _AdminPharmacyScreenState();
}

class _AdminPharmacyScreenState extends State<AdminPharmacyScreen> {
  final _searchController = TextEditingController();
  bool _didStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AdminPharmacyProvider>().loadPharmacies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({PharmacyModel? pharmacy}) async {
    final shouldRefresh = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.adminPharmacyForm,
      arguments: pharmacy == null
          ? null
          : {'pharmacyId': pharmacy.id, 'pharmacy': pharmacy},
    );

    if (!mounted || shouldRefresh != true) {
      return;
    }

    await context.read<AdminPharmacyProvider>().loadPharmacies();
  }

  Future<void> _confirmDelete(PharmacyModel pharmacy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ẩn nhà thuốc'),
          content: Text(
            'Bạn có chắc chắn muốn ẩn nhà thuốc "${pharmacy.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ẩn'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminPharmacyProvider>();
    final success = await provider.deletePharmacy(pharmacy.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã ẩn nhà thuốc'
              : provider.errorMessage ?? 'Không thể ẩn nhà thuốc.',
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

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý nhà thuốc')),
      body: Consumer<AdminPharmacyProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => provider.loadPharmacies(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _PharmacyToolbar(
                  controller: _searchController,
                  isLoading: provider.isLoading,
                  onSearchChanged: provider.search,
                  onAdd: () => _openForm(),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.allPharmacies.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: AppLoading(message: 'Đang tải nhà thuốc...'),
                  )
                else if (provider.errorMessage != null &&
                    provider.allPharmacies.isEmpty)
                  _PharmacyErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadPharmacies(),
                  )
                else if (provider.pharmacies.isEmpty)
                  const _PharmacyEmptyView()
                else ...[
                  if (provider.isLoading || provider.isDeleting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ...provider.pharmacies.map(
                    (pharmacy) => _PharmacyCard(
                      pharmacy: pharmacy,
                      isBusy: provider.isDeleting,
                      onEdit: () => _openForm(pharmacy: pharmacy),
                      onDelete: () => _confirmDelete(pharmacy),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PharmacyToolbar extends StatelessWidget {
  const _PharmacyToolbar({
    required this.controller,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm nhà thuốc hoặc khu vực',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('+ Thêm nhà thuốc'),
        ),
      ],
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({
    required this.pharmacy,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final PharmacyModel pharmacy;
  final bool isBusy;
  final VoidCallback onEdit;
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fallback(pharmacy.phone, 'Chưa có số điện thoại'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(isActive: pharmacy.isActive),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(
              icon: Icons.place_rounded,
              text: pharmacy.fullAddress ?? _buildAddress(pharmacy),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.schedule_rounded,
              text: _fallback(pharmacy.openingHours, 'Chưa có giờ mở cửa'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Sửa'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton.icon(
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.visibility_off_rounded),
                    label: const Text('Ẩn'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildAddress(PharmacyModel pharmacy) {
    return [
      pharmacy.address,
      pharmacy.ward,
      pharmacy.district,
      pharmacy.province,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
  }

  String _fallback(String? value, String fallback) {
    final text = value?.trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isActive ? 'Đang hoạt động' : 'Đã ẩn'),
      visualDensity: VisualDensity.compact,
      backgroundColor: isActive
          ? AppTheme.success.withValues(alpha: 0.12)
          : AppTheme.textSecondary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: isActive ? AppTheme.success : AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PharmacyErrorView extends StatelessWidget {
  const _PharmacyErrorView({required this.message, required this.onRetry});

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

class _PharmacyEmptyView extends StatelessWidget {
  const _PharmacyEmptyView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(
        child: Text('Chưa có nhà thuốc phù hợp.', textAlign: TextAlign.center),
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

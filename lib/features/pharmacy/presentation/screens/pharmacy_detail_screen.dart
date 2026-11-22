import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/location/map_launcher.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../inventory/data/models/inventory_model.dart';
import '../../../inventory/providers/inventory_provider.dart';
import '../../data/models/pharmacy_model.dart';
import '../../providers/pharmacy_provider.dart';

class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({super.key, this.pharmacyId});

  final String? pharmacyId;

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.pharmacyId;
      if (mounted && id != null && id.trim().isNotEmpty) {
        context.read<PharmacyProvider>().loadPharmacyDetail(id);
        context.read<InventoryProvider>().loadInventoryByPharmacy(
          pharmacyId: id,
          refresh: true,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _callPharmacy(PharmacyModel pharmacy) async {
    final phone = pharmacy.phone?.trim();
    if (phone == null || phone.isEmpty) {
      _showSnackBar('Nhà thuốc chưa cập nhật số điện thoại');
      return;
    }

    final opened = await MapLauncher.call(phone);
    if (!opened && mounted) {
      _showSnackBar('Không thể gọi tự động. Số điện thoại nhà thuốc: $phone');
    }
  }

  Future<void> _openDirection(PharmacyModel pharmacy) async {
    final opened = await MapLauncher.openDirections(
      latitude: pharmacy.latitude,
      longitude: pharmacy.longitude,
      address: pharmacy.fullAddress ?? pharmacy.address,
    );
    if (!opened && mounted) {
      _showSnackBar('Không thể mở ứng dụng bản đồ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacyProvider>();
    final pharmacy = provider.selectedPharmacy;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: const Text('Chi tiết nhà thuốc')),
      body: provider.isLoading && pharmacy == null
          ? const AppLoading(message: 'Đang tải nhà thuốc...')
          : pharmacy == null
          ? _ErrorOrEmptyView(
              message: provider.errorMessage,
              onRetry: () {
                final id = widget.pharmacyId;
                if (id != null && id.trim().isNotEmpty) {
                  context.read<PharmacyProvider>().loadPharmacyDetail(id);
                }
              },
            )
          : RefreshIndicator(
              onRefresh: () async {
                final id = widget.pharmacyId ?? pharmacy.id;
                await Future.wait([
                  context.read<PharmacyProvider>().loadPharmacyDetail(id),
                  context.read<InventoryProvider>().loadInventoryByPharmacy(
                    pharmacyId: id,
                    refresh: true,
                  ),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  const _MapHeader(),
                  const SizedBox(height: 16),
                  _PharmacyInfoCard(pharmacy: pharmacy),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callPharmacy(pharmacy),
                          icon: const Icon(Icons.phone_outlined),
                          label: const Text('Gọi điện'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openDirection(pharmacy),
                          icon: const Icon(Icons.directions_outlined),
                          label: const Text('Chỉ đường'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sản phẩm còn hàng tại chi nhánh',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PharmacyInventorySection(pharmacyId: pharmacy.id),
                ],
              ),
            ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.16)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 42),
          ),
        ],
      ),
    );
  }
}

class _PharmacyInfoCard extends StatelessWidget {
  const _PharmacyInfoCard({required this.pharmacy});

  final PharmacyModel pharmacy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppTheme.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_outlined,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name.isEmpty ? 'Nhà thuốc' : pharmacy.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(isActive: pharmacy.isActive),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoLine(
              icon: Icons.location_on_outlined,
              label: 'Địa chỉ',
              value: pharmacy.fullAddress?.trim().isNotEmpty == true
                  ? pharmacy.fullAddress!.trim()
                  : pharmacy.address,
            ),
            _InfoLine(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: pharmacy.phone?.trim().isNotEmpty == true
                  ? pharmacy.phone!.trim()
                  : 'Đang cập nhật',
            ),
            _InfoLine(
              icon: Icons.access_time_outlined,
              label: 'Giờ mở cửa',
              value: pharmacy.openingHours?.trim().isNotEmpty == true
                  ? pharmacy.openingHours!.trim()
                  : 'Đang cập nhật',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Đang cập nhật' : value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.success : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Đang hoạt động' : 'Tạm ngưng',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PharmacyInventorySection extends StatelessWidget {
  const _PharmacyInventorySection({required this.pharmacyId});

  final String pharmacyId;

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final inventories = provider.pharmacyInventories;

        if (provider.isLoading && inventories.isEmpty) {
          return const Card(
            child: SizedBox(
              height: 170,
              child: AppLoading(message: 'Đang tải tồn kho...'),
            ),
          );
        }

        if (provider.errorMessage != null && inventories.isEmpty) {
          return _InventoryErrorCard(
            message: provider.errorMessage!,
            onRetry: () {
              context.read<InventoryProvider>().loadInventoryByPharmacy(
                pharmacyId: pharmacyId,
                refresh: true,
              );
            },
          );
        }

        if (inventories.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(26),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppTheme.primaryBlue,
                    size: 56,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Chi nhánh này chưa có dữ liệu tồn kho',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final inventory in inventories) ...[
              _InventoryProductCard(inventory: inventory),
              const SizedBox(height: 12),
            ],
            if (provider.hasMore)
              OutlinedButton(
                onPressed: provider.isLoadingMore
                    ? null
                    : () {
                        context
                            .read<InventoryProvider>()
                            .loadInventoryByPharmacy(pharmacyId: pharmacyId);
                      },
                child: provider.isLoadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tải thêm'),
              ),
          ],
        );
      },
    );
  }
}

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard({required this.inventory});

  final InventoryModel inventory;

  @override
  Widget build(BuildContext context) {
    final imageUrl = inventory.productImage?.trim();
    final productName = inventory.productName?.trim().isNotEmpty == true
        ? inventory.productName!.trim()
        : 'Sản phẩm';
    final sku = inventory.productSku?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 76,
                height: 76,
                color: AppTheme.lightBlue,
                child: imageUrl == null || imageUrl.isEmpty
                    ? const Icon(
                        Icons.medication_liquid_outlined,
                        color: AppTheme.primaryBlue,
                        size: 38,
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.medication_liquid_outlined,
                          color: AppTheme.primaryBlue,
                          size: 38,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  if (sku != null && sku.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'SKU: $sku',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Số lượng tồn: ${inventory.quantity}',
                    style: const TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: inventory.productId.trim().isEmpty
                          ? null
                          : () => Navigator.of(context).pushNamed(
                              AppRoutes.productDetail,
                              arguments: {'id': inventory.productId},
                            ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Xem sản phẩm'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryErrorCard extends StatelessWidget {
  const _InventoryErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              color: AppTheme.primaryBlue,
              size: 48,
            ),
            const SizedBox(height: 10),
            const Text(
              'Không tải được dữ liệu tồn kho',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _ErrorOrEmptyView extends StatelessWidget {
  const _ErrorOrEmptyView({this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.trim().isEmpty) {
      return const AppEmptyState(
        title: 'Chưa có thông tin nhà thuốc',
        icon: Icons.local_pharmacy_outlined,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_outlined,
                  color: AppTheme.primaryBlue,
                  size: 54,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không tải được chi tiết nhà thuốc',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.08)
      ..strokeWidth = 1.2;

    for (var x = 24.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x - 42, size.height), paint);
    }

    for (var y = 26.0; y < size.height; y += 46) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

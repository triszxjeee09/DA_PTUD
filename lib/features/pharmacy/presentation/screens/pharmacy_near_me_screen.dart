import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/pharmacy_model.dart';
import '../../providers/pharmacy_provider.dart';

class PharmacyNearMeScreen extends StatefulWidget {
  const PharmacyNearMeScreen({super.key});

  @override
  State<PharmacyNearMeScreen> createState() => _PharmacyNearMeScreenState();
}

class _PharmacyNearMeScreenState extends State<PharmacyNearMeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PharmacyProvider>().loadPharmacies();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PharmacyModel> _filterPharmacies(List<PharmacyModel> pharmacies) {
    final keyword = _keyword.trim().toLowerCase();
    if (keyword.isEmpty) {
      return pharmacies;
    }

    return pharmacies.where((pharmacy) {
      final searchable = [
        pharmacy.name,
        pharmacy.address,
        pharmacy.fullAddress,
        pharmacy.province,
        pharmacy.district,
      ].whereType<String>().join(' ').toLowerCase();

      return searchable.contains(keyword);
    }).toList();
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDetail(PharmacyModel pharmacy) {
    Navigator.of(context).pushNamed(
      AppRoutes.pharmacyDetail,
      arguments: {'pharmacyId': pharmacy.id},
    );
  }

  void _openDirection(PharmacyModel pharmacy) {
    _showComingSoon('Chức năng chỉ đường đang phát triển');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacyProvider>();
    final pharmacies = _filterPharmacies(provider.pharmacies);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: const Text('Nhà thuốc gần bạn')),
      body: RefreshIndicator(
        onRefresh: context.read<PharmacyProvider>().loadPharmacies,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm nhà thuốc hoặc khu vực',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _keyword.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _keyword = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) => setState(() => _keyword = value),
            ),
            const SizedBox(height: 16),
            _MapPreviewCard(
              onLocationTap: () {
                _showComingSoon('Chức năng đang phát triển');
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Danh sách nhà thuốc',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            if (provider.isLoading && provider.pharmacies.isEmpty)
              const SizedBox(
                height: 220,
                child: AppLoading(message: 'Đang tải nhà thuốc...'),
              )
            else if (provider.errorMessage != null &&
                provider.pharmacies.isEmpty)
              _ErrorCard(
                message: provider.errorMessage!,
                onRetry: context.read<PharmacyProvider>().loadPharmacies,
              )
            else if (pharmacies.isEmpty)
              const Card(
                child: SizedBox(
                  height: 220,
                  child: AppEmptyState(
                    title: 'Không tìm thấy nhà thuốc',
                    message: 'Thử tìm bằng tên nhà thuốc hoặc khu vực khác.',
                    icon: Icons.local_pharmacy_outlined,
                  ),
                ),
              )
            else
              for (final pharmacy in pharmacies) ...[
                _PharmacyCard(
                  pharmacy: pharmacy,
                  onDetail: () => _openDetail(pharmacy),
                  onDirection: () => _openDirection(pharmacy),
                ),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({required this.onLocationTap});

  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bản đồ nhà thuốc',
            style: TextStyle(
              color: AppTheme.darkBlue,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLocationTap,
            icon: const Icon(Icons.my_location_outlined),
            label: const Text('Lấy vị trí hiện tại'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({
    required this.pharmacy,
    required this.onDetail,
    required this.onDirection,
  });

  final PharmacyModel pharmacy;
  final VoidCallback onDetail;
  final VoidCallback onDirection;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppTheme.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_outlined,
                    color: AppTheme.primaryBlue,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ActiveChip(isActive: pharmacy.isActive),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoLine(
              icon: Icons.location_on_outlined,
              text: pharmacy.fullAddress?.trim().isNotEmpty == true
                  ? pharmacy.fullAddress!.trim()
                  : pharmacy.address,
            ),
            if (pharmacy.phone?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.phone_outlined,
                text: pharmacy.phone!.trim(),
              ),
            ],
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.access_time_outlined,
              text: pharmacy.openingHours?.trim().isNotEmpty == true
                  ? pharmacy.openingHours!.trim()
                  : 'Giờ mở cửa đang cập nhật',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDetail,
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDirection,
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Chỉ đường'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        Icon(icon, size: 19, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.trim().isEmpty ? 'Đang cập nhật' : text,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.success : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              color: AppTheme.primaryBlue,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không tải được danh sách nhà thuốc',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

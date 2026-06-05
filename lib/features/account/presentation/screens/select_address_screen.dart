import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../data/models/user_address_model.dart';
import '../../providers/user_address_provider.dart';

class SelectAddressScreen extends StatefulWidget {
  const SelectAddressScreen({super.key});

  @override
  State<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserAddressProvider>().loadAddresses();
      }
    });
  }

  Future<void> _openAddressForm({UserAddressModel? address}) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.addressForm,
      arguments: address == null
          ? null
          : {'addressId': address.id, 'address': address},
    );

    if (mounted) {
      context.read<UserAddressProvider>().loadAddresses();
    }
  }

  void _confirmAddress() {
    final selectedAddress = context.read<UserAddressProvider>().selectedAddress;

    if (selectedAddress == null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
      );
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.checkout);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserAddressProvider>();
    final addresses = provider.addresses;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: const Text('Chọn địa chỉ')),
      body: RefreshIndicator(
        onRefresh: () => context.read<UserAddressProvider>().loadAddresses(),
        child: provider.isLoading && addresses.isEmpty
            ? const _LoadingView()
            : provider.errorMessage != null && addresses.isEmpty
            ? _ErrorView(
                message: provider.errorMessage!,
                onRetry: () =>
                    context.read<UserAddressProvider>().loadAddresses(),
              )
            : addresses.isEmpty
            ? _EmptyAddressView(onAdd: () => _openAddressForm())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                children: [
                  for (final address in addresses) ...[
                    _AddressCard(
                      address: address,
                      selected: provider.selectedAddress?.id == address.id,
                      onSelected: () => provider.selectAddress(address),
                      onEdit: () => _openAddressForm(address: address),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _AddAddressButton(onPressed: () => _openAddressForm()),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _confirmAddress,
            child: const Text('Xác nhận địa chỉ'),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onSelected,
    required this.onEdit,
  });

  final UserAddressModel address;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.35)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelected,
        child: IntrinsicHeight(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 6,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AddressRadio(selected: selected),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                Text(
                                  address.receiverName,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  '|',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  address.receiverPhone,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (address.isDefault) ...[
                                  const _DefaultBadge(),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(
                                    _readAddressText(address),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sửa địa chỉ',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        color: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _readAddressText(UserAddressModel address) {
    final fullAddress = address.fullAddress;
    if (fullAddress != null && fullAddress.trim().isNotEmpty) {
      return fullAddress;
    }

    return [
      address.detailAddress,
      address.ward,
      address.district,
      address.province,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Mặc định',
        style: TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AddressRadio extends StatelessWidget {
  const _AddressRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppTheme.primaryBlue : Colors.white,
        border: Border.all(
          color: selected ? AppTheme.primaryBlue : const Color(0xFFC6D0E1),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.circle, color: Colors.white, size: 10)
          : null,
    );
  }
}

class _AddAddressButton extends StatelessWidget {
  const _AddAddressButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Thêm địa chỉ mới'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        side: const BorderSide(
          color: AppTheme.primaryBlue,
          width: 1.4,
          style: BorderStyle.solid,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _EmptyAddressView extends StatelessWidget {
  const _EmptyAddressView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: AppTheme.primaryBlue,
          size: 76,
        ),
        const SizedBox(height: 18),
        const Text(
          'Bạn chưa có địa chỉ giao hàng',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Thêm địa chỉ mới'),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        const Icon(
          Icons.wifi_off_outlined,
          color: AppTheme.primaryBlue,
          size: 72,
        ),
        const SizedBox(height: 16),
        const Text(
          'Không tải được địa chỉ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 22),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}

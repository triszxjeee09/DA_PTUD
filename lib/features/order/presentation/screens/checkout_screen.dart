import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../account/data/models/user_address_model.dart';
import '../../../account/providers/user_address_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../payment/providers/payment_provider.dart';
import '../../../prescription/data/models/prescription_model.dart';
import '../../../voucher/data/models/apply_voucher_response_model.dart';
import '../../data/models/create_order_request_model.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const double _shippingFee = 0;

  final _noteController = TextEditingController();
  _PaymentOption _selectedPayment = _PaymentOption.cod;
  PrescriptionModel? _selectedPrescription;
  ApplyVoucherResponseModel? _appliedVoucher;
  double? _voucherOrderAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final cartProvider = context.read<CartProvider>();
      if (cartProvider.cart == null) {
        cartProvider.loadCart();
      }

      final addressProvider = context.read<UserAddressProvider>();
      if (addressProvider.addresses.isEmpty) {
        addressProvider.loadAddresses();
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _changeAddress() async {
    await Navigator.of(context).pushNamed(AppRoutes.selectAddress);

    if (!mounted) {
      return;
    }

    final addressProvider = context.read<UserAddressProvider>();
    if (addressProvider.addresses.isEmpty) {
      addressProvider.loadAddresses();
    }
  }

  Future<void> _selectPaymentMethod() async {
    final selected = await showModalBottomSheet<_PaymentOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                for (final option in _PaymentOption.values)
                  _PaymentOptionTile(
                    option: option,
                    selected: option == _selectedPayment,
                    onTap: option.isAvailable
                        ? () => Navigator.of(context).pop(option)
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedPayment = selected;
      });
    }
  }

  Future<void> _selectPrescription() async {
    final selected = await Navigator.of(
      context,
    ).pushNamed<PrescriptionModel>(AppRoutes.prescriptionSelect);

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPrescription = selected;
    });
  }

  Future<void> _uploadNewPrescription() async {
    await Navigator.of(context).pushNamed(AppRoutes.prescriptionUpload);
  }

  Future<void> _selectVoucher(double orderAmount) async {
    final result = await Navigator.of(context)
        .pushNamed<ApplyVoucherResponseModel>(
          AppRoutes.applyVoucher,
          arguments: {'orderAmount': orderAmount},
        );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _appliedVoucher = result;
      _voucherOrderAmount = orderAmount;
    });
  }

  void _clearVoucher() {
    if (_appliedVoucher == null) {
      return;
    }

    setState(() {
      _appliedVoucher = null;
      _voucherOrderAmount = null;
    });
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>().cart;
    final selectedAddress = context.read<UserAddressProvider>().selectedAddress;
    final hasPrescriptionProduct = cart?.hasPrescriptionProduct ?? false;

    if (!_selectedPayment.isAvailable) {
      _showSnackBar('Phương thức thanh toán này đang phát triển');
      return;
    }

    if (selectedAddress == null) {
      _showSnackBar('Vui lòng chọn địa chỉ giao hàng');
      return;
    }

    if (cart == null || cart.items.isEmpty) {
      _showSnackBar('Giỏ hàng của bạn đang trống');
      return;
    }

    if (hasPrescriptionProduct && _selectedPrescription == null) {
      _showSnackBar('Vui lòng chọn đơn thuốc đã được duyệt');
      return;
    }

    if (hasPrescriptionProduct && _selectedPrescription?.status != 'APPROVED') {
      _showSnackBar('Đơn thuốc của bạn chưa được dược sĩ duyệt');
      return;
    }

    final userEmail = context.read<AuthProvider>().currentUser?.email?.trim();
    if (userEmail == null || userEmail.isEmpty) {
      final shouldContinue = await _confirmOrderWithoutEmail();
      if (!mounted) {
        return;
      }

      if (!shouldContinue) {
        return;
      }
    }

    final note = _noteController.text.trim();
    final request = CreateOrderRequestModel(
      addressId: selectedAddress.id,
      prescriptionId: hasPrescriptionProduct ? _selectedPrescription?.id : null,
      voucherId: _appliedVoucher?.voucherId,
      paymentMethod: _selectedPayment.value,
      note: note.isEmpty ? null : note,
    );
    debugPrint(
      '[ORDER] Request tạo đơn hàng: '
      'addressId=${request.addressId}, '
      'paymentMethod=${request.paymentMethod}, '
      'voucherId=${request.voucherId ?? 'null'}, '
      'prescriptionId=${request.prescriptionId ?? 'null'}, '
      'note=${request.note == null ? 'null' : 'co ghi chu'}',
    );

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.createOrder(request);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnackBar(orderProvider.errorMessage ?? 'Không thể đặt hàng');
      return;
    }

    final order = orderProvider.selectedOrder;
    if (order == null) {
      _showSnackBar('Không tìm thấy thông tin đơn hàng');
      return;
    }

    if (_selectedPayment.value == 'VNPAY') {
      final paymentProvider = context.read<PaymentProvider>();
      final createdPayment = await paymentProvider.createVnPayPayment(order.id);

      if (!mounted) {
        return;
      }

      if (!createdPayment) {
        _showSnackBar(
          paymentProvider.errorMessage ?? 'Không thể tạo thanh toán VNPay',
        );
        return;
      }

      final vnPayPayment = paymentProvider.vnPayPayment;
      final paymentUrl = vnPayPayment?.paymentUrl.trim() ?? '';
      if (paymentUrl.isEmpty) {
        _showSnackBar('Không tìm thấy đường dẫn thanh toán VNPay');
        return;
      }

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.paymentVnPay,
        arguments: {
          'paymentUrl': paymentUrl,
          'orderId': order.id,
          'orderCode': order.orderCode,
        },
      );
      return;
    }

    await context.read<CartProvider>().loadCart();

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacementNamed(AppRoutes.orderSuccess, arguments: {'order': order});
  }

  Future<bool> _confirmOrderWithoutEmail() async {
    final action = await showDialog<_MissingEmailAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chưa có email'),
          content: const Text(
            'Bạn chưa cập nhật email nên có thể không nhận được email xác nhận đơn hàng. Bạn vẫn muốn tiếp tục đặt hàng?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_MissingEmailAction.updateEmail),
              child: const Text('Cập nhật email'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_MissingEmailAction.continueOrder),
              child: const Text('Tiếp tục đặt hàng'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return false;
    }

    if (action == _MissingEmailAction.updateEmail) {
      Navigator.of(context).pushNamed(AppRoutes.accountProfile);
      return false;
    }

    return action == _MissingEmailAction.continueOrder;
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final addressProvider = context.watch<UserAddressProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final userEmail = context.watch<AuthProvider>().currentUser?.email?.trim();
    final cart = cartProvider.cart;
    final items = cart?.items ?? const <CartItemModel>[];
    final selectedAddress = addressProvider.selectedAddress;
    final subtotal = cart?.totalAmount ?? 0;
    final appliedVoucher = _appliedVoucher;
    if (appliedVoucher != null &&
        _voucherOrderAmount != null &&
        _voucherOrderAmount != subtotal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _appliedVoucher != null) {
          _clearVoucher();
          _showSnackBar('Giỏ hàng đã thay đổi, vui lòng chọn lại voucher');
        }
      });
    }
    final discount = appliedVoucher?.discountAmount ?? 0;
    final total = (subtotal - discount + _shippingFee)
        .clamp(0, double.infinity)
        .toDouble();
    final hasPrescriptionProduct = cart?.hasPrescriptionProduct ?? false;
    final isLoading =
        (cartProvider.isLoading && cart == null) ||
        (addressProvider.isLoading && selectedAddress == null);
    final isProcessingOrder =
        orderProvider.isCreating || paymentProvider.isCreatingVnPayPayment;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: const Text('Xác nhận đơn hàng')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
              children: [
                if (hasPrescriptionProduct) ...[
                  const _PrescriptionWarning(),
                  const SizedBox(height: 16),
                  _PrescriptionCard(
                    prescription: _selectedPrescription,
                    onSelect: _selectPrescription,
                    onUpload: _uploadNewPrescription,
                  ),
                  const SizedBox(height: 16),
                ],
                _AddressCard(
                  address: selectedAddress,
                  onChange: _changeAddress,
                ),
                const SizedBox(height: 16),
                _ConfirmationEmailCard(email: userEmail),
                const SizedBox(height: 16),
                _ProductsCard(items: items),
                const SizedBox(height: 16),
                _PaymentCard(
                  selectedPayment: _selectedPayment,
                  onChange: _selectPaymentMethod,
                ),
                const SizedBox(height: 16),
                _VoucherCard(
                  appliedVoucher: appliedVoucher,
                  onSelect: () => _selectVoucher(subtotal),
                  onClear: _clearVoucher,
                ),
                const SizedBox(height: 16),
                _NoteCard(controller: _noteController),
                const SizedBox(height: 16),
                _PaymentSummaryCard(
                  subtotal: subtotal,
                  discount: discount,
                  shippingFee: _shippingFee,
                  total: total,
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      CurrencyFormatter.format(total),
                      style: const TextStyle(
                        color: AppTheme.darkBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessingOrder ? null : _placeOrder,
                  child: Text(isProcessingOrder ? 'Đang xử lý...' : 'Đặt hàng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationEmailCard extends StatelessWidget {
  const _ConfirmationEmailCard({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = email?.trim();
    final hasEmail = normalizedEmail != null && normalizedEmail.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email xác nhận',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasEmail
                        ? 'Email xác nhận đơn hàng sẽ được gửi tới: $normalizedEmail'
                        : 'Tài khoản của bạn chưa có email. Vui lòng cập nhật email để nhận xác nhận đơn hàng.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (!hasEmail) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.accountProfile),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Cập nhật email'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onChange});

  final UserAddressModel? address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Địa chỉ giao hàng',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  if (address == null)
                    const Text(
                      'Chưa chọn địa chỉ giao hàng',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else ...[
                    Text(
                      '${address!.receiverName} - ${address!.receiverPhone}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _readAddressText(address!),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(onPressed: onChange, child: const Text('Thay đổi')),
          ],
        ),
      ),
    );
  }

  static String _readAddressText(UserAddressModel address) {
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

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({required this.items});

  final List<CartItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppTheme.primaryBlue),
                SizedBox(width: 12),
                Text(
                  'Sản phẩm',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text(
                'Giỏ hàng chưa có sản phẩm',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              for (final item in items) ...[
                _CheckoutProductItem(item: item),
                if (item != items.last) const Divider(height: 22),
              ],
          ],
        ),
      ),
    );
  }
}

class _CheckoutProductItem extends StatelessWidget {
  const _CheckoutProductItem({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 72,
            height: 72,
            color: AppTheme.lightBlue,
            child: item.productImage == null
                ? const Icon(
                    Icons.medication_liquid_outlined,
                    color: AppTheme.primaryBlue,
                  )
                : CachedNetworkImage(
                    imageUrl: item.productImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.medication_liquid_outlined,
                      color: AppTheme.primaryBlue,
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
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'x${item.quantity}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          CurrencyFormatter.format(item.totalPrice),
          style: const TextStyle(
            color: AppTheme.darkBlue,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.selectedPayment, required this.onChange});

  final _PaymentOption selectedPayment;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.payments_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedPayment.displayLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(onPressed: onChange, child: const Text('Thay đổi')),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PaymentOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: onTap == null
            ? AppTheme.textSecondary.withValues(alpha: 0.45)
            : selected
            ? AppTheme.primaryBlue
            : AppTheme.textSecondary,
      ),
      title: Text(
        option.displayLabel,
        style: TextStyle(
          color: onTap == null ? AppTheme.textSecondary : AppTheme.textPrimary,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      subtitle: option.isAvailable
          ? null
          : const Text(
              'Đang phát triển',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.appliedVoucher,
    required this.onSelect,
    required this.onClear,
  });

  final ApplyVoucherResponseModel? appliedVoucher;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final voucher = appliedVoucher;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(width: 12),
                Text(
                  'Mã giảm giá',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (voucher == null) ...[
              const Text(
                'Chưa áp dụng mã giảm giá',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.local_offer_outlined),
                  label: const Text('Chọn voucher'),
                ),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            voucher.code,
                            style: const TextStyle(
                              color: AppTheme.darkBlue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          voucher.name.isEmpty
                              ? 'Voucher đã áp dụng'
                              : voucher.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '-${CurrencyFormatter.format(voucher.discountAmount)}',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onSelect,
                        child: const Text('Thay đổi'),
                      ),
                      TextButton(
                        onPressed: onClear,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Bỏ chọn'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi chú cho đơn hàng',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ghi chú cho nhà thuốc',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.total,
  });

  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết thanh toán',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'Tạm tính',
              value: CurrencyFormatter.format(subtotal),
            ),
            _SummaryRow(
              label: 'Giảm giá',
              value: discount > 0
                  ? '-${CurrencyFormatter.format(discount)}'
                  : CurrencyFormatter.format(0),
              valueColor: discount > 0
                  ? AppTheme.success
                  : AppTheme.textPrimary,
            ),
            _SummaryRow(
              label: 'Phí giao hàng',
              value: shippingFee == 0
                  ? '0đ'
                  : CurrencyFormatter.format(shippingFee),
              valueColor: AppTheme.success,
            ),
            const Divider(height: 28),
            _SummaryRow(
              label: 'Tổng thanh toán',
              value: CurrencyFormatter.format(total),
              valueColor: AppTheme.darkBlue,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
                  valueColor ??
                  (isTotal ? AppTheme.darkBlue : AppTheme.textPrimary),
              fontSize: isTotal ? 22 : 16,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionWarning extends StatelessWidget {
  const _PrescriptionWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.45)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đơn hàng có sản phẩm cần đơn thuốc. Vui lòng chọn đơn thuốc đã được dược sĩ duyệt hoặc gửi đơn thuốc mới.',
              style: TextStyle(color: AppTheme.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.onSelect,
    required this.onUpload,
  });

  final PrescriptionModel? prescription;
  final VoidCallback onSelect;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: AppTheme.primaryBlue),
                SizedBox(width: 12),
                Text(
                  'Đơn thuốc',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (prescription == null) ...[
              const Text(
                'Chưa chọn đơn thuốc',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSelect,
                      child: const Text('Chọn đơn thuốc'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onUpload,
                      child: const Text('Gửi đơn thuốc mới'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription!.patientName.isEmpty
                              ? 'Bệnh nhân chưa cập nhật'
                              : prescription!.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PrescriptionStatusChip(
                          status: prescription!.status,
                          label: _prescriptionStatusLabel(prescription!),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onSelect,
                    child: const Text('Thay đổi'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PrescriptionInfoRow(
                icon: Icons.calendar_today_outlined,
                text:
                    'Ngày gửi: ${_formatPrescriptionDate(prescription!.createdAt)}',
              ),
              if (prescription!.pharmacistNote?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _PrescriptionInfoRow(
                  icon: Icons.medical_information_outlined,
                  text: 'Dược sĩ: ${prescription!.pharmacistNote!.trim()}',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PrescriptionInfoRow extends StatelessWidget {
  const _PrescriptionInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _PrescriptionStatusChip extends StatelessWidget {
  const _PrescriptionStatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'PENDING' => AppTheme.warning,
      'APPROVED' => AppTheme.success,
      'REJECTED' => AppTheme.error,
      _ => AppTheme.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _prescriptionStatusLabel(PrescriptionModel prescription) {
  if (prescription.statusLabel.trim().isNotEmpty) {
    return prescription.statusLabel;
  }

  return switch (prescription.status) {
    'PENDING' => 'Chờ duyệt',
    'APPROVED' => 'Đã duyệt',
    'REJECTED' => 'Từ chối',
    _ => 'Đang cập nhật',
  };
}

String _formatPrescriptionDate(DateTime? value) {
  if (value == null) {
    return 'Đang cập nhật';
  }

  return DateFormatter.formatDateTime(value);
}

enum _PaymentOption {
  cod('Thanh toán khi nhận hàng', 'COD'),
  vnpay('VNPay', 'VNPAY'),
  momo('MoMo', 'MOMO'),
  bankTransfer('Chuyển khoản ngân hàng', 'BANK_TRANSFER');

  const _PaymentOption(this.label, this.value);

  final String label;
  final String value;

  bool get isAvailable =>
      this == _PaymentOption.cod || this == _PaymentOption.vnpay;

  String get displayLabel {
    return switch (this) {
      _PaymentOption.cod => 'Thanh toán khi nhận hàng',
      _PaymentOption.vnpay => 'VNPay',
      _PaymentOption.momo => 'MoMo',
      _PaymentOption.bankTransfer => 'Chuyển khoản ngân hàng',
    };
  }
}

enum _MissingEmailAction { updateEmail, continueOrder }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_voucher_model.dart';
import '../../data/models/admin_voucher_request_model.dart';
import '../../providers/admin_voucher_provider.dart';

class AdminVoucherFormScreen extends StatefulWidget {
  const AdminVoucherFormScreen({super.key, this.voucherId});

  final String? voucherId;

  @override
  State<AdminVoucherFormScreen> createState() => _AdminVoucherFormScreenState();
}

class _AdminVoucherFormScreenState extends State<AdminVoucherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _minOrderController = TextEditingController(text: '0');
  final _usageLimitController = TextEditingController();

  String _discountType = 'PERCENT';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _didStart = false;
  String? _voucherIdFromArguments;

  String? get _voucherId {
    final fromWidget = _emptyToNull(widget.voucherId);
    if (fromWidget != null) {
      return fromWidget;
    }

    return _emptyToNull(_voucherIdFromArguments);
  }

  bool get _isEditing => _voucherId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    _voucherIdFromArguments = _readVoucherIdArgument();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxDiscountController.dispose();
    _minOrderController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final voucherId = _voucherId;
    if (voucherId == null || !mounted) {
      return;
    }

    final provider = context.read<AdminVoucherProvider>();
    await provider.loadVoucherDetail(voucherId);

    if (!mounted) {
      return;
    }

    final voucher = provider.selectedVoucher;
    if (voucher == null) {
      _showMessage(provider.errorMessage ?? 'Không thể tải voucher.');
      return;
    }

    _fillForm(voucher);
  }

  void _fillForm(AdminVoucherModel voucher) {
    _codeController.text = voucher.code;
    _nameController.text = voucher.name;
    _descriptionController.text = voucher.description ?? '';
    _discountValueController.text = _formatNumber(voucher.discountValue);
    _maxDiscountController.text = voucher.maxDiscountAmount == null
        ? ''
        : _formatNumber(voucher.maxDiscountAmount!);
    _minOrderController.text = _formatNumber(voucher.minOrderAmount);
    _usageLimitController.text = voucher.usageLimit?.toString() ?? '';

    setState(() {
      _discountType = _normalizeDiscountType(voucher.discountType);
      _startDate = voucher.startDate;
      _endDate = voucher.endDate;
      _isActive = voucher.isActive;
    });
  }

  Future<void> _pickStartDate() async {
    final selectedDate = await _pickDate(_startDate ?? DateTime.now());
    if (selectedDate == null || !mounted) {
      return;
    }

    final startDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    setState(() {
      _startDate = startDate;
      if (_endDate != null && !_endDate!.isAfter(startDate)) {
        _endDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59,
        );
      }
    });
  }

  Future<void> _pickEndDate() async {
    final initial =
        _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1));
    final selectedDate = await _pickDate(initial);
    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
        59,
      );
    });
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final startDate = _startDate;
    final endDate = _endDate;
    if (startDate != null && endDate != null && !endDate.isAfter(startDate)) {
      _showMessage('Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }

    final provider = context.read<AdminVoucherProvider>();
    final request = AdminVoucherRequestModel(
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      description: _emptyToNull(_descriptionController.text),
      discountType: _discountType,
      discountValue: _readNumber(_discountValueController.text),
      maxDiscountAmount: _readNullableNumber(_maxDiscountController.text),
      minOrderAmount: _readNumber(_minOrderController.text),
      usageLimit: _readNullableInt(_usageLimitController.text),
      startDate: startDate?.toIso8601String(),
      endDate: endDate?.toIso8601String(),
      isActive: _isActive,
    );

    final voucherId = _voucherId;
    final success = voucherId != null
        ? await provider.updateVoucher(voucherId, request)
        : await provider.createVoucher(request);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(provider.errorMessage ?? 'Không thể lưu voucher.');
      return;
    }

    _showMessage(
      _isEditing ? 'Cập nhật voucher thành công' : 'Thêm voucher thành công',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    final provider = context.watch<AdminVoucherProvider>();
    final isBusy =
        provider.isSubmitting || (provider.isLoadingDetail && _isEditing);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa voucher' : 'Thêm voucher')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _SectionCard(
                  title: 'Thông tin voucher',
                  children: [
                    TextFormField(
                      controller: _codeController,
                      enabled: !isBusy,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9_-]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mã voucher',
                        hintText: 'VD: SALE50',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                      validator: _validateCode,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      enabled: !isBusy,
                      decoration: const InputDecoration(
                        labelText: 'Tên chương trình',
                        prefixIcon: Icon(Icons.local_offer_outlined),
                      ),
                      validator: _required('Tên voucher không được rỗng'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isBusy,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Điều kiện giảm giá',
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _discountType,
                      decoration: const InputDecoration(
                        labelText: 'Loại giảm giá',
                        prefixIcon: Icon(Icons.discount_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PERCENT',
                          child: Text('Giảm theo phần trăm'),
                        ),
                        DropdownMenuItem(
                          value: 'FIXED',
                          child: Text('Giảm tiền cố định'),
                        ),
                      ],
                      onChanged: isBusy
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _discountType = value);
                            },
                      validator: (value) => _emptyToNull(value) == null
                          ? 'Loại giảm giá không được rỗng'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _discountValueController,
                      enabled: !isBusy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Giá trị giảm',
                        hintText: _discountType == 'PERCENT'
                            ? 'VD: 10'
                            : 'VD: 50000',
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final discountValue = _readNullableNumber(value);
                        if (discountValue == null || discountValue <= 0) {
                          return 'Giá trị giảm phải lớn hơn 0';
                        }
                        if (_discountType == 'PERCENT' && discountValue > 100) {
                          return 'Giá trị phần trăm không được lớn hơn 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _maxDiscountController,
                      enabled: !isBusy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: _discountType == 'PERCENT'
                            ? 'Giảm tối đa'
                            : 'Giảm tối đa',
                        hintText: _discountType == 'PERCENT'
                            ? 'Nên nhập khi giảm theo phần trăm'
                            : 'Không bắt buộc',
                        prefixIcon: const Icon(Icons.price_check_outlined),
                      ),
                      validator: (value) {
                        final text = _emptyToNull(value);
                        if (text == null) {
                          return null;
                        }

                        final maxDiscount = _readNullableNumber(text);
                        if (maxDiscount == null) {
                          return 'Giảm tối đa không hợp lệ';
                        }

                        if (maxDiscount < 0) {
                          return 'Giảm tối đa phải lớn hơn hoặc bằng 0';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _minOrderController,
                      enabled: !isBusy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Đơn hàng tối thiểu',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (value) {
                        final text = _emptyToNull(value);
                        final minOrder = _readNullableNumber(text);
                        if (text != null && minOrder == null) {
                          return 'Đơn hàng tối thiểu không hợp lệ';
                        }

                        if ((minOrder ?? 0) < 0) {
                          return 'Đơn tối thiểu phải lớn hơn hoặc bằng 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usageLimitController,
                      enabled: !isBusy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giới hạn lượt dùng',
                        hintText: 'Bỏ trống nếu không giới hạn',
                        prefixIcon: Icon(Icons.people_alt_outlined),
                      ),
                      validator: (value) {
                        final text = value?.trim();
                        if (text == null || text.isEmpty) {
                          return null;
                        }
                        final parsed = int.tryParse(text);
                        if (parsed == null || parsed <= 0) {
                          return 'Giới hạn lượt dùng phải lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _DiscountPreview(
                      discountType: _discountType,
                      discountValue: _readNumber(_discountValueController.text),
                      maxDiscountAmount: _readNullableNumber(
                        _maxDiscountController.text,
                      ),
                      minOrderAmount: _readNumber(_minOrderController.text),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Thời gian và trạng thái',
                  children: [
                    _DatePickerTile(
                      label: 'Ngày bắt đầu',
                      value: _startDate,
                      helperText: 'Mặc định 00:00:00',
                      onTap: isBusy ? null : _pickStartDate,
                    ),
                    const SizedBox(height: 12),
                    _DatePickerTile(
                      label: 'Ngày kết thúc',
                      value: _endDate,
                      helperText: 'Mặc định 23:59:59',
                      onTap: isBusy ? null : _pickEndDate,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: isBusy
                          ? null
                          : (value) => setState(() => _isActive = value),
                      title: const Text('Đang hoạt động'),
                      activeThumbColor: AppTheme.primaryBlue,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (provider.isLoadingDetail && _isEditing)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99FFFFFF),
                child: AppLoading(message: 'Đang tải voucher...'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: AppPrimaryButton(
            label: provider.isSubmitting ? 'Đang lưu...' : 'Lưu voucher',
            icon: Icons.save_rounded,
            isLoading: provider.isSubmitting,
            onPressed: isBusy ? null : _submit,
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) => _emptyToNull(value) == null ? message : null;
  }

  String? _validateCode(String? value) {
    final code = _emptyToNull(value);
    if (code == null) {
      return 'Mã voucher không được rỗng';
    }

    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(code)) {
      return 'Mã voucher chỉ gồm chữ, số, gạch ngang hoặc gạch dưới';
    }

    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toString();
  }

  double _readNumber(String? value) {
    final text = _normalizeNumberText(value);
    return text == null ? 0 : double.tryParse(text) ?? 0;
  }

  double? _readNullableNumber(String? value) {
    final text = _normalizeNumberText(value);
    if (text == null || text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  int? _readNullableInt(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return int.tryParse(text);
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  String? _readVoucherIdArgument() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      return _emptyToNull(arguments['voucherId']?.toString());
    }

    return null;
  }

  String? _normalizeNumberText(String? value) {
    final rawText = value?.trim().replaceAll(' ', '');
    if (rawText == null || rawText.isEmpty) {
      return null;
    }

    var text = rawText;
    final hasComma = text.contains(',');
    final hasDot = text.contains('.');

    if (hasComma && hasDot) {
      final commaIndex = text.lastIndexOf(',');
      final dotIndex = text.lastIndexOf('.');
      text = commaIndex > dotIndex
          ? text.replaceAll('.', '').replaceAll(',', '.')
          : text.replaceAll(',', '');
    } else if (hasComma) {
      final parts = text.split(',');
      text = parts.length == 2 && parts.last.length <= 2
          ? text.replaceAll(',', '.')
          : text.replaceAll(',', '');
    } else if (hasDot) {
      final parts = text.split('.');
      if (parts.length > 2 || parts.last.length == 3) {
        text = text.replaceAll('.', '');
      }
    }

    return text;
  }

  String _normalizeDiscountType(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'FIXED' ||
        normalized == 'FIXED_AMOUNT' ||
        normalized == 'AMOUNT') {
      return 'FIXED';
    }

    return 'PERCENT';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DiscountPreview extends StatelessWidget {
  const _DiscountPreview({
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscountAmount,
  });

  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;

  @override
  Widget build(BuildContext context) {
    final discountText = discountType == 'PERCENT'
        ? '${discountValue.toStringAsFixed(0)}%'
        : CurrencyFormatter.format(discountValue);
    final maxText = maxDiscountAmount == null
        ? 'Không giới hạn giảm tối đa'
        : 'Tối đa ${CurrencyFormatter.format(maxDiscountAmount!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.18)),
      ),
      child: Text(
        'Xem trước: giảm $discountText, $maxText, áp dụng từ đơn ${CurrencyFormatter.format(minOrderAmount)}',
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.helperText,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final String helperText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: const Icon(Icons.event_rounded),
        ),
        child: Text(
          value == null ? 'Chọn ngày' : DateFormatter.formatDateTime(value!),
          style: TextStyle(
            color: value == null
                ? AppTheme.textSecondary
                : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
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

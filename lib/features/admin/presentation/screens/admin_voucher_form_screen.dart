import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../voucher/data/models/voucher_model.dart';
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
  final _minOrderController = TextEditingController();
  final _usageLimitController = TextEditingController();

  String _discountType = 'PERCENT';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _didStart = false;

  bool get _isEditing => widget.voucherId?.trim().isNotEmpty ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
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
    if (!_isEditing || !mounted) {
      return;
    }

    final provider = context.read<AdminVoucherProvider>();
    final voucher = await provider.loadVoucherDetail(widget.voucherId!.trim());

    if (!mounted) {
      return;
    }

    if (voucher == null) {
      _showMessage(provider.errorMessage ?? 'Không thể tải voucher.');
      return;
    }

    _fillForm(voucher);
  }

  void _fillForm(VoucherModel voucher) {
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
      _discountType = voucher.discountType.trim().isEmpty
          ? 'PERCENT'
          : voucher.discountType;
      _startDate = voucher.startDate;
      _endDate = voucher.endDate;
      _isActive = voucher.isActive;
    });
  }

  Future<void> _pickStartDate() async {
    final date = await _pickDate(_startDate ?? DateTime.now());
    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = date;
      if (_endDate != null && !_endDate!.isAfter(date)) {
        _endDate = date.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickEndDate() async {
    final initial =
        _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1));
    final date = await _pickDate(initial);
    if (date == null || !mounted) {
      return;
    }

    setState(() => _endDate = date);
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
    if (startDate == null) {
      _showMessage('Ngày bắt đầu không được rỗng');
      return;
    }
    if (endDate == null) {
      _showMessage('Ngày kết thúc không được rỗng');
      return;
    }
    if (!endDate.isAfter(startDate)) {
      _showMessage('Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }

    final provider = context.read<AdminVoucherProvider>();
    final request = AdminVoucherRequestModel(
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      description: _emptyToNull(_descriptionController.text),
      discountType: _discountType,
      discountValue: _readNumber(_discountValueController.text),
      maxDiscountAmount: _readNullableNumber(_maxDiscountController.text),
      minOrderAmount: _readNumber(_minOrderController.text),
      usageLimit: _readNullableInt(_usageLimitController.text),
      startDate: startDate,
      endDate: endDate,
      isActive: _isActive,
    );

    final success = _isEditing
        ? await provider.updateVoucher(widget.voucherId!.trim(), request)
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
    final isBusy = provider.isSaving || provider.isLoadingDetail;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa voucher' : 'Thêm voucher')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Mã voucher'),
                  validator: _required('Mã voucher không được rỗng'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên voucher'),
                  validator: _required('Tên voucher không được rỗng'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _discountType,
                  decoration: const InputDecoration(
                    labelText: 'Loại giảm giá',
                    prefixIcon: Icon(Icons.discount_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PERCENT', child: Text('PERCENT')),
                    DropdownMenuItem(value: 'FIXED', child: Text('FIXED')),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Giá trị giảm'),
                  validator: (value) {
                    final discountValue = _readNumber(value);
                    if (discountValue <= 0) {
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Giảm tối đa'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minOrderController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Đơn tối thiểu'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usageLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giới hạn lượt dùng',
                  ),
                ),
                const SizedBox(height: 12),
                _DatePickerTile(
                  label: 'Ngày bắt đầu',
                  value: _startDate,
                  onTap: isBusy ? null : _pickStartDate,
                ),
                const SizedBox(height: 12),
                _DatePickerTile(
                  label: 'Ngày kết thúc',
                  value: _endDate,
                  onTap: isBusy ? null : _pickEndDate,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  onChanged: isBusy
                      ? null
                      : (value) => setState(() => _isActive = value),
                  title: const Text('Đang hoạt động'),
                  activeColor: AppTheme.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (provider.isLoadingDetail)
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
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : _submit,
            icon: provider.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(provider.isSaving ? 'Đang lưu...' : 'Lưu'),
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) => _emptyToNull(value) == null ? message : null;
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
    return double.tryParse((value ?? '').replaceAll(',', '').trim()) ?? 0;
  }

  double? _readNullableNumber(String? value) {
    final text = value?.replaceAll(',', '').trim();
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
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_rounded),
        ),
        child: Text(
          value == null ? 'Chọn ngày' : DateFormatter.formatDate(value!),
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

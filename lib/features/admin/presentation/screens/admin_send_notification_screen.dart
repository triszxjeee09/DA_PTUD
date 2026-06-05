import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/admin_notification_request_model.dart';
import '../../data/services/admin_notification_service.dart';

class AdminSendNotificationScreen extends StatefulWidget {
  const AdminSendNotificationScreen({super.key});

  @override
  State<AdminSendNotificationScreen> createState() =>
      _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState
    extends State<AdminSendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _referenceIdController = TextEditingController();
  final AdminNotificationService _service = AdminNotificationService(
    dioClient: DioClient(),
  );

  bool _sendToAllCustomers = true;
  bool _isSubmitting = false;
  String _type = 'SYSTEM';

  @override
  void dispose() {
    _userIdController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _referenceIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final request = AdminNotificationRequestModel(
      userId: _sendToAllCustomers ? null : _emptyToNull(_userIdController.text),
      sendToAllCustomers: _sendToAllCustomers,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _type,
      referenceId: _emptyToNull(_referenceIdController.text),
    );

    try {
      await _service.sendNotification(request);

      if (!mounted) {
        return;
      }

      _showMessage('Gửi thông báo thành công');
      _clearForm();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message.trim().isEmpty
            ? 'Không thể gửi thông báo, vui lòng thử lại'
            : error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Không thể gửi thông báo, vui lòng thử lại');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _userIdController.clear();
    _titleController.clear();
    _contentController.clear();
    _referenceIdController.clear();
    setState(() {
      _sendToAllCustomers = true;
      _type = 'SYSTEM';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi thông báo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Card(
              child: SwitchListTile(
                activeColor: AppTheme.primaryBlue,
                value: _sendToAllCustomers,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() => _sendToAllCustomers = value);
                      },
                secondary: const Icon(Icons.groups_rounded),
                title: const Text('Gửi cho tất cả khách hàng'),
                subtitle: Text(
                  _sendToAllCustomers
                      ? 'Thông báo sẽ được gửi đến toàn bộ khách hàng'
                      : 'Nhập userId của người nhận cụ thể',
                ),
              ),
            ),
            if (!_sendToAllCustomers) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _userIdController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Nhập userId người nhận',
                  prefixIcon: Icon(Icons.person_search_rounded),
                ),
                validator: (value) {
                  if (_sendToAllCustomers) {
                    return null;
                  }

                  return _emptyToNull(value) == null
                      ? 'User ID không được rỗng'
                      : null;
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề thông báo',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (value) => _emptyToNull(value) == null
                  ? 'Tiêu đề không được rỗng'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              enabled: !_isSubmitting,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Nội dung thông báo',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              validator: (value) => _emptyToNull(value) == null
                  ? 'Nội dung không được rỗng'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Loại thông báo',
                prefixIcon: Icon(Icons.notifications_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'SYSTEM', child: Text('SYSTEM')),
                DropdownMenuItem(value: 'PROMOTION', child: Text('PROMOTION')),
                DropdownMenuItem(value: 'ORDER', child: Text('ORDER')),
                DropdownMenuItem(
                  value: 'PRESCRIPTION',
                  child: Text('PRESCRIPTION'),
                ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() => _type = value);
                    },
              validator: (value) => _emptyToNull(value) == null
                  ? 'Loại thông báo không được rỗng'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _referenceIdController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Reference ID',
                hintText: 'Không bắt buộc',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi thông báo'),
          ),
        ),
      ),
    );
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

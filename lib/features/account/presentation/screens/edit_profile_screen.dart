import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/xfile_image.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _previewAvatar;

  Future<void> _showAvatarSourceSheet() async {
    final provider = context.read<AuthProvider>();
    if (provider.isUploadingAvatar) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Chụp ảnh'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                const Divider(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    await _pickAndUploadAvatar(source);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 86,
        maxWidth: 1200,
      );
      if (pickedFile == null || !mounted) {
        return;
      }

      final avatarFile = pickedFile;
      setState(() => _previewAvatar = avatarFile);

      final provider = context.read<AuthProvider>();
      final success = await provider.uploadAndUpdateAvatar(avatarFile);
      if (!mounted) {
        return;
      }

      if (success) {
        setState(() => _previewAvatar = null);
        _showSnackBar('Cập nhật ảnh đại diện thành công');
        return;
      }

      setState(() => _previewAvatar = null);
      _showSnackBar(
        provider.avatarErrorMessage ?? 'Không thể cập nhật ảnh đại diện',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _previewAvatar = null);
      _showSnackBar('Không thể chọn ảnh. Vui lòng thử lại.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Vui lòng đăng nhập để cập nhật hồ sơ.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AvatarSection(
                      user: user,
                      previewAvatar: _previewAvatar,
                      isUploading: authProvider.isUploadingAvatar,
                      onChangeAvatar: _showAvatarSourceSheet,
                    ),
                    const SizedBox(height: 18),
                    _ProfileInfoCard(user: user),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.user,
    required this.isUploading,
    required this.onChangeAvatar,
    this.previewAvatar,
  });

  final UserModel user;
  final XFile? previewAvatar;
  final bool isUploading;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          children: [
            _EditableAvatar(
              avatarUrl: user.avatarUrl,
              previewAvatar: previewAvatar,
              isUploading: isUploading,
            ),
            const SizedBox(height: 14),
            Text(
              user.fullName?.trim().isNotEmpty == true
                  ? user.fullName!.trim()
                  : 'Khách hàng An Tâm',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              isUploading ? 'Đang tải ảnh...' : 'Ảnh đại diện tài khoản',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: isUploading ? null : onChangeAvatar,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Thay ảnh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.isUploading,
    this.avatarUrl,
    this.previewAvatar,
  });

  final String? avatarUrl;
  final XFile? previewAvatar;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryBlue, width: 3),
          ),
          child: ClipOval(
            child: _AvatarImage(avatarUrl: avatarUrl, file: previewAvatar),
          ),
        ),
        if (isUploading)
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.32),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({this.avatarUrl, this.file});

  final String? avatarUrl;
  final XFile? file;

  @override
  Widget build(BuildContext context) {
    final localFile = file;
    if (localFile != null) {
      return XFileImage(
        file: localFile,
        width: 116,
        height: 116,
        fit: BoxFit.cover,
      );
    }

    final imageUrl = avatarUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(
        Icons.person_rounded,
        color: AppTheme.primaryBlue,
        size: 62,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 116,
      height: 116,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
      errorWidget: (_, __, ___) => const Icon(
        Icons.person_rounded,
        color: AppTheme.primaryBlue,
        size: 62,
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin tài khoản',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Họ và tên',
              value: user.fullName,
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: user.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text == null || text.isEmpty ? 'Chưa cập nhật' : text,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

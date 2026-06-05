import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../providers/prescription_provider.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _noteController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<File> _selectedFiles = [];

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientPhoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image == null || !mounted) {
        return;
      }

      setState(() => _selectedFiles.add(File(image.path)));
      context.read<PrescriptionProvider>().clearError();
    } catch (_) {
      _showSnackBar('Không thể mở máy ảnh. Vui lòng thử lại.');
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty || !mounted) {
        return;
      }

      setState(
        () => _selectedFiles.addAll(images.map((image) => File(image.path))),
      );
      context.read<PrescriptionProvider>().clearError();
    } catch (_) {
      _showSnackBar('Không thể chọn ảnh. Vui lòng thử lại.');
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_selectedFiles.isEmpty) {
      _showSnackBar('Vui lòng chọn ít nhất một ảnh đơn thuốc');
      return;
    }

    final provider = context.read<PrescriptionProvider>();
    final success = await provider.uploadPrescription(
      patientName: _patientNameController.text.trim(),
      patientPhone: _patientPhoneController.text.trim().isEmpty
          ? null
          : _patientPhoneController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      files: _selectedFiles,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gửi đơn thuốc thành công')));

      final prescriptionId = provider.selectedPrescription?.id;
      if (prescriptionId != null && prescriptionId.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.prescriptionDetail,
          arguments: {'id': prescriptionId},
        );
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.prescriptions);
      }
      return;
    }

    _showSnackBar(provider.errorMessage ?? 'Không thể gửi đơn thuốc');
  }

  void _removeImage(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = context.watch<PrescriptionProvider>().isUploading;

    return Scaffold(
      appBar: AppBar(title: const Text('Gửi đơn thuốc')),
      body: SafeArea(
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: isUploading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Chụp hoặc tải lên đơn thuốc để dược sĩ kiểm tra và tư vấn sản phẩm phù hợp',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _UploadArea(
                        imageCount: _selectedFiles.length,
                        onTakePhoto: _takePhoto,
                        onPickImages: _pickImages,
                      ),
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SelectedImageList(
                          files: _selectedFiles,
                          onRemove: _removeImage,
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _patientNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Tên bệnh nhân',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên bệnh nhân';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _patientPhoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại bệnh nhân',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _noteController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú cho dược sĩ',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _WarningNote(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isUploading ? null : _submit,
                        child: isUploading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Gửi đơn thuốc'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.72),
                  child: const AppLoading(message: 'Đang gửi đơn thuốc...'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea({
    required this.imageCount,
    required this.onTakePhoto,
    required this.onPickImages,
  });

  final int imageCount;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickImages;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppTheme.primaryBlue.withValues(alpha: 0.45),
        radius: 18,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.lightBlue.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.primaryBlue,
                size: 34,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              imageCount == 0
                  ? 'Tải ảnh đơn thuốc lên'
                  : 'Đã chọn $imageCount ảnh đơn thuốc',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Ảnh rõ nét giúp dược sĩ kiểm tra nhanh và chính xác hơn.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTakePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Chụp ảnh đơn thuốc'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onPickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh từ thư viện'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedImageList extends StatelessWidget {
  const _SelectedImageList({required this.files, required this.onRemove});

  final List<File> files;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  files[index],
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => onRemove(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WarningNote extends StatelessWidget {
  const _WarningNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.28)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đơn thuốc sẽ được dược sĩ kiểm tra trước khi xử lý đơn hàng.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.dashWidth = 8,
    this.gapWidth = 5,
  });

  final Color color;
  final double radius;
  final double dashWidth;
  final double gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final dashEnd = nextDistance.clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, dashEnd), paint);
        distance = nextDistance + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.gapWidth != gapWidth;
  }
}

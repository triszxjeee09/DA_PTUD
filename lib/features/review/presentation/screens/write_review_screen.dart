import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../providers/review_provider.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({
    super.key,
    required this.productId,
    required this.productName,
    this.productImage,
    this.orderId,
    this.unitPrice,
  });

  final String productId;
  final String productName;
  final String? productImage;
  final String? orderId;
  final double? unitPrice;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  static const List<String> _suggestions = [
    'Sản phẩm đúng mô tả',
    'Giao hàng nhanh',
    'Đóng gói cẩn thận',
    'Tư vấn tốt',
  ];

  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _appendSuggestion(String value) {
    final current = _commentController.text.trim();
    final next = current.isEmpty ? value : '$current. $value';
    _commentController
      ..text = next
      ..selection = TextSelection.collapsed(offset: next.length);
  }

  Future<void> _submit() async {
    if (widget.productId.trim().isEmpty) {
      _showSnackBar('Không tìm thấy sản phẩm để đánh giá');
      return;
    }

    if (_rating < 1 || _rating > 5) {
      _showSnackBar('Vui lòng chọn số sao từ 1 đến 5');
      return;
    }

    final provider = context.read<ReviewProvider>();
    final success = await provider.createReview(
      productId: widget.productId,
      orderId: widget.orderId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Đánh giá sản phẩm thành công')),
        );
      Navigator.of(context).pop(true);
      return;
    }

    _showSnackBar(provider.errorMessage ?? 'Không thể gửi đánh giá');
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<ReviewProvider>().isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá sản phẩm')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ProductSummary(
              productName: widget.productName,
              productImage: widget.productImage,
              unitPrice: widget.unitPrice,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn hài lòng với sản phẩm chứ?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _RatingPicker(
                      rating: _rating,
                      onChanged: (value) => setState(() => _rating = value),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _commentController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestions
                          .map(
                            (suggestion) => ActionChip(
                              label: Text(suggestion),
                              onPressed: () => _appendSuggestion(suggestion),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            AppPrimaryButton(
              label: 'Gửi đánh giá',
              icon: Icons.rate_review_outlined,
              isLoading: isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({
    required this.productName,
    this.productImage,
    this.unitPrice,
  });

  final String productName;
  final String? productImage;
  final double? unitPrice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 86,
                height: 86,
                color: AppTheme.lightBlue,
                child: productImage == null || productImage!.trim().isEmpty
                    ? const Icon(
                        Icons.medication_liquid_outlined,
                        color: AppTheme.primaryBlue,
                        size: 42,
                      )
                    : CachedNetworkImage(
                        imageUrl: productImage!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.medication_liquid_outlined,
                          color: AppTheme.primaryBlue,
                          size: 42,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  if (unitPrice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Đơn giá: ${CurrencyFormatter.format(unitPrice!)}',
                      style: const TextStyle(color: AppTheme.textSecondary),
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

class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= rating;
        return IconButton(
          onPressed: () => onChanged(value),
          iconSize: 38,
          splashRadius: 26,
          icon: Icon(
            selected ? Icons.star_rounded : Icons.star_border_rounded,
            color: selected ? AppTheme.warning : AppTheme.textSecondary,
          ),
        );
      }),
    );
  }
}

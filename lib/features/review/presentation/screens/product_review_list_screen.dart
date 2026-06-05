import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/product_review_model.dart';
import '../../providers/review_provider.dart';

class ProductReviewListScreen extends StatefulWidget {
  const ProductReviewListScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductReviewListScreen> createState() =>
      _ProductReviewListScreenState();
}

class _ProductReviewListScreenState extends State<ProductReviewListScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.productId.isNotEmpty) {
        _loadReviews(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.productId.isEmpty) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      final provider = context.read<ReviewProvider>();
      if (provider.hasMore && !provider.isLoading && !provider.isLoadingMore) {
        _loadReviews();
      }
    }
  }

  Future<void> _loadReviews({bool refresh = false}) {
    return context.read<ReviewProvider>().loadReviewsByProduct(
      productId: widget.productId,
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final reviews = provider.productReviews;

    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá sản phẩm')),
      body: widget.productId.isEmpty
          ? const _ReviewErrorView(message: 'Không tìm thấy sản phẩm.')
          : RefreshIndicator(
              onRefresh: () => _loadReviews(refresh: true),
              child: _buildBody(provider, reviews),
            ),
    );
  }

  Widget _buildBody(ReviewProvider provider, List<ProductReviewModel> reviews) {
    if (provider.isLoading && reviews.isEmpty) {
      return const AppLoading(message: 'Đang tải đánh giá...');
    }

    if (provider.errorMessage != null && reviews.isEmpty) {
      return _ReviewErrorView(
        message: provider.errorMessage!,
        onRetry: () => _loadReviews(refresh: true),
      );
    }

    if (reviews.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
        children: const [
          AppEmptyState(
            title: 'Sản phẩm chưa có đánh giá',
            message: 'Hãy là người đầu tiên chia sẻ cảm nhận về sản phẩm này.',
            icon: Icons.rate_review_outlined,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: reviews.length + (provider.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= reviews.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (index == 0) {
          return Column(
            children: [
              _ReviewSummaryCard(reviews: reviews),
              const SizedBox(height: 12),
              _ReviewCard(review: reviews[index]),
            ],
          );
        }

        return _ReviewCard(review: reviews[index]);
      },
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.reviews});

  final List<ProductReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
              reviews.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppTheme.warning,
                size: 36,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppTheme.darkBlue,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reviews.length} đánh giá đang hiển thị',
                    style: const TextStyle(color: AppTheme.textSecondary),
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProductReviewModel review;

  @override
  Widget build(BuildContext context) {
    final name = review.userFullName?.trim().isNotEmpty == true
        ? review.userFullName!.trim()
        : 'Khách hàng';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserAvatar(imageUrl: review.userAvatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      _StarRow(rating: review.rating),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review.createdAt),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (review.comment?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(review.comment!.trim(), style: const TextStyle(height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return const CircleAvatar(
        backgroundColor: AppTheme.lightBlue,
        child: Icon(Icons.person_outline, color: AppTheme.primaryBlue),
      );
    }

    return CircleAvatar(
      backgroundColor: AppTheme.lightBlue,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              const Icon(Icons.person_outline, color: AppTheme.primaryBlue),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final normalizedRating = rating.clamp(0, 5);

    return Row(
      children: List.generate(5, (index) {
        final selected = index < normalizedRating;
        return Icon(
          selected ? Icons.star_rounded : Icons.star_border_rounded,
          color: selected ? AppTheme.warning : AppTheme.textSecondary,
          size: 18,
        );
      }),
    );
  }
}

class _ReviewErrorView extends StatelessWidget {
  const _ReviewErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: AppTheme.primaryBlue,
          size: 72,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 18),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ],
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return 'Đang cập nhật';
  }

  return DateFormatter.formatDate(value);
}

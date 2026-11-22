import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../providers/review_provider.dart';

/// Các đánh giá do chính khách hàng đã viết, kèm phản hồi từ nhà thuốc.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReviewProvider>().loadMyReviews(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final reviews = provider.myReviews;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Đánh giá của tôi')),
      body: RefreshIndicator(
        onRefresh: () => provider.loadMyReviews(refresh: true),
        child: provider.isLoading && reviews.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : reviews.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 140),
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 56,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      provider.errorMessage ?? 'Bạn chưa viết đánh giá nào',
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: review.productId == null
                          ? null
                          : () => Navigator.of(context).pushNamed(
                              AppRoutes.productDetail,
                              arguments: {'id': review.productId},
                            ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.productName ?? 'Sản phẩm',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Row(
                              children: [
                                for (var i = 1; i <= 5; i++)
                                  Icon(
                                    i <= review.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color: AppTheme.warning,
                                  ),
                              ],
                            ),
                            if (review.comment != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(review.comment!),
                              ),
                            if (review.staffReply != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(10),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.lightBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Nhà thuốc: ${review.staffReply}'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

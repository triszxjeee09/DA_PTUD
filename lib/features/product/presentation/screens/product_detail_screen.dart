import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../favorite/presentation/widgets/favorite_button.dart';
import '../../../inventory/data/models/inventory_model.dart';
import '../../../inventory/providers/inventory_provider.dart';
import '../../../review/data/models/product_review_model.dart';
import '../../../review/providers/review_provider.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedQuantity = 1;
  bool _isAddingToCart = false;
  bool _isBuyingNow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.productId.isNotEmpty) {
        context.read<ProductProvider>().loadProductDetail(widget.productId);
        context.read<ReviewProvider>().loadReviewsByProduct(
          productId: widget.productId,
          refresh: true,
        );
        context.read<InventoryProvider>().loadInventoryByProduct(
          widget.productId,
        );
      }
    });
  }

  void _increaseQuantity() {
    setState(() {
      _selectedQuantity += 1;
    });
  }

  void _decreaseQuantity() {
    if (_selectedQuantity == 1) {
      return;
    }

    setState(() {
      _selectedQuantity -= 1;
    });
  }

  Future<void> _addToCart(ProductModel product, {bool buyNow = false}) async {
    if (_isAddingToCart || _isBuyingNow) {
      return;
    }

    setState(() {
      if (buyNow) {
        _isBuyingNow = true;
      } else {
        _isAddingToCart = true;
      }
    });

    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addToCart(
      product.id,
      quantity: _selectedQuantity,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isAddingToCart = false;
      _isBuyingNow = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã thêm sản phẩm vào giỏ hàng')),
      );

      if (product.requiresPrescription) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Sản phẩm này cần đơn thuốc khi đặt hàng'),
          ),
        );
      }

      if (buyNow) {
        Navigator.of(context).pushNamed(AppRoutes.cart);
      }
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          cartProvider.errorMessage ?? 'Không thể thêm sản phẩm vào giỏ hàng',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final product = provider.selectedProduct;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          if (product != null) FavoriteButton(product: product),
          IconButton(
            tooltip: 'Giỏ hàng',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: widget.productId.isEmpty
          ? const _DetailStateMessage(
              title: 'Không tìm thấy sản phẩm',
              message: 'Mã sản phẩm không hợp lệ.',
            )
          : provider.isLoading && product == null
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && product == null
          ? _DetailStateMessage(
              title: 'Không tải được sản phẩm',
              message: provider.errorMessage!,
            )
          : product == null
          ? const _DetailStateMessage(
              title: 'Chưa có dữ liệu',
              message: 'Vui lòng thử lại sau.',
            )
          : _ProductDetailContent(
              product: product,
              selectedQuantity: _selectedQuantity,
              onDecreaseQuantity: _decreaseQuantity,
              onIncreaseQuantity: _increaseQuantity,
            ),
      bottomNavigationBar: product == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isAddingToCart || _isBuyingNow
                            ? null
                            : () => _addToCart(product),
                        icon: _isAddingToCart
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_shopping_cart),
                        label: const Text('Thêm vào giỏ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAddingToCart || _isBuyingNow
                            ? null
                            : () => _addToCart(product, buyNow: true),
                        child: _isBuyingNow
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Mua ngay'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  const _ProductDetailContent({
    required this.product,
    required this.selectedQuantity,
    required this.onDecreaseQuantity,
    required this.onIncreaseQuantity,
  });

  final ProductModel product;
  final int selectedQuantity;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onIncreaseQuantity;

  @override
  Widget build(BuildContext context) {
    final images = _readImages(product);

    return ListView(
      children: [
        _ProductImages(images: images),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (product.requiresPrescription)
                    const _InfoBadge(
                      label: 'Cần đơn thuốc',
                      color: AppTheme.error,
                      icon: Icons.description_outlined,
                    ),
                  const _InfoBadge(
                    label: 'Còn hàng',
                    color: AppTheme.success,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                product.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  height: 1.22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.unit,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: const TextStyle(
                      color: AppTheme.darkBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (product.originalPrice != null &&
                      product.originalPrice! > product.price)
                    Text(
                      CurrencyFormatter.format(product.originalPrice!),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              _QuantitySelector(
                quantity: selectedQuantity,
                onDecrease: onDecreaseQuantity,
                onIncrease: onIncreaseQuantity,
              ),
              const SizedBox(height: 18),
              const _SafetyNotice(),
              const SizedBox(height: 26),
              _ProductReviewPreview(productId: product.id),
              const SizedBox(height: 26),
              const _ProductInventorySection(),
              const SizedBox(height: 26),
              const Text(
                'Thông tin chi tiết',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              _InfoSection(
                title: 'Thông tin chung',
                icon: Icons.info_outline,
                content: _generalInfo(product),
              ),
              _InfoSection(
                title: 'Thành phần',
                icon: Icons.science_outlined,
                content: product.ingredients,
              ),
              _InfoSection(
                title: 'Công dụng',
                icon: Icons.health_and_safety_outlined,
                content: product.description ?? product.shortDescription,
              ),
              _InfoSection(
                title: 'Cách dùng',
                icon: Icons.menu_book_outlined,
                content: product.usageInstructions,
              ),
              _InfoSection(
                title: 'Liều dùng tham khảo',
                icon: Icons.medication_outlined,
                content: product.dosage,
              ),
              _InfoSection(
                title: 'Lưu ý an toàn',
                icon: Icons.warning_amber_outlined,
                content: _joinSafetyNotes(product),
              ),
              _InfoSection(
                title: 'Chống chỉ định',
                icon: Icons.block_outlined,
                content: product.contraindications,
              ),
              _InfoSection(
                title: 'Bảo quản',
                icon: Icons.inventory_2_outlined,
                content: product.storageInstructions,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _readImages(ProductModel product) {
    final urls = <String>[
      ...product.images.map((image) => image.imageUrl),
      if (product.thumbnailUrl != null) product.thumbnailUrl!,
    ].where((url) => url.trim().isNotEmpty).toSet().toList();

    return urls;
  }

  String? _joinSafetyNotes(ProductModel product) {
    final notes = [
      product.sideEffects,
      product.precautions,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (notes.isEmpty) {
      return null;
    }

    return notes.join('\n\n');
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Số lượng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Giảm số lượng',
                onPressed: quantity == 1 ? null : onDecrease,
                icon: const Icon(Icons.remove),
                color: AppTheme.primaryBlue,
              ),
              SizedBox(
                width: 42,
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tăng số lượng',
                onPressed: onIncrease,
                icon: const Icon(Icons.add),
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductImages extends StatelessWidget {
  const _ProductImages({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      color: AppTheme.lightBlue,
      child: images.isEmpty
          ? const Center(
              child: Icon(
                Icons.medication_liquid_outlined,
                color: AppTheme.primaryBlue,
                size: 86,
              ),
            )
          : PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.medication_liquid_outlined,
                    color: AppTheme.primaryBlue,
                    size: 86,
                  ),
                );
              },
            ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông tin chỉ mang tính tham khảo, vui lòng hỏi ý kiến dược sĩ nếu cần.',
              style: TextStyle(color: AppTheme.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductReviewPreview extends StatelessWidget {
  const _ProductReviewPreview({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, provider, _) {
        final reviews = provider.productReviews;
        final previewReviews = reviews.take(2).toList();
        final average = reviews.isEmpty
            ? 0.0
            : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
                  reviews.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Đánh giá sản phẩm',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.productReviews,
                        arguments: {'productId': productId},
                      ),
                      child: const Text('Xem tất cả đánh giá'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (provider.isLoading && reviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reviews.isEmpty)
                  const Text(
                    'Sản phẩm chưa có đánh giá',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else ...[
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.warning),
                      const SizedBox(width: 6),
                      Text(
                        average.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppTheme.darkBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${reviews.length} đánh giá đang hiển thị)',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final review in previewReviews) ...[
                    _ReviewPreviewItem(review: review),
                    if (review != previewReviews.last)
                      const Divider(height: 20),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductInventorySection extends StatelessWidget {
  const _ProductInventorySection();

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final inventories = provider.productInventories;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sản phẩm có tại nhà thuốc',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                if (provider.isLoading && inventories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.errorMessage != null && inventories.isEmpty)
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  )
                else if (inventories.isEmpty)
                  const Text(
                    'Chưa có thông tin tồn kho cho sản phẩm này',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  for (final inventory in inventories) ...[
                    _ProductInventoryItem(inventory: inventory),
                    if (inventory != inventories.last)
                      const Divider(height: 24),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductInventoryItem extends StatelessWidget {
  const _ProductInventoryItem({required this.inventory});

  final InventoryModel inventory;

  @override
  Widget build(BuildContext context) {
    final inStock = inventory.quantity > 0;
    final pharmacyName = inventory.pharmacyName?.trim().isNotEmpty == true
        ? inventory.pharmacyName!.trim()
        : 'Nhà thuốc';
    final address = inventory.pharmacyAddress?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_pharmacy_outlined,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacyName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (address != null && address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StockChip(inStock: inStock),
                      Text(
                        'Còn lại: ${inventory.quantity}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: inventory.pharmacyId.trim().isEmpty
                ? null
                : () => Navigator.of(context).pushNamed(
                    AppRoutes.pharmacyDetail,
                    arguments: {'pharmacyId': inventory.pharmacyId},
                  ),
            child: const Text('Xem nhà thuốc'),
          ),
        ),
      ],
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.inStock});

  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final color = inStock ? AppTheme.success : AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        inStock ? 'Còn hàng' : 'Hết hàng',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ReviewPreviewItem extends StatelessWidget {
  const _ReviewPreviewItem({required this.review});

  final ProductReviewModel review;

  @override
  Widget build(BuildContext context) {
    final name = review.userFullName?.trim().isNotEmpty == true
        ? review.userFullName!.trim()
        : 'Khách hàng';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _ReviewStars(rating: review.rating),
          ],
        ),
        if (review.comment?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            review.comment!.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
        ],
      ],
    );
  }
}

class _ReviewStars extends StatelessWidget {
  const _ReviewStars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final normalizedRating = rating.clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final selected = index < normalizedRating;
        return Icon(
          selected ? Icons.star_rounded : Icons.star_border_rounded,
          color: selected ? AppTheme.warning : AppTheme.textSecondary,
          size: 16,
        );
      }),
    );
  }
}

String? _generalInfo(ProductModel product) {
  final lines = <String>[
    if (product.dosageForm != null) 'Dạng bào chế: ${product.dosageForm}',
    if (product.targetAudience != null)
      'Đối tượng sử dụng: ${product.targetAudience}',
    if (product.manufacturer != null)
      'Nhà sản xuất: ${product.manufacturer}',
    if (product.symptoms != null) 'Dùng cho: ${product.symptoms}',
  ];
  return lines.isEmpty ? null : lines.join('\n');
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String? content;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: AppTheme.primaryBlue),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                content == null || content!.trim().isEmpty
                    ? 'Chưa có thông tin'
                    : content!,
                style: const TextStyle(height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStateMessage extends StatelessWidget {
  const _DetailStateMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.primaryBlue,
              size: 58,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

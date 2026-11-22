import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../favorite/presentation/widgets/favorite_button.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../widgets/product_filter_sheet.dart';

enum _ProductQuickFilter {
  all('Tất cả'),
  bestSeller('Bán chạy'),
  prescription('Cần đơn thuốc'),
  nonPrescription('Không cần đơn'),
  discount('Giảm giá');

  const _ProductQuickFilter(this.label);

  final String label;
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.arguments});

  final Map<String, dynamic>? arguments;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  final Set<String> _addingProductIds = <String>{};

  _ProductQuickFilter _selectedFilter = _ProductQuickFilter.all;
  Map<String, dynamic> _advancedFilters = <String, dynamic>{};

  String? get _categoryId => widget.arguments?['categoryId']?.toString();
  String? get _brandId => widget.arguments?['brandId']?.toString();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController(
      text: widget.arguments?['keyword']?.toString() ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProducts(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      final provider = context.read<ProductProvider>();
      if (provider.hasMore && !provider.isLoading && !provider.isLoadingMore) {
        _loadProducts();
      }
    }
  }

  Future<void> _loadProducts({bool refresh = false}) {
    return context.read<ProductProvider>().loadProducts(
      keyword: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      categoryId: _categoryId,
      brandId: _brandId,
      requiresPrescription: switch (_selectedFilter) {
        _ProductQuickFilter.prescription => true,
        _ProductQuickFilter.nonPrescription => false,
        _ => null,
      },
      isFeatured: _selectedFilter == _ProductQuickFilter.bestSeller
          ? true
          : null,
      extraFilters: _advancedFilters.isEmpty ? null : _advancedFilters,
      refresh: refresh,
    );
  }

  Future<void> _openFilters() async {
    final result = await ProductFilterSheet.show(context, _advancedFilters);
    if (result == null || !mounted) {
      return;
    }
    setState(() => _advancedFilters = result);
    await _loadProducts(refresh: true);
  }

  Future<void> _addToCart(ProductModel product) async {
    if (_addingProductIds.contains(product.id)) {
      return;
    }

    setState(() {
      _addingProductIds.add(product.id);
    });

    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addToCart(product.id, quantity: 1);

    if (!mounted) {
      return;
    }

    setState(() {
      _addingProductIds.remove(product.id);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        title: Text(
          widget.arguments?['categoryName']?.toString().trim().isNotEmpty ==
                  true
              ? widget.arguments!['categoryName'].toString()
              : 'Sản phẩm',
        ),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: _advancedFilters.isNotEmpty,
              label: Text('${_advancedFilters.length}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _loadProducts(refresh: true),
                      decoration: InputDecoration(
                        hintText: 'Tìm thuốc, triệu chứng, vitamin...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Tìm kiếm',
                          onPressed: () => _loadProducts(refresh: true),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _ProductQuickFilter.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _ProductQuickFilter.values[index];
                          final selected = filter == _selectedFilter;

                          return ChoiceChip(
                            label: Text(filter.label),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                              _loadProducts(refresh: true);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (provider.isLoading && provider.products.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.errorMessage != null && provider.products.isEmpty)
              SliverFillRemaining(
                child: _StateMessage(
                  icon: Icons.wifi_off_outlined,
                  title: 'Không tải được sản phẩm',
                  message: provider.errorMessage!,
                  actionLabel: 'Thử lại',
                  onAction: () => _loadProducts(refresh: true),
                ),
              )
            else if (provider.products.isEmpty)
              const SliverFillRemaining(
                child: _StateMessage(
                  icon: Icons.inventory_2_outlined,
                  title: 'Chưa có sản phẩm',
                  message: 'Vui lòng thử từ khóa hoặc bộ lọc khác.',
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = provider.products[index];

                    return _ProductGridCard(
                      product: product,
                      isAddingToCart: _addingProductIds.contains(product.id),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.productDetail,
                          arguments: {'id': product.id},
                        );
                      },
                      onAddToCart: () => _addToCart(product),
                    );
                  }, childCount: provider.products.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: provider.isLoadingMore
                        ? const CircularProgressIndicator()
                        : provider.hasMore
                        ? const SizedBox.shrink()
                        : const Text(
                            'Đã hiển thị tất cả sản phẩm',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    required this.product,
    required this.isAddingToCart,
    required this.onTap,
    required this.onAddToCart,
  });

  final ProductModel product;
  final bool isAddingToCart;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          color: AppTheme.lightBlue,
                          child: product.thumbnailUrl == null
                              ? const Icon(
                                  Icons.medication_liquid_outlined,
                                  color: AppTheme.primaryBlue,
                                  size: 48,
                                )
                              : CachedNetworkImage(
                                  imageUrl: product.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.medication_liquid_outlined,
                                    color: AppTheme.primaryBlue,
                                    size: 48,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (product.requiresPrescription)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          label: 'Cần đơn thuốc',
                          color: AppTheme.error,
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: FavoriteButton(product: product, compact: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.format(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.darkBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (product.originalPrice != null &&
                            product.originalPrice! > product.price)
                          Text(
                            CurrencyFormatter.format(product.originalPrice!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Thêm vào giỏ hàng',
                    onPressed: isAddingToCart ? null : onAddToCart,
                    icon: isAddingToCart
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 54),
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

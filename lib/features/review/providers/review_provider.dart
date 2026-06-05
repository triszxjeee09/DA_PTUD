import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/create_product_review_request_model.dart';
import '../data/models/product_review_model.dart';
import '../data/services/review_service.dart';

enum _ReviewListMode { product, mine }

class ReviewProvider extends ChangeNotifier {
  ReviewProvider({ReviewService? reviewService})
    : _reviewService = reviewService ?? ReviewService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const int _pageSize = 10;

  final ReviewService _reviewService;

  List<ProductReviewModel> _productReviews = const [];
  List<ProductReviewModel> _myReviews = const [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentProductId;
  _ReviewListMode? _currentMode;

  List<ProductReviewModel> get productReviews => _productReviews;
  List<ProductReviewModel> get myReviews => _myReviews;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;

  Future<bool> createReview({
    required String productId,
    String? orderId,
    required int rating,
    String? comment,
  }) async {
    _setSubmitting(true);

    try {
      final review = await _reviewService.createReview(
        CreateProductReviewRequestModel(
          productId: productId,
          orderId: _normalizeText(orderId),
          rating: rating,
          comment: _normalizeText(comment),
        ),
      );
      _myReviews = [review, ..._myReviews];
      if (_currentProductId == productId) {
        _productReviews = [review, ..._productReviews];
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> loadReviewsByProduct({
    required String productId,
    bool refresh = false,
  }) async {
    final productChanged =
        _currentMode != _ReviewListMode.product ||
        _currentProductId != productId;

    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh || productChanged) {
      _productReviews = const [];
      _currentPage = 0;
      _hasMore = true;
      _currentProductId = productId;
      _currentMode = _ReviewListMode.product;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_hasMore) {
      return;
    }

    final pageToLoad = _currentPage;
    if (_productReviews.isEmpty) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    try {
      final pageResponse = await _reviewService.getReviewsByProduct(
        productId: productId,
        page: pageToLoad,
        size: _pageSize,
      );

      _productReviews = pageToLoad == 0
          ? pageResponse.content
          : [..._productReviews, ...pageResponse.content];
      _currentPage = pageToLoad + 1;
      _hasMore = !pageResponse.last && _currentPage < pageResponse.totalPages;
      _currentProductId = productId;
      _currentMode = _ReviewListMode.product;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  Future<void> loadMyReviews({bool refresh = false}) async {
    final modeChanged = _currentMode != _ReviewListMode.mine;

    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh || modeChanged) {
      _myReviews = const [];
      _currentPage = 0;
      _hasMore = true;
      _currentMode = _ReviewListMode.mine;
      _currentProductId = null;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_hasMore) {
      return;
    }

    final pageToLoad = _currentPage;
    if (_myReviews.isEmpty) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    try {
      final pageResponse = await _reviewService.getMyReviews(
        page: pageToLoad,
        size: _pageSize,
      );

      _myReviews = pageToLoad == 0
          ? pageResponse.content
          : [..._myReviews, ...pageResponse.content];
      _currentPage = pageToLoad + 1;
      _hasMore = !pageResponse.last && _currentPage < pageResponse.totalPages;
      _currentMode = _ReviewListMode.mine;
      _currentProductId = null;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) {
      return;
    }

    _isSubmitting = value;
    notifyListeners();
  }

  void _setLoadingMore(bool value) {
    if (_isLoadingMore == value) {
      return;
    }

    _isLoadingMore = value;
    notifyListeners();
  }

  String? _normalizeText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}

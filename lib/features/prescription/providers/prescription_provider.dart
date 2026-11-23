import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/prescription_model.dart';
import '../data/services/prescription_service.dart';

class PrescriptionProvider extends ChangeNotifier {
  PrescriptionProvider({PrescriptionService? prescriptionService})
    : _prescriptionService = prescriptionService ?? PrescriptionService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const int _pageSize = 10;

  final PrescriptionService _prescriptionService;

  List<PrescriptionModel> _prescriptions = const [];
  PrescriptionModel? _selectedPrescription;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentStatusFilter;

  List<PrescriptionModel> get prescriptions => _prescriptions;
  PrescriptionModel? get selectedPrescription => _selectedPrescription;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String? get currentStatusFilter => _currentStatusFilter;

  Future<bool> uploadPrescription({
    required String patientName,
    String? patientPhone,
    String? note,
    required List<XFile> files,
  }) async {
    _setUploading(true);

    try {
      _selectedPrescription = await _prescriptionService.uploadPrescription(
        patientName: patientName,
        patientPhone: patientPhone,
        note: note,
        files: files,
      );
      _errorMessage = null;
      notifyListeners();
      await loadMyPrescriptions(status: _currentStatusFilter, refresh: true);
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    } finally {
      _setUploading(false);
    }
  }

  Future<void> loadMyPrescriptions({
    String? status,
    bool refresh = false,
  }) async {
    final normalizedStatus = _normalizeStatus(status);
    final statusChanged = normalizedStatus != _currentStatusFilter;

    if (_isLoading || _isLoadingMore) {
      return;
    }

    if (refresh || statusChanged) {
      _prescriptions = const [];
      _currentPage = 0;
      _hasMore = true;
      _currentStatusFilter = normalizedStatus;
      _errorMessage = null;
      notifyListeners();
    }

    if (!_hasMore) {
      return;
    }

    final pageToLoad = _currentPage;
    if (_prescriptions.isEmpty) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    try {
      final pageResponse = await _prescriptionService.getMyPrescriptions(
        page: pageToLoad,
        size: _pageSize,
        status: _currentStatusFilter,
      );

      _prescriptions = pageToLoad == 0
          ? pageResponse.content
          : [..._prescriptions, ...pageResponse.content];
      _currentPage = pageToLoad + 1;
      _hasMore = !pageResponse.last && _currentPage < pageResponse.totalPages;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  Future<void> loadPrescriptionDetail(String id) async {
    _setLoading(true);

    try {
      _selectedPrescription = await _prescriptionService.getPrescriptionDetail(
        id,
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  void clearSelectedPrescription() {
    if (_selectedPrescription == null) {
      return;
    }

    _selectedPrescription = null;
    notifyListeners();
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

  void _setUploading(bool value) {
    if (_isUploading == value) {
      return;
    }

    _isUploading = value;
    notifyListeners();
  }

  void _setLoadingMore(bool value) {
    if (_isLoadingMore == value) {
      return;
    }

    _isLoadingMore = value;
    notifyListeners();
  }

  String? _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) {
      return null;
    }

    return status.trim();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}

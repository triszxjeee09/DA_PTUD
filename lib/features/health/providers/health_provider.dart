import 'package:flutter/foundation.dart';

import '../../../core/sync/synced_collection.dart';
import '../data/models/health_member.dart';
import '../data/models/health_metric.dart';

/// Hồ sơ sức khỏe gia đình: lưu SQLite trên máy và đồng bộ lên API.
class HealthProvider extends ChangeNotifier {
  HealthProvider({SyncedCollection? members, SyncedCollection? metrics})
    : _members =
          members ??
          SyncedCollection(
            kind: 'health_members',
            listPath: '/health/members',
            createPath: (_) => '/health/members',
            deletePath: (id) => '/health/members/$id',
          ),
      _metrics =
          metrics ??
          SyncedCollection(
            kind: 'health_metrics',
            listPath: '/health/metrics',
            createPath: (item) => '/health/members/${item['memberId']}/metrics',
            deletePath: (id) => '/health/metrics/$id',
          );

  final SyncedCollection _members;
  final SyncedCollection _metrics;

  String? _owner;
  List<HealthMember> _memberList = const [];
  List<HealthMetric> _metricList = const [];
  bool _isLoading = false;
  bool _isOnline = true;

  List<HealthMember> get members => _memberList;
  List<HealthMetric> get metrics => _metricList;
  bool get isLoading => _isLoading;

  /// `false` khi lần đồng bộ gần nhất không kết nối được máy chủ.
  bool get isOnline => _isOnline;

  HealthMember? memberById(String? id) {
    for (final member in _memberList) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
  }

  /// Chỉ số của một thành viên, mới nhất trước.
  List<HealthMetric> metricsOf(String memberId, String type) {
    final list = _metricList
        .where((m) => m.memberId == memberId && m.type == type)
        .toList();
    list.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return list;
  }

  Future<void> load(String owner) async {
    if (_owner != owner) {
      _owner = owner;
      _memberList = const [];
      _metricList = const [];
    }
    _isLoading = true;
    notifyListeners();
    await _reloadLocal(owner);
    _isLoading = false;
    notifyListeners();

    final memberOk = await _members.sync(owner);
    final metricOk = await _metrics.sync(owner);
    _isOnline = memberOk && metricOk;
    await _reloadLocal(owner);
    notifyListeners();
  }

  Future<void> saveMember(HealthMember member) async {
    final owner = _owner;
    if (owner == null) {
      return;
    }
    await _members.save(owner, member.toJson());
    await _reloadLocal(owner);
    notifyListeners();
  }

  Future<String?> deleteMember(HealthMember member) async {
    final owner = _owner;
    if (owner == null) {
      return null;
    }
    if (member.relation == 'SELF') {
      return 'Không thể xóa hồ sơ của bản thân';
    }
    for (final metric in _metricList.where((m) => m.memberId == member.id)) {
      await _metrics.remove(owner, metric.id);
    }
    await _members.remove(owner, member.id);
    await _reloadLocal(owner);
    notifyListeners();
    return null;
  }

  Future<void> addMetric(HealthMetric metric) async {
    final owner = _owner;
    if (owner == null) {
      return;
    }
    await _metrics.save(owner, metric.toJson());
    await _reloadLocal(owner);
    notifyListeners();
  }

  Future<void> deleteMetric(String id) async {
    final owner = _owner;
    if (owner == null) {
      return;
    }
    await _metrics.remove(owner, id);
    await _reloadLocal(owner);
    notifyListeners();
  }

  void resetIfUserChanged(String? userId) {
    if (_owner != null && _owner != userId) {
      _owner = null;
      _memberList = const [];
      _metricList = const [];
    }
  }

  void clear() {
    _owner = null;
    _memberList = const [];
    _metricList = const [];
    notifyListeners();
  }

  Future<void> _reloadLocal(String owner) async {
    final members = await _members.load(owner);
    final metrics = await _metrics.load(owner);
    _memberList = members.map(HealthMember.fromJson).toList();
    _metricList = metrics.map(HealthMetric.fromJson).toList();
  }
}

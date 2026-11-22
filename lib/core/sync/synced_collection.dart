import '../database/local_record_store.dart';
import '../network/json_api.dart';

/// Bộ sưu tập offline-first: đọc/ghi luôn qua SQLite trên thiết bị, sau đó
/// đồng bộ hai chiều với REST API khi có mạng.
///
/// - Ghi: lưu local (chưa đồng bộ) rồi thử đẩy lên API.
/// - Đồng bộ: đẩy các thay đổi đang chờ, sau đó kéo dữ liệu máy chủ về.
/// - Mất mạng: thay đổi giữ nguyên trong SQLite và được gửi ở lần đồng bộ sau.
class SyncedCollection {
  SyncedCollection({
    required this.kind,
    required this.listPath,
    required this.createPath,
    required this.deletePath,
    this.bodyOf,
    JsonApi? api,
    LocalRecordStore? store,
  }) : _api = api ?? JsonApi(),
       _store = store ?? LocalRecordStore.instance;

  final String kind;
  final String listPath;
  final String Function(Map<String, dynamic> item) createPath;
  final String? Function(String id) deletePath;
  final Object Function(Map<String, dynamic> item)? bodyOf;

  final JsonApi _api;
  final LocalRecordStore _store;

  Future<List<Map<String, dynamic>>> load(String owner) async {
    final records = await _store.list(owner, kind);
    return records.map((record) => record.data).toList();
  }

  Future<void> save(String owner, Map<String, dynamic> item) async {
    final id = item['id'].toString();
    await _store.upsert(owner, kind, id, item);
    await syncPending(owner);
  }

  Future<void> remove(String owner, String id) async {
    final record = await _store.find(owner, kind, id);
    if (record == null) {
      return;
    }
    if (deletePath(id) == null) {
      await _store.purge(owner, kind, id);
      return;
    }
    await _store.markDeleted(owner, kind, id);
    await syncPending(owner);
  }

  /// Đẩy thay đổi đang chờ. Trả về `true` nếu đã đẩy hết (không còn bản ghi chờ).
  Future<bool> syncPending(String owner) async {
    final pending = await _store.pending(owner, kind);
    var allSynced = true;
    for (final record in pending) {
      try {
        if (record.deleted) {
          final path = deletePath(record.id);
          if (path != null) {
            await _api.delete(path);
          }
          await _store.purge(owner, kind, record.id);
        } else {
          await _api.post(
            createPath(record.data),
            body: bodyOf == null ? record.data : bodyOf!(record.data),
          );
          await _store.markSynced(owner, kind, record.id);
        }
      } catch (_) {
        allSynced = false;
      }
    }
    return allSynced;
  }

  /// Đồng bộ hai chiều. Không ném lỗi: mất mạng thì giữ nguyên dữ liệu local.
  Future<bool> sync(String owner) async {
    final pushed = await syncPending(owner);
    if (!pushed) {
      return false;
    }

    try {
      final remote = JsonApi.asList(await _api.get(listPath));
      final remoteIds = <String>{};
      for (final item in remote) {
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) {
          continue;
        }
        remoteIds.add(id);
        final local = await _store.find(owner, kind, id);
        if (local == null || local.synced) {
          await _store.upsert(owner, kind, id, item, synced: true);
        }
      }

      final locals = await _store.list(owner, kind);
      for (final record in locals) {
        if (record.synced && !remoteIds.contains(record.id)) {
          await _store.purge(owner, kind, record.id);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:async';

enum OutboxSyncStatus { pending, syncing, synced, failed }

class OutboxItem {
  final String id;
  final String targetTable;
  final String recordId;
  final String operation;
  final Map<String, dynamic> payload;
  OutboxSyncStatus status;
  int retryCount;
  String? lastError;
  final DateTime createdAt;

  OutboxItem({
    required this.id,
    required this.targetTable,
    required this.recordId,
    required this.operation,
    required this.payload,
    this.status = OutboxSyncStatus.pending,
    this.retryCount = 0,
    this.lastError,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetTable': targetTable,
    'recordId': recordId,
    'operation': operation,
    'payload': payload,
    'status': status.name,
    'retryCount': retryCount,
    'lastError': lastError,
    'createdAt': createdAt.toIso8601String(),
  };
}

abstract class RemoteSyncClient {
  Future<bool> pushMutation(OutboxItem item);
}

class OutboxSyncService {
  final List<OutboxItem> _queue = [];
  final RemoteSyncClient remoteClient;
  bool _isOnline = true;
  bool _isSyncing = false;

  OutboxSyncService({required this.remoteClient, bool initialOnline = true})
    : _isOnline = initialOnline;

  bool get isOnline => _isOnline;
  int get pendingCount => _queue
      .where(
        (i) =>
            i.status == OutboxSyncStatus.pending ||
            i.status == OutboxSyncStatus.failed,
      )
      .length;
  int get syncedCount =>
      _queue.where((i) => i.status == OutboxSyncStatus.synced).length;
  List<OutboxItem> get allItems => List.unmodifiable(_queue);

  /// Toggle network connectivity state (for test simulation & connectivity listener)
  void setOnline(bool online) {
    _isOnline = online;
    if (_isOnline) {
      processQueue();
    }
  }

  /// Enqueue an idempotent local write into the sync outbox
  void enqueue({
    required String id,
    required String targetTable,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    final item = OutboxItem(
      id: id,
      targetTable: targetTable,
      recordId: recordId,
      operation: operation,
      payload: payload,
    );
    _queue.add(item);

    if (_isOnline) {
      processQueue();
    }
  }

  /// Process pending queue items in FIFO order
  Future<int> processQueue() async {
    if (!_isOnline || _isSyncing) return 0;
    _isSyncing = true;
    int processedCount = 0;

    try {
      final pendingItems = _queue
          .where(
            (i) =>
                i.status == OutboxSyncStatus.pending ||
                i.status == OutboxSyncStatus.failed,
          )
          .toList();

      for (final item in pendingItems) {
        if (!_isOnline) break;

        item.status = OutboxSyncStatus.syncing;
        try {
          final success = await remoteClient.pushMutation(item);
          if (success) {
            item.status = OutboxSyncStatus.synced;
            item.lastError = null;
            processedCount++;
          } else {
            item.status = OutboxSyncStatus.failed;
            item.retryCount++;
            item.lastError = 'Remote rejected mutation';
          }
        } catch (e) {
          item.status = OutboxSyncStatus.failed;
          item.retryCount++;
          item.lastError = e.toString();
        }
      }
    } finally {
      _isSyncing = false;
    }

    return processedCount;
  }
}

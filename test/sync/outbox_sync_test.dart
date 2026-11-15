import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/data/sync/outbox_sync_service.dart';

class MockRemoteSyncClient implements RemoteSyncClient {
  final List<OutboxItem> pushedItems = [];
  bool shouldFail = false;

  @override
  Future<bool> pushMutation(OutboxItem item) async {
    if (shouldFail) {
      throw Exception('Network unreachable: connection timed out');
    }
    pushedItems.add(item);
    return true;
  }
}

void main() {
  group('OutboxSyncService Offline/Online Integration Tests', () {
    late MockRemoteSyncClient mockClient;
    late OutboxSyncService syncService;

    setUp(() {
      mockClient = MockRemoteSyncClient();
      syncService = OutboxSyncService(remoteClient: mockClient, initialOnline: true);
    });

    test('Immediate sync when device is online', () async {
      syncService.enqueue(
        id: 'mut-1',
        targetTable: 'vehicles',
        recordId: 'veh-101',
        operation: 'INSERT',
        payload: {'registration': 'RJ27CA1024', 'make': 'MG MOTOR'},
      );

      await pumpEventQueue();

      expect(syncService.pendingCount, 0);
      expect(syncService.syncedCount, 1);
      expect(mockClient.pushedItems.length, 1);
      expect(mockClient.pushedItems.first.recordId, 'veh-101');
    });

    test('Queues items while offline, flushes automatically when coming online', () async {
      // 1. Go offline
      syncService.setOnline(false);
      expect(syncService.isOnline, isFalse);

      // 2. Perform 3 offline mutations
      syncService.enqueue(
        id: 'mut-1',
        targetTable: 'customers',
        recordId: 'cust-1',
        operation: 'INSERT',
        payload: {'name': 'Bhavyam'},
      );
      syncService.enqueue(
        id: 'mut-2',
        targetTable: 'vehicles',
        recordId: 'veh-1',
        operation: 'INSERT',
        payload: {'reg': 'RJ27CA1024'},
      );
      syncService.enqueue(
        id: 'mut-3',
        targetTable: 'job_cards',
        recordId: 'jc-1',
        operation: 'INSERT',
        payload: {'status': 'RECEIVED'},
      );

      // Verify all 3 are stored locally in the outbox
      expect(syncService.pendingCount, 3);
      expect(syncService.syncedCount, 0);
      expect(mockClient.pushedItems.isEmpty, isTrue);

      // 3. Network reconnects
      syncService.setOnline(true);
      await pumpEventQueue();

      // Verify all 3 were flushed in FIFO order
      expect(syncService.pendingCount, 0);
      expect(syncService.syncedCount, 3);
      expect(mockClient.pushedItems.length, 3);
      expect(mockClient.pushedItems[0].recordId, 'cust-1');
      expect(mockClient.pushedItems[1].recordId, 'veh-1');
      expect(mockClient.pushedItems[2].recordId, 'jc-1');
    });

    test('Network error increments retry count and sets lastError without dropping payload', () async {
      mockClient.shouldFail = true;

      syncService.enqueue(
        id: 'mut-err-1',
        targetTable: 'job_cards',
        recordId: 'jc-err',
        operation: 'UPDATE',
        payload: {'status': 'WORK_IN_PROGRESS'},
      );

      await pumpEventQueue();

      expect(syncService.pendingCount, 1);
      expect(syncService.syncedCount, 0);

      final failedItem = syncService.allItems.first;
      expect(failedItem.status, OutboxSyncStatus.failed);
      expect(failedItem.retryCount, 1);
      expect(failedItem.lastError, contains('Network unreachable'));

      // Now network recovers
      mockClient.shouldFail = false;
      await syncService.processQueue();

      expect(syncService.pendingCount, 0);
      expect(syncService.syncedCount, 1);
      expect(failedItem.status, OutboxSyncStatus.synced);
      expect(failedItem.lastError, isNull);
    });
  });
}

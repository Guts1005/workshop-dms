import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/inventory/inventory_controller.dart';
import 'package:workshop_dms/features/inventory/inventory_models.dart';
import 'package:workshop_dms/features/inventory/inventory_repository.dart';

void main() {
  test('rejects invalid inventory inputs before writing', () async {
    final repository = _FakeInventoryRepository();
    final controller = InventoryController(repository: repository);

    expect(
      await controller.recordMovement(
        partId: 'part',
        type: 'RECEIPT',
        quantityText: 'NaN',
        supplierId: 'supplier',
        note: '',
      ),
      isFalse,
    );
    expect(
      await controller.recordMovement(
        partId: 'part',
        type: 'RECEIPT',
        quantityText: '1',
        note: '',
      ),
      isFalse,
    );
    expect(repository.movementWrites, 0);
  });

  test('adjustment requires an explicit direction and explanation', () async {
    final repository = _FakeInventoryRepository();
    final controller = InventoryController(repository: repository);

    expect(
      await controller.recordMovement(
        partId: 'part',
        type: 'ADJUSTMENT',
        quantityText: '2',
        note: 'incorrect stock',
      ),
      isFalse,
    );
    expect(repository.movementWrites, 0);
  });

  test('stock threshold marks low quantities and formats prices', () {
    expect(_part(onHand: 2, reorder: 2).lowStock, isTrue);
    expect(_part(onHand: 3, reorder: 2).lowStock, isFalse);
    expect(formatInventoryRupees(5050), '₹50.50');
  });
}

InventoryPart _part({required num onHand, required num reorder}) =>
    InventoryPart(
      id: 'part',
      sku: 'OIL-1',
      name: 'Engine oil',
      category: 'Lubricants',
      unit: 'litre',
      gstRatePercent: 18,
      unitCostPaise: 40000,
      unitPricePaise: 50000,
      reorderQuantity: reorder,
      onHandQuantity: onHand,
    );

class _FakeInventoryRepository implements InventoryRepository {
  int movementWrites = 0;

  @override
  Future<InventorySnapshot> load() async => const InventorySnapshot(
    parts: [],
    suppliers: [],
    movements: [],
    canManageCatalog: true,
  );

  @override
  Future<void> saveSupplier({
    required String name,
    required String phone,
    required String gstin,
    required String address,
  }) async {}

  @override
  Future<void> savePart({
    required String sku,
    required String name,
    required String category,
    required String unit,
    required num gstRatePercent,
    required int unitCostPaise,
    required int unitPricePaise,
    required num reorderQuantity,
  }) async {}

  @override
  Future<void> recordMovement({
    required String partId,
    required String type,
    required num quantity,
    String? supplierId,
    String? jobCardId,
    required String note,
  }) async {
    movementWrites++;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'inventory_models.dart';

abstract class InventoryRepository {
  Future<InventorySnapshot> load();
  Future<void> saveSupplier({
    required String name,
    required String phone,
    required String gstin,
    required String address,
  });
  Future<void> savePart({
    required String sku,
    required String name,
    required String category,
    required String unit,
    required num gstRatePercent,
    required int unitCostPaise,
    required int unitPricePaise,
    required num reorderQuantity,
  });
  Future<void> recordMovement({
    required String partId,
    required String type,
    required num quantity,
    String? supplierId,
    String? jobCardId,
    required String note,
  });
}

class SupabaseInventoryRepository implements InventoryRepository {
  SupabaseInventoryRepository(this.client);
  final SupabaseClient client;

  @override
  Future<InventorySnapshot> load() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to access inventory.');
    final membership = await client
        .from('workshop_memberships')
        .select('workshop_id, role')
        .eq('user_id', userId)
        .single();
    final workshopId = membership['workshop_id'] as String;
    final results = await Future.wait([
      client
          .from('inventory_parts')
          .select(
            'id, sku, name, category, unit, gst_rate_percent, unit_cost_paise, unit_price_paise, reorder_quantity, on_hand_quantity',
          )
          .eq('workshop_id', workshopId)
          .eq('active', true)
          .order('name'),
      client
          .from('inventory_suppliers')
          .select('id, name, phone, gstin')
          .eq('workshop_id', workshopId)
          .order('name'),
      client
          .from('inventory_movements')
          .select(
            'part_id, movement_type, quantity_delta, stock_after, note, recorded_by_label, created_at',
          )
          .eq('workshop_id', workshopId)
          .order('created_at', ascending: false)
          .limit(30),
    ]);
    final parts = (results[0] as List).cast<Map<String, dynamic>>();
    final suppliers = (results[1] as List).cast<Map<String, dynamic>>();
    final movementRows = (results[2] as List).cast<Map<String, dynamic>>();
    final partById = {for (final row in parts) row['id'] as String: row};
    return InventorySnapshot(
      parts: parts
          .map(
            (row) => InventoryPart(
              id: row['id'] as String,
              sku: row['sku'] as String,
              name: row['name'] as String,
              category: row['category'] as String? ?? '',
              unit: row['unit'] as String,
              gstRatePercent: row['gst_rate_percent'] as num,
              unitCostPaise: row['unit_cost_paise'] as int,
              unitPricePaise: row['unit_price_paise'] as int,
              reorderQuantity: row['reorder_quantity'] as num,
              onHandQuantity: row['on_hand_quantity'] as num,
            ),
          )
          .toList(),
      suppliers: suppliers
          .map(
            (row) => InventorySupplier(
              id: row['id'] as String,
              name: row['name'] as String,
              phone: row['phone'] as String? ?? '',
              gstin: row['gstin'] as String?,
            ),
          )
          .toList(),
      movements: movementRows.map((row) {
        final part = partById[row['part_id'] as String];
        return InventoryMovement(
          partName: part?['name'] as String? ?? 'Archived part',
          sku: part?['sku'] as String? ?? '',
          type: row['movement_type'] as String,
          quantityDelta: row['quantity_delta'] as num,
          stockAfter: row['stock_after'] as num,
          note: row['note'] as String? ?? '',
          recordedBy: row['recorded_by_label'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      }).toList(),
      canManageCatalog:
          membership['role'] == 'owner' || membership['role'] == 'advisor',
    );
  }

  @override
  Future<void> saveSupplier({
    required String name,
    required String phone,
    required String gstin,
    required String address,
  }) async {
    await client.rpc(
      'save_inventory_supplier',
      params: {
        'p_name': name.trim(),
        'p_phone': phone.trim(),
        'p_gstin': gstin.trim().isEmpty ? null : gstin.trim().toUpperCase(),
        'p_address': address.trim(),
      },
    );
  }

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
  }) async {
    await client.rpc(
      'save_inventory_part',
      params: {
        'p_sku': sku.trim().toUpperCase(),
        'p_name': name.trim(),
        'p_category': category.trim(),
        'p_unit': unit,
        'p_gst_rate_percent': gstRatePercent,
        'p_unit_cost_paise': unitCostPaise,
        'p_unit_price_paise': unitPricePaise,
        'p_reorder_quantity': reorderQuantity,
      },
    );
  }

  @override
  Future<void> recordMovement({
    required String partId,
    required String type,
    required num quantity,
    String? supplierId,
    String? jobCardId,
    required String note,
  }) async {
    await client.rpc(
      'record_inventory_movement',
      params: {
        'p_part_id': partId,
        'p_movement_type': type,
        'p_quantity': quantity,
        'p_supplier_id': supplierId,
        'p_job_card_id': jobCardId,
        'p_note': note.trim(),
      },
    );
  }
}

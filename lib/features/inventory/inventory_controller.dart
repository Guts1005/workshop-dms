import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'inventory_models.dart';
import 'inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return SupabaseInventoryRepository(Supabase.instance.client);
});

final inventoryControllerProvider =
    StateNotifierProvider.autoDispose<InventoryController, InventoryState>(
      (ref) => InventoryController(
        repository: ref.watch(inventoryRepositoryProvider),
      ),
    );

class InventoryState {
  const InventoryState({
    this.snapshot,
    this.loading = false,
    this.saving = false,
    this.error,
    this.notice,
  });
  final InventorySnapshot? snapshot;
  final bool loading;
  final bool saving;
  final String? error;
  final String? notice;

  InventoryState copyWith({
    InventorySnapshot? snapshot,
    bool? loading,
    bool? saving,
    String? error,
    String? notice,
    bool clearError = false,
    bool clearNotice = false,
  }) => InventoryState(
    snapshot: snapshot ?? this.snapshot,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    error: clearError ? null : (error ?? this.error),
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

class InventoryController extends StateNotifier<InventoryState> {
  InventoryController({required this.repository})
    : super(const InventoryState());
  final InventoryRepository repository;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(
        snapshot: await repository.load(),
        loading: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Could not load inventory. Check your connection and retry.',
      );
    }
  }

  Future<bool> _save(Future<void> Function() operation, String success) async {
    state = state.copyWith(saving: true, clearError: true, clearNotice: true);
    try {
      await operation();
      await load();
      state = state.copyWith(saving: false, notice: success);
      return true;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        error: 'Inventory change was not saved. Your entries are still available; retry when connected.',
      );
      return false;
    }
  }

  Future<bool> saveSupplier({
    required String name,
    required String phone,
    required String gstin,
    required String address,
  }) {
    if (name.trim().length < 2) return _invalid('Enter a supplier name.');
    return _save(
      () => repository.saveSupplier(
        name: name,
        phone: phone,
        gstin: gstin,
        address: address,
      ),
      'Supplier added.',
    );
  }

  Future<bool> savePart({
    required String sku,
    required String name,
    required String category,
    required String unit,
    required String gstRate,
    required String cost,
    required String price,
    required String reorderQuantity,
  }) {
    final gst = num.tryParse(gstRate.trim());
    final costPaise = _parsePaise(cost);
    final pricePaise = _parsePaise(price);
    final reorder = num.tryParse(reorderQuantity.trim());
    if (sku.trim().isEmpty || name.trim().length < 2) {
      return _invalid('Enter a part code and name.');
    }
    if (gst == null || !gst.isFinite || gst < 0 || gst > 100) {
      return _invalid('Enter a GST rate between 0 and 100.');
    }
    if (costPaise == null ||
        pricePaise == null ||
        reorder == null ||
        !reorder.isFinite ||
        reorder < 0) {
      return _invalid('Check the cost, price, and low-stock quantity.');
    }
    return _save(
      () => repository.savePart(
        sku: sku,
        name: name,
        category: category,
        unit: unit,
        gstRatePercent: gst,
        unitCostPaise: costPaise,
        unitPricePaise: pricePaise,
        reorderQuantity: reorder,
      ),
      'Part added to inventory.',
    );
  }

  Future<bool> recordMovement({
    required String partId,
    required String type,
    required String quantityText,
    String? supplierId,
    required String note,
  }) {
    final quantity = num.tryParse(quantityText.trim());
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      return _invalid('Enter a valid quantity greater than zero.');
    }
    if (type == 'RECEIPT' && supplierId == null) {
      return _invalid('Select the supplier for this receipt.');
    }
    if (type == 'ADJUSTMENT' &&
        (note.trim().length < 5 ||
            !RegExp(r'^[+-]\s*\S').hasMatch(note.trim()))) {
      return _invalid(
        'Start the adjustment reason with + or - and explain the count change.',
      );
    }
    return _save(
      () => repository.recordMovement(
        partId: partId,
        type: type,
        quantity: quantity,
        supplierId: supplierId,
        note: note,
      ),
      'Stock updated.',
    );
  }

  Future<bool> _invalid(String message) async {
    state = state.copyWith(error: message, clearNotice: true);
    return false;
  }

  int? _parsePaise(String value) {
    final raw = value.trim();
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(raw)) return null;
    final segments = raw.split('.');
    final rupees = int.tryParse(segments.first);
    final paise = int.tryParse(
      segments.length == 1 ? '00' : segments[1].padRight(2, '0'),
    );
    if (rupees == null || paise == null) return null;
    return rupees * 100 + paise;
  }
}

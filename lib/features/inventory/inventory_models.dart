class InventoryPart {
  const InventoryPart({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.gstRatePercent,
    required this.unitCostPaise,
    required this.unitPricePaise,
    required this.reorderQuantity,
    required this.onHandQuantity,
  });

  final String id;
  final String sku;
  final String name;
  final String category;
  final String unit;
  final num gstRatePercent;
  final int unitCostPaise;
  final int unitPricePaise;
  final num reorderQuantity;
  final num onHandQuantity;

  bool get lowStock => onHandQuantity <= reorderQuantity;
}

class InventorySupplier {
  const InventorySupplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.gstin,
  });

  final String id;
  final String name;
  final String phone;
  final String? gstin;
}

class InventoryMovement {
  const InventoryMovement({
    required this.partName,
    required this.sku,
    required this.type,
    required this.quantityDelta,
    required this.stockAfter,
    required this.note,
    required this.recordedBy,
    required this.createdAt,
  });

  final String partName;
  final String sku;
  final String type;
  final num quantityDelta;
  final num stockAfter;
  final String note;
  final String recordedBy;
  final DateTime createdAt;
}

class InventorySnapshot {
  const InventorySnapshot({
    required this.parts,
    required this.suppliers,
    required this.movements,
    required this.canManageCatalog,
  });

  final List<InventoryPart> parts;
  final List<InventorySupplier> suppliers;
  final List<InventoryMovement> movements;
  final bool canManageCatalog;
}

String formatInventoryRupees(int paise) =>
    '₹${(paise / 100).toStringAsFixed(2)}';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'inventory_controller.dart';
import 'inventory_models.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryControllerProvider);
    final controller = ref.read(inventoryControllerProvider.notifier);
    final snapshot = state.snapshot;
    return Scaffold(
      backgroundColor: AppTokens.base,
      appBar: AppBar(
        backgroundColor: AppTokens.base,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        title: const Text('Parts & inventory'),
        leading: IconButton(
          tooltip: 'Back to home',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh inventory',
            onPressed: state.loading ? null : controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.loading && snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : snapshot == null
          ? _loadError(state.error, controller.load)
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                  children: [
                    _summary(snapshot),
                    if (state.error != null) ...[
                      const SizedBox(height: 10),
                      _message(state.error!, error: true),
                    ],
                    if (state.notice != null) ...[
                      const SizedBox(height: 10),
                      _message(state.notice!, error: false),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _heading('PARTS CATALOG')),
                        if (snapshot.canManageCatalog)
                          PopupMenuButton<String>(
                            tooltip: 'Manage inventory',
                            onSelected: (value) {
                              if (value == 'part') _addPart(controller);
                              if (value == 'supplier') _addSupplier(controller);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'part',
                                child: Text('Add a part'),
                              ),
                              PopupMenuItem(
                                value: 'supplier',
                                child: Text('Add a supplier'),
                              ),
                            ],
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: const BoxDecoration(
                                color: AppTokens.inverse,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: AppTokens.textOnDark,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'ADD',
                                    style: TextStyle(
                                      color: AppTokens.textOnDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.parts.isEmpty)
                      _empty(
                        'No parts in the catalog yet. Add the parts your workshop uses.',
                      )
                    else
                      for (final part in snapshot.parts)
                        _partCard(part, snapshot, controller, state.saving),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _heading('RECENT STOCK ACTIVITY')),
                        if (snapshot.canManageCatalog &&
                            snapshot.parts.isNotEmpty)
                          TextButton.icon(
                            onPressed: state.saving
                                ? null
                                : () => _recordMovement(snapshot, controller),
                            icon: const Icon(Icons.swap_vert),
                            label: const Text('Receive / adjust'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.movements.isEmpty)
                      _empty(
                        'Stock changes will appear here with who recorded them.',
                      )
                    else
                      for (final movement in snapshot.movements)
                        _movementCard(movement),
                    if (snapshot.canManageCatalog) ...[
                      const SizedBox(height: 16),
                      _heading('SUPPLIERS (${snapshot.suppliers.length})'),
                      const SizedBox(height: 8),
                      if (snapshot.suppliers.isEmpty)
                        _empty(
                          'Add suppliers to record who supplied received stock.',
                        )
                      else
                        for (final supplier in snapshot.suppliers)
                          _supplierCard(supplier),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summary(InventorySnapshot snapshot) {
    final lowCount = snapshot.parts.where((part) => part.lowStock).length;
    return _card(
      Row(
        children: [
          Expanded(child: _metric('${snapshot.parts.length}', 'PARTS')),
          Expanded(child: _metric('${snapshot.suppliers.length}', 'SUPPLIERS')),
          Expanded(
            child: _metric('$lowCount', 'LOW STOCK', alert: lowCount > 0),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label, {bool alert = false}) => Column(
    children: [
      Text(
        value,
        style: AppTokens.fontMonospace(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: alert ? AppTokens.brandRed : AppTokens.textPrimary,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: AppTokens.fontMonospace(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTokens.textSecondary,
        ),
      ),
    ],
  );

  Widget _partCard(
    InventoryPart part,
    InventorySnapshot snapshot,
    InventoryController controller,
    bool saving,
  ) => _card(
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          part.lowStock
              ? Icons.warning_amber_rounded
              : Icons.inventory_2_outlined,
          color: part.lowStock ? AppTokens.brandRed : AppTokens.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.name,
                style: AppTokens.fontBody(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${part.sku}  ·  ${part.category.isEmpty ? part.unit : '${part.category} · ${part.unit}'}',
                style: AppTokens.fontBody(color: AppTokens.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  Text(
                    'Stock: ${_quantity(part.onHandQuantity)} ${part.unit}',
                    style: AppTokens.fontMonospace(
                      fontWeight: FontWeight.w700,
                      color: part.lowStock
                          ? AppTokens.brandRed
                          : AppTokens.textPrimary,
                    ),
                  ),
                  Text(
                    'Low at ${_quantity(part.reorderQuantity)}',
                    style: AppTokens.fontBody(
                      fontSize: 12,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  Text(
                    'Sell ${formatInventoryRupees(part.unitPricePaise)}',
                    style: AppTokens.fontBody(
                      fontSize: 12,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (snapshot.canManageCatalog)
          IconButton(
            tooltip: 'Receive or adjust stock for ${part.name}',
            onPressed: saving
                ? null
                : () =>
                      _recordMovement(snapshot, controller, initialPart: part),
            icon: const Icon(Icons.add_box_outlined),
          ),
      ],
    ),
  );

  Widget _movementCard(InventoryMovement movement) {
    final positive = movement.quantityDelta > 0;
    final sign = positive ? '+' : '';
    final local = movement.createdAt.toLocal();
    return _card(
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          positive ? Icons.south_west : Icons.north_east,
          color: positive ? AppTokens.green : AppTokens.brandRed,
        ),
        title: Text(
          '${movement.type} - ${movement.partName}',
          style: AppTokens.fontBody(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$sign${_quantity(movement.quantityDelta)}  ->  ${_quantity(movement.stockAfter)} on hand  |  ${movement.recordedBy}${movement.note.isEmpty ? '' : '\n${movement.note}'}\n${local.day}/${local.month}/${local.year}',
        ),
        isThreeLine: movement.note.isNotEmpty,
      ),
    );
  }

  Widget _supplierCard(InventorySupplier supplier) => _card(
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.storefront_outlined),
      title: Text(
        supplier.name,
        style: AppTokens.fontBody(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          if (supplier.phone.isNotEmpty) supplier.phone,
          if (supplier.gstin != null) 'GSTIN ${supplier.gstin}',
        ].join(' · '),
      ),
    ),
  );

  Future<void> _addPart(InventoryController controller) async {
    final form = _FormValues([
      _Field('Part code / SKU'),
      _Field('Part name'),
      _Field('Category (optional)'),
      _Field('GST rate %', initial: '0'),
      _Field('Unit cost ₹', initial: '0'),
      _Field('Selling price ₹', initial: '0'),
      _Field('Low stock alert quantity', initial: '0'),
    ]);
    String unit = 'piece';
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add part'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < form.fields.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: form.fields[i].controller,
                      keyboardType: i >= 3
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: form.fields[i].label,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      const [
                            'piece',
                            'set',
                            'litre',
                            'ml',
                            'kg',
                            'gram',
                            'metre',
                            'pack',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setDialogState(() => unit = value ?? unit),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, [...form.values, unit]),
              child: const Text('Save part'),
            ),
          ],
        ),
      ),
    );
    if (values != null && mounted) {
      await controller.savePart(
        sku: values[0],
        name: values[1],
        category: values[2],
        gstRate: values[3],
        cost: values[4],
        price: values[5],
        reorderQuantity: values[6],
        unit: values[7],
      );
    }
    form.dispose();
  }

  Future<void> _addSupplier(InventoryController controller) async {
    final form = _FormValues([
      _Field('Supplier name'),
      _Field('Phone (optional)'),
      _Field('GSTIN (optional)'),
      _Field('Address (optional)'),
    ]);
    final values = await _formDialog('Add supplier', 'Save supplier', form);
    if (values != null && mounted) {
      await controller.saveSupplier(
        name: values[0],
        phone: values[1],
        gstin: values[2],
        address: values[3],
      );
    }
    form.dispose();
  }

  Future<void> _recordMovement(
    InventorySnapshot snapshot,
    InventoryController controller, {
    InventoryPart? initialPart,
  }) async {
    final parts = snapshot.parts;
    final suppliers = snapshot.suppliers;
    if (parts.isEmpty) return;
    String partId = initialPart?.id ?? parts.first.id;
    String type = 'RECEIPT';
    String? supplierId = suppliers.isEmpty ? null : suppliers.first.id;
    String direction = '+';
    final quantity = TextEditingController();
    final note = TextEditingController();
    final result = await showDialog<List<String?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update stock'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: partId,
                  decoration: const InputDecoration(
                    labelText: 'Part',
                    border: OutlineInputBorder(),
                  ),
                  items: parts
                      .map(
                        (part) => DropdownMenuItem(
                          value: part.id,
                          child: Text(
                            '${part.sku} · ${part.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => partId = value ?? partId),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Movement',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'RECEIPT',
                      child: Text('Receive from supplier'),
                    ),
                    DropdownMenuItem(
                      value: 'ADJUSTMENT',
                      child: Text('Stock count adjustment'),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() {
                    type = value ?? type;
                  }),
                ),
                if (type == 'RECEIPT') ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: supplierId,
                    decoration: const InputDecoration(
                      labelText: 'Supplier',
                      border: OutlineInputBorder(),
                    ),
                    items: suppliers
                        .map(
                          (supplier) => DropdownMenuItem(
                            value: supplier.id,
                            child: Text(supplier.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => supplierId = value),
                  ),
                ],
                if (type == 'ADJUSTMENT') ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: direction,
                    decoration: const InputDecoration(
                      labelText: 'Count change',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '+',
                        child: Text('Increase stock'),
                      ),
                      DropdownMenuItem(
                        value: '-',
                        child: Text('Decrease stock'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => direction = value ?? direction),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (type == 'ADJUSTMENT') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    minLines: 2,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Reason for count change',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, [
                partId,
                type,
                quantity.text,
                supplierId,
                type == 'ADJUSTMENT' ? '$direction ${note.text.trim()}' : '',
              ]),
              child: const Text('Save movement'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      await controller.recordMovement(
        partId: result[0]!,
        type: result[1]!,
        quantityText: result[2]!,
        supplierId: result[3],
        note: result[4] ?? '',
      );
    }
    quantity.dispose();
    note.dispose();
  }

  Future<List<String>?> _formDialog(
    String title,
    String submit,
    _FormValues form,
  ) => showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in form.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: field.controller,
                  decoration: InputDecoration(
                    labelText: field.label,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, form.values),
          child: Text(submit),
        ),
      ],
    ),
  );

  Widget _heading(String text) => Text(
    text,
    style: AppTokens.fontMonospace(fontSize: 12, fontWeight: FontWeight.w800),
  );
  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTokens.raised,
      border: Border.all(color: AppTokens.borderLight),
    ),
    child: child,
  );
  Widget _empty(String text) => _card(
    Text(text, style: AppTokens.fontBody(color: AppTokens.textSecondary)),
  );
  Widget _message(String text, {required bool error}) => _card(
    Row(
      children: [
        Icon(
          error ? Icons.error_outline : Icons.check_circle_outline,
          color: error ? AppTokens.brandRed : AppTokens.green,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
  Widget _loadError(String? text, VoidCallback retry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(text ?? 'Could not load inventory.'),
        ),
        OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
  String _quantity(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

class _Field {
  _Field(this.label, {String initial = ''})
    : controller = TextEditingController(text: initial);
  final String label;
  final TextEditingController controller;
}

class _FormValues {
  _FormValues(this.fields);
  final List<_Field> fields;
  List<String> get values =>
      fields.map((field) => field.controller.text).toList();
  void dispose() {
    for (final field in fields) {
      field.controller.dispose();
    }
  }
}

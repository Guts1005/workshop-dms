import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase/workshop_database.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key, this.initialPlate});

  final String? initialPlate;

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  static const _ink = Color(0xFF182421);
  static const _muted = Color(0xFF66736F);
  static const _green = Color(0xFF17745B);
  static const _line = Color(0xFFE2E9E5);

  final _search = TextEditingController();
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.text = widget.initialPlate ?? '';
    _loadVehicles();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await WorkshopDatabase(Supabase.instance.client).vehicles();
      if (mounted) setState(() => _vehicles = rows);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Vehicle records could not be loaded. Check the connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final vehicles = _vehicles
        .where(
          (row) =>
              (row['plate'] as String).toLowerCase().contains(query) ||
              (row['model'] as String).toLowerCase().contains(query) ||
              (row['customerName'] as String).toLowerCase().contains(query),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F4),
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Vehicles',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadVehicles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by plate, model, or customer',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _line),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _errorState()
                    : vehicles.isEmpty
                    ? _emptyState(query.isNotEmpty)
                    : RefreshIndicator(
                        onRefresh: _loadVehicles,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                          itemCount: vehicles.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _vehicleCard(vehicles[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleCard(Map<String, dynamic> vehicle) {
    final history = vehicle['history'] as List<dynamic>;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _showDetails(vehicle),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3EF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.directions_car_outlined, color: _green),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle['plate'] as String,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vehicle['model'] as String,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                    if ((vehicle['customerName'] as String).isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        vehicle['customerName'] as String,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${vehicle['odometer']} km',
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${history.length} ${history.length == 1 ? 'application' : 'applications'}',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> vehicle) {
    final history = vehicle['history'] as List<dynamic>;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicle['plate'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: _ink,
                  ),
                ),
                Text(
                  vehicle['model'] as String,
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 16),
                _detail('Make', vehicle['make'] as String),
                _detail('Body type', vehicle['bodyType'] as String),
                _detail('Odometer', '${vehicle['odometer']} km'),
                if (vehicle['vin'] != null)
                  _detail('VIN', vehicle['vin'] as String),
                if ((vehicle['customerName'] as String).isNotEmpty)
                  _detail('Latest customer', vehicle['customerName'] as String),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    this.context.push(
                      '/passport',
                      extra: {
                        'registrationNumber': vehicle['plate'],
                        'model': vehicle['model'],
                      },
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Open service record'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Applications',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const Text(
                    'No applications recorded yet.',
                    style: TextStyle(color: _muted),
                  ),
                for (final job in history)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.assignment_outlined,
                      color: _green,
                    ),
                    title: Text(
                      (job['requested_work'] as String?) ?? 'Application',
                    ),
                    subtitle: Text(
                      '${job['created_at']} · ${(job['intake_odometer_km'] as int?) ?? 0} km',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      this.context.go(
                        '/applications',
                        extra: {'registrationNumber': vehicle['plate']},
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: _muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState(bool searching) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car_outlined, size: 42, color: _muted),
          const SizedBox(height: 12),
          Text(
            searching ? 'No matching vehicles' : 'No vehicles yet',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try another registration or customer.'
                : 'Vehicles are added when you create an application.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
          if (!searching) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.push('/intake'),
              icon: const Icon(Icons.add),
              label: const Text('Create application'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: _muted),
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loadVehicles,
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ui_kit/tokens/app_tokens.dart';

class DigitalPassportScreen extends StatefulWidget {
  final String? registrationNumber;
  final String? model;

  const DigitalPassportScreen({super.key, this.registrationNumber, this.model});

  @override
  State<DigitalPassportScreen> createState() => _DigitalPassportScreenState();
}

class _DigitalPassportScreenState extends State<DigitalPassportScreen> {
  late Future<Map<String, dynamic>?> _record;

  @override
  void initState() {
    super.initState();
    _record = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final plate = widget.registrationNumber?.toUpperCase().replaceAll(
      RegExp(r'[\s-]'),
      '',
    );
    if (plate == null || plate.isEmpty) return null;
    final client = Supabase.instance.client;
    final vehicle = await client
        .from('vehicles')
        .select('id, registration_number, make, model, body_type, odometer_km')
        .eq('registration_number', plate)
        .maybeSingle();
    if (vehicle == null) return null;
    final history = await client
        .from('job_cards')
        .select('id, created_at, requested_work, status, intake_odometer_km')
        .eq('vehicle_id', vehicle['id'])
        .order('created_at', ascending: false);
    return {'vehicle': vehicle, 'history': history};
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTokens.base,
    appBar: AppBar(
      title: const Text('Vehicle service record'),
      leading: IconButton(
        onPressed: () => context.go('/vehicles'),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: FutureBuilder<Map<String, dynamic>?>(
      future: _record,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EmptyRecord(
            message: 'The service record could not load. Check your connection and retry.',
            onRetry: () => setState(() => _record = _load()),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const _EmptyRecord(
            message: 'Choose a saved vehicle to view its service record.',
          );
        }
        final vehicle = data['vehicle'] as Map<String, dynamic>;
        final history = data['history'] as List<dynamic>;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle['registration_number'] as String,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${vehicle['make']} ${vehicle['model']} · ${vehicle['body_type']}',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Last recorded odometer: ${vehicle['odometer_km']} km',
                    ),
                    Text(
                      '${history.length} saved service ${history.length == 1 ? 'record' : 'records'}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Service history',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'No service records have been saved for this vehicle yet.',
                  ),
                ),
              )
            else
              ...history.map((item) {
                final row = item as Map<String, dynamic>;
                final date = DateTime.tryParse(
                  row['created_at'] as String? ?? '',
                )?.toLocal();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      row['requested_work'] as String? ?? 'Service application',
                    ),
                    subtitle: Text(
                      '${date == null ? '' : '${date.day}/${date.month}/${date.year} · '}${row['intake_odometer_km']} km',
                    ),
                    trailing: Text(_status(row['status'] as String? ?? '')),
                  ),
                );
              }),
          ],
        );
      },
    ),
  );

  String _status(String value) => switch (value) {
    'DELIVERED' => 'Completed',
    'CANCELLED' => 'Cancelled',
    'READY_FOR_PICKUP' => 'Ready',
    'WORK_IN_PROGRESS' => 'In progress',
    'WAITING_APPROVAL' || 'ESTIMATE_SENT' => 'Awaiting approval',
    _ => 'Open',
  };
}

class _EmptyRecord extends StatelessWidget {
  const _EmptyRecord({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 44,
            color: AppTokens.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mechanical_inspection/mechanical_inspection_models.dart';
import '../../../ui_kit/tokens/app_tokens.dart';

@visibleForTesting
List<String> formatMechanicalInspectionReadings({
  required Map<String, dynamic> measurements,
  required List<String> notApplicable,
}) => mechanicalMeasurementSpecs.map((spec) {
  final value = measurements[spec.id];
  if (value is num) {
    final displayValue = value == value.toInt()
        ? value.toInt().toString()
        : value.toString();
    return '${spec.label}: $displayValue ${spec.unit}';
  }
  if (notApplicable.contains(spec.id)) {
    return '${spec.label}: Not applicable';
  }
  return '${spec.label}: Not recorded';
}).toList();

String vehicleRecordStatusLabel(String value) => switch (value) {
  'DELIVERED' => 'Completed',
  'CANCELLED' => 'Cancelled',
  'READY_FOR_PICKUP' => 'Ready for pickup',
  'QC_PASSED' => 'Invoice pending',
  'WORK_IN_PROGRESS' => 'In service',
  'ESTIMATE_REVISION_REQUIRED' => 'Estimate update needed',
  'WAITING_APPROVAL' || 'ESTIMATE_SENT' => 'Waiting for approval',
  'INSPECTION_PENDING' => 'Inspection',
  'RECEIVED' => 'Check-in',
  _ => 'Open',
};

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
    final jobIds = history.map((row) => row['id'] as String).toList();
    final inspections = jobIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from('mechanical_inspections')
              .select(
                'job_card_id, inspector_name, odometer_km, measurements, not_applicable, notes, completed_at',
              )
              .inFilter('job_card_id', jobIds)
              .order('completed_at', ascending: false);
    final inspectionByJob = {
      for (final inspection in inspections)
        inspection['job_card_id'] as String: inspection,
    };
    return {
      'vehicle': vehicle,
      'history': history,
      'inspectionByJob': inspectionByJob,
    };
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
        final inspectionByJob = data['inspectionByJob'] as Map<String, dynamic>;
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
                      "${vehicle['make']} ${vehicle['model']} - ${vehicle['body_type']}",
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
              ...history.map<Widget>((item) {
                final row = item as Map<String, dynamic>;
                final date = DateTime.tryParse(
                  row['created_at'] as String? ?? '',
                )?.toLocal();
                final inspection =
                    inspectionByJob[row['id'] as String]
                        as Map<String, dynamic>?;
                final title =
                    row['requested_work'] as String? ?? 'Service application';
                final subtitle =
                    '${date == null ? '' : '${date.day}/${date.month}/${date.year} · '}'
                    '${row['intake_odometer_km']} km · '
                    '${_status(row['status'] as String? ?? '')}';
                if (inspection == null) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(subtitle),
                    ),
                  );
                }
                final completedAt = DateTime.tryParse(
                  inspection['completed_at'] as String? ?? '',
                )?.toLocal();
                final completedLabel = completedAt == null
                    ? ''
                    : '${completedAt.day}/${completedAt.month}/${completedAt.year}';
                final measurements =
                    inspection['measurements'] as Map<String, dynamic>? ?? {};
                final notApplicable =
                    (inspection['not_applicable'] as List<dynamic>? ?? [])
                        .cast<String>();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(title),
                    subtitle: Text(subtitle),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Inspected by ${inspection['inspector_name']} · ${completedLabel.isEmpty ? 'date unavailable' : completedLabel} · ${inspection['odometer_km']} km',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final reading in formatMechanicalInspectionReadings(
                        measurements: measurements,
                        notApplicable: notApplicable,
                      ))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(reading),
                          ),
                        ),
                      if ((inspection['notes'] as String? ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Notes: ${(inspection['notes'] as String).trim()}',
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        );
      },
    ),
  );

  String _status(String value) => vehicleRecordStatusLabel(value);
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

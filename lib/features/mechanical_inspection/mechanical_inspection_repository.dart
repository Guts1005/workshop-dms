import 'package:supabase_flutter/supabase_flutter.dart';

import 'mechanical_inspection_models.dart';

abstract class MechanicalInspectionRepository {
  Future<int> getIntakeOdometer(String jobCardId);
  Future<MechanicalInspectionRecord?> getInspection(String jobCardId);
  Future<void> saveInspection({
    required String jobCardId,
    required MechanicalInspectionRecord inspection,
  });
}

class SupabaseMechanicalInspectionRepository
    implements MechanicalInspectionRepository {
  SupabaseMechanicalInspectionRepository(this.client);

  final SupabaseClient client;

  Future<String> _workshopId() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to continue.');
    final membership = await client
        .from('workshop_memberships')
        .select('workshop_id')
        .eq('user_id', userId)
        .maybeSingle();
    final id = membership?['workshop_id'] as String?;
    if (id == null) throw StateError('No workshop is linked to this account.');
    return id;
  }

  @override
  Future<int> getIntakeOdometer(String jobCardId) async {
    final row = await client
        .from('job_cards')
        .select('intake_odometer_km')
        .eq('id', jobCardId)
        .single();
    return row['intake_odometer_km'] as int;
  }

  @override
  Future<MechanicalInspectionRecord?> getInspection(String jobCardId) async {
    final row = await client
        .from('mechanical_inspections')
        .select(
          'inspector_name, odometer_km, measurements, not_applicable, notes, completed_at',
        )
        .eq('job_card_id', jobCardId)
        .maybeSingle();
    if (row == null) return null;
    final rawMeasurements = row['measurements'] as Map<String, dynamic>;
    final rawNotApplicable = row['not_applicable'] as List<dynamic>;
    return MechanicalInspectionRecord(
      inspectorName: row['inspector_name'] as String,
      odometerKm: row['odometer_km'] as int,
      measurements: rawMeasurements.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      notApplicable: rawNotApplicable.cast<String>().toSet(),
      notes: row['notes'] as String? ?? '',
      completedAt: DateTime.parse(row['completed_at'] as String),
    );
  }

  @override
  Future<void> saveInspection({
    required String jobCardId,
    required MechanicalInspectionRecord inspection,
  }) async {
    await client.from('mechanical_inspections').upsert({
      'workshop_id': await _workshopId(),
      'job_card_id': jobCardId,
      'inspector_name': inspection.inspectorName.trim(),
      'odometer_km': inspection.odometerKm,
      'measurements': inspection.measurements,
      'not_applicable': inspection.notApplicable.toList()..sort(),
      'notes': inspection.notes.trim(),
      'completed_at': inspection.completedAt.toUtc().toIso8601String(),
    }, onConflict: 'job_card_id');
  }
}

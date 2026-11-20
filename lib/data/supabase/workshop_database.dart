import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationNextAction {
  const ApplicationNextAction({required this.route, required this.label});

  final String route;
  final String label;
}

ApplicationNextAction nextApplicationAction({
  required int mandatoryPhotoCount,
  required bool hasManagerOverride,
  required bool hasConditionReport,
  required bool hasMechanicalInspection,
}) {
  if (!hasConditionReport && mandatoryPhotoCount < 6 && !hasManagerOverride) {
    return const ApplicationNextAction(
      route: '/bay-capture',
      label: 'Open photo check-in',
    );
  }
  if (!hasConditionReport) {
    return const ApplicationNextAction(
      route: '/condition-map',
      label: 'Open vehicle condition',
    );
  }
  if (!hasMechanicalInspection) {
    return const ApplicationNextAction(
      route: '/mechanical-inspection',
      label: 'Record mechanical inspection',
    );
  }
  return const ApplicationNextAction(
    route: '/job-card',
    label: 'Open job card and estimate',
  );
}

class WorkshopDatabase {
  WorkshopDatabase(this.client);

  final SupabaseClient client;

  Future<String> currentWorkshopId() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to access workshop records.');
    final membership = await client
        .from('workshop_memberships')
        .select('workshop_id')
        .eq('user_id', userId)
        .maybeSingle();
    final workshopId = membership?['workshop_id'] as String?;
    if (workshopId == null) {
      throw StateError('This account is not linked to a workshop.');
    }
    return workshopId;
  }

  Future<List<Map<String, dynamic>>> applications() async {
    final workshopId = await currentWorkshopId();
    final rows = await client
        .from('job_cards')
        .select(
          'id, status, requested_work, expected_delivery, created_at, assigned_technician, vehicle_id, customer_id, workshop_id, intake_odometer_km',
        )
        .eq('workshop_id', workshopId)
        .order('created_at', ascending: false);
    if (rows.isEmpty) return [];

    final jobIds = rows.map((row) => row['id'] as String).toList();
    final vehicleIds = rows
        .map((row) => row['vehicle_id'] as String)
        .toSet()
        .toList();
    final customerIds = rows
        .map((row) => row['customer_id'] as String)
        .toSet()
        .toList();
    final vehicles = await client
        .from('vehicles')
        .select('id, registration_number, make, model, body_type, odometer_km')
        .eq('workshop_id', workshopId)
        .inFilter('id', vehicleIds);
    final customers = await client
        .from('customers')
        .select('id, name, phone')
        .eq('workshop_id', workshopId)
        .inFilter('id', customerIds);
    final photoRows = await client
        .from('bay_photos')
        .select('job_card_id, shot_type')
        .eq('workshop_id', workshopId)
        .inFilter('job_card_id', jobIds);
    final reportRows = await client
        .from('condition_reports')
        .select('job_card_id, signed_at')
        .eq('workshop_id', workshopId)
        .inFilter('job_card_id', jobIds);

    final vehicleById = {for (final row in vehicles) row['id'] as String: row};
    final customerById = {
      for (final row in customers) row['id'] as String: row,
    };
    const mandatoryShotTypes = {
      'frontLeft45',
      'frontRight45',
      'rearLeft45',
      'rearRight45',
      'plateCloseup',
      'odometerReading',
    };
    final photosByJob = <String, Set<String>>{};
    for (final photo in photoRows) {
      final jobId = photo['job_card_id'] as String;
      photosByJob
          .putIfAbsent(jobId, () => {})
          .add(photo['shot_type'] as String);
    }
    final reportByJob = {
      for (final row in reportRows) row['job_card_id'] as String: row,
    };
    final overrideRows = await client
        .from('manager_overrides')
        .select('job_card_id')
        .eq('workshop_id', workshopId)
        .inFilter('job_card_id', jobIds);
    final overrideJobIds = overrideRows
        .map((row) => row['job_card_id'] as String)
        .toSet();
    final inspectionRows = await client
        .from('mechanical_inspections')
        .select('job_card_id')
        .eq('workshop_id', workshopId)
        .inFilter('job_card_id', jobIds);
    final inspectionJobIds = inspectionRows
        .map((row) => row['job_card_id'] as String)
        .toSet();

    return rows.map((row) {
      final jobId = row['id'] as String;
      final vehicle =
          vehicleById[row['vehicle_id'] as String] ?? const <String, dynamic>{};
      final customer =
          customerById[row['customer_id'] as String] ??
          const <String, dynamic>{};
      final photoCount = (photosByJob[jobId] ?? const <String>{})
          .intersection(mandatoryShotTypes)
          .length;
      final hasReport = reportByJob.containsKey(jobId);
      final hasOverride = overrideJobIds.contains(jobId);
      final hasMechanicalInspection = inspectionJobIds.contains(jobId);
      final action = nextApplicationAction(
        mandatoryPhotoCount: photoCount,
        hasManagerOverride: hasOverride,
        hasConditionReport: hasReport,
        hasMechanicalInspection: hasMechanicalInspection,
      );
      final pending = <String>[];
      final missingPhotos = 6 - photoCount;
      if (missingPhotos > 0) {
        pending.add(
          hasOverride
              ? '$missingPhotos mandatory photos waived by manager override'
              : '$missingPhotos mandatory check-in photos',
        );
      }
      if (!hasReport) {
        pending.add('Vehicle condition report');
      } else if (!hasMechanicalInspection) {
        pending.add('Mechanical inspection');
      } else {
        pending.add('Prepare estimate and request customer approval');
      }
      final status = row['status'] as String? ?? 'RECEIVED';
      return <String, dynamic>{
        'id': jobId,
        'plate': vehicle['registration_number'] ?? '',
        'model': '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'.trim(),
        'customerName': customer['name'] ?? '',
        'customerPhone': customer['phone'] ?? '',
        'serviceType': row['requested_work'] ?? '',
        'status': _displayStatus(status, hasConditionReport: hasReport),
        'statusCode': status,
        'remainingHint': pending.isEmpty
            ? 'No immediate action required'
            : pending.join(' / '),
        'elapsed': _relativeTime(
          DateTime.tryParse(row['created_at'] as String? ?? ''),
        ),
        'technician': row['assigned_technician'] ?? 'Not assigned',
        'bay': 'Not assigned',
        'estimatedCompletion': _displayDate(
          row['expected_delivery'] as String?,
        ),
        'route': action.route,
        'nextActionLabel': action.label,
        'completedItems': <String>[
          'Application created',
          if (photoCount > 0) '$photoCount mandatory check-in photos saved',
          if (hasReport) 'Condition report saved',
          if (hasMechanicalInspection) 'Mechanical inspection saved',
        ],
        'pendingItems': pending,
        'photoCount': photoCount,
        'hasConditionReport': hasReport,
        'hasManagerOverride': hasOverride,
        'hasMechanicalInspection': hasMechanicalInspection,
        'vehicleId': row['vehicle_id'],
        'customerId': row['customer_id'],
        'odometer': row['intake_odometer_km'] ?? vehicle['odometer_km'] ?? 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> vehicles() async {
    final workshopId = await currentWorkshopId();
    final rows = await client
        .from('vehicles')
        .select(
          'id, registration_number, make, model, body_type, odometer_km, fuel_level_percent, vin, created_at',
        )
        .eq('workshop_id', workshopId)
        .order('registration_number');
    if (rows.isEmpty) return [];
    final ids = rows.map((row) => row['id'] as String).toList();
    final jobs = await client
        .from('job_cards')
        .select(
          'id, vehicle_id, customer_id, created_at, requested_work, intake_odometer_km',
        )
        .eq('workshop_id', workshopId)
        .inFilter('vehicle_id', ids)
        .order('created_at', ascending: false);
    final customerIds = jobs
        .map((row) => row['customer_id'] as String)
        .toSet()
        .toList();
    final customers = customerIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from('customers')
              .select('id, name, phone')
              .eq('workshop_id', workshopId)
              .inFilter('id', customerIds);
    final customerById = {
      for (final row in customers) row['id'] as String: row,
    };
    final latestJobByVehicle = <String, Map<String, dynamic>>{};
    for (final job in jobs.reversed) {
      latestJobByVehicle[job['vehicle_id'] as String] = job;
    }
    return rows.map((vehicle) {
      final latestJob = latestJobByVehicle[vehicle['id'] as String];
      final customer = latestJob == null
          ? null
          : customerById[latestJob['customer_id'] as String];
      return <String, dynamic>{
        'id': vehicle['id'],
        'plate': vehicle['registration_number'],
        'make': vehicle['make'],
        'model': vehicle['model'],
        'bodyType': vehicle['body_type'],
        'odometer': vehicle['odometer_km'],
        'fuelLevel': vehicle['fuel_level_percent'],
        'vin': vehicle['vin'],
        'customerName': customer?['name'] ?? '',
        'customerPhone': customer?['phone'] ?? '',
        'lastService': latestJob?['created_at'],
        'lastRequestedWork': latestJob?['requested_work'] ?? '',
        'history': jobs
            .where((job) => job['vehicle_id'] == vehicle['id'])
            .toList(),
      };
    }).toList();
  }

  static String _displayStatus(
    String status, {
    required bool hasConditionReport,
  }) => switch (status) {
    'RECEIVED' => 'Check-in started',
    'INSPECTION_PENDING' =>
      hasConditionReport ? 'Condition report saved' : 'Condition check needed',
    'ESTIMATE_SENT' || 'WAITING_APPROVAL' => 'Waiting for approval',
    'WORK_IN_PROGRESS' => 'Being serviced',
    'READY_FOR_PICKUP' => 'Ready for pickup',
    'DELIVERED' => 'Completed',
    'CANCELLED' => 'Cancelled',
    _ => 'Open',
  };

  static String _relativeTime(DateTime? value) {
    if (value == null) return '';
    final elapsed = DateTime.now().difference(value);
    if (elapsed.inMinutes < 1) return 'Just created';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }

  static String _displayDate(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);
    if (date == null) return 'Not set';
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

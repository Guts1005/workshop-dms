import 'package:supabase_flutter/supabase_flutter.dart';

import 'service_reminder_models.dart';

class ServiceReminderWorkspace {
  const ServiceReminderWorkspace({
    required this.workshopName,
    required this.memberRole,
    required this.settings,
    required this.reminders,
  });

  final String workshopName;
  final String memberRole;
  final ServiceReminderSettings? settings;
  final List<VehicleServiceReminder> reminders;

  bool get canEditSettings => memberRole == 'owner' || memberRole == 'advisor';
}

abstract class ServiceReminderRepository {
  Future<ServiceReminderWorkspace> load({DateTime? now});
  Future<void> saveSettings(ServiceReminderSettings settings);
  Future<bool> hasWhatsAppConsent(String customerId);
}

class SupabaseServiceReminderRepository implements ServiceReminderRepository {
  SupabaseServiceReminderRepository(this.client);

  final SupabaseClient client;

  @override
  Future<ServiceReminderWorkspace> load({DateTime? now}) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Sign in to view service reminders.');

    final membership = await client
        .from('workshop_memberships')
        .select('workshop_id, role')
        .eq('user_id', user.id)
        .single();
    final workshopId = membership['workshop_id'] as String;
    final workshop = await client
        .from('workshops')
        .select('name')
        .eq('id', workshopId)
        .single();
    final settingsRow = await client
        .from('workshop_service_reminder_settings')
        .select('service_interval_km, service_interval_days, due_soon_days')
        .eq('workshop_id', workshopId)
        .maybeSingle();
    final settings = settingsRow == null
        ? null
        : ServiceReminderSettings.fromJson(settingsRow);
    if (settings == null) {
      return ServiceReminderWorkspace(
        workshopName: workshop['name'] as String,
        memberRole: membership['role'] as String,
        settings: null,
        reminders: const [],
      );
    }

    final deliveries = await client
        .from('job_deliveries')
        .select('job_card_id, delivered_at')
        .order('delivered_at', ascending: false)
        .limit(1000);
    if (deliveries.isEmpty) {
      return ServiceReminderWorkspace(
        workshopName: workshop['name'] as String,
        memberRole: membership['role'] as String,
        settings: settings,
        reminders: const [],
      );
    }

    final jobIds = deliveries
        .map((row) => row['job_card_id'] as String)
        .toList();
    final jobs = await client
        .from('job_cards')
        .select('id, vehicle_id, customer_id, intake_odometer_km')
        .inFilter('id', jobIds);
    final jobsById = {for (final job in jobs) job['id'] as String: job};
    final vehicleIds = jobs
        .map((job) => job['vehicle_id'] as String)
        .toSet()
        .toList();
    final customerIds = jobs
        .map((job) => job['customer_id'] as String)
        .toSet()
        .toList();
    if (vehicleIds.isEmpty || customerIds.isEmpty) {
      return ServiceReminderWorkspace(
        workshopName: workshop['name'] as String,
        memberRole: membership['role'] as String,
        settings: settings,
        reminders: const [],
      );
    }

    final vehicles = await client
        .from('vehicles')
        .select('id, registration_number, make, model')
        .inFilter('id', vehicleIds);
    final vehiclesById = {
      for (final vehicle in vehicles) vehicle['id'] as String: vehicle,
    };
    final customers = await client
        .from('customers')
        .select('id, name, phone, consent_whatsapp')
        .inFilter('id', customerIds);
    final customersById = {
      for (final customer in customers) customer['id'] as String: customer,
    };

    final visits = <RecordedServiceVisit>[];
    for (final delivery in deliveries) {
      final job = jobsById[delivery['job_card_id'] as String];
      if (job == null) continue;
      final vehicle = vehiclesById[job['vehicle_id'] as String];
      final customer = customersById[job['customer_id'] as String];
      if (vehicle == null || customer == null) continue;
      visits.add(
        RecordedServiceVisit(
          vehicleId: vehicle['id'] as String,
          customerId: customer['id'] as String,
          registrationNumber: vehicle['registration_number'] as String,
          vehicleModel: '${vehicle['make']} ${vehicle['model']}',
          customerName: customer['name'] as String,
          customerPhone: customer['phone'] as String,
          whatsappConsent: customer['consent_whatsapp'] as bool? ?? false,
          deliveredAt: DateTime.parse(delivery['delivered_at'] as String),
          intakeOdometerKm: (job['intake_odometer_km'] as num).toInt(),
        ),
      );
    }

    return ServiceReminderWorkspace(
      workshopName: workshop['name'] as String,
      memberRole: membership['role'] as String,
      settings: settings,
      reminders: evaluateVehicleServiceReminders(
        visits: visits,
        settings: settings,
        now: now,
      ),
    );
  }

  @override
  Future<void> saveSettings(ServiceReminderSettings settings) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Sign in to change service reminders.');
    final membership = await client
        .from('workshop_memberships')
        .select('workshop_id, role')
        .eq('user_id', user.id)
        .single();
    if (!const {'owner', 'advisor'}.contains(membership['role'])) {
      throw StateError(
        'Only an owner or advisor can change reminder intervals.',
      );
    }
    await client.from('workshop_service_reminder_settings').upsert({
      'workshop_id': membership['workshop_id'],
      ...settings.toJson(),
      'updated_by': user.id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'workshop_id');
  }

  @override
  Future<bool> hasWhatsAppConsent(String customerId) async {
    final customer = await client
        .from('customers')
        .select('consent_whatsapp')
        .eq('id', customerId)
        .maybeSingle();
    return customer?['consent_whatsapp'] as bool? ?? false;
  }
}

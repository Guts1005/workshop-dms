import 'service_reminder_engine.dart';

class ServiceReminderSettings {
  const ServiceReminderSettings({
    required this.intervalKm,
    required this.intervalDays,
    this.dueSoonDays = 14,
  });

  final int intervalKm;
  final int intervalDays;
  final int dueSoonDays;

  factory ServiceReminderSettings.fromJson(Map<String, dynamic> json) =>
      ServiceReminderSettings(
        intervalKm: (json['service_interval_km'] as num).toInt(),
        intervalDays: (json['service_interval_days'] as num).toInt(),
        dueSoonDays: (json['due_soon_days'] as num?)?.toInt() ?? 14,
      );

  Map<String, dynamic> toJson() => {
    'service_interval_km': intervalKm,
    'service_interval_days': intervalDays,
    'due_soon_days': dueSoonDays,
  };
}

class RecordedServiceVisit {
  const RecordedServiceVisit({
    required this.vehicleId,
    required this.customerId,
    required this.registrationNumber,
    required this.vehicleModel,
    required this.customerName,
    required this.customerPhone,
    required this.whatsappConsent,
    required this.deliveredAt,
    required this.intakeOdometerKm,
  });

  final String vehicleId;
  final String customerId;
  final String registrationNumber;
  final String vehicleModel;
  final String customerName;
  final String customerPhone;
  final bool whatsappConsent;
  final DateTime deliveredAt;
  final int intakeOdometerKm;
}

class VehicleServiceReminder {
  const VehicleServiceReminder({
    required this.vehicleId,
    required this.customerId,
    required this.whatsappConsent,
    required this.result,
    required this.previousVisitCount,
  });

  final String vehicleId;
  final String customerId;
  final bool whatsappConsent;
  final ServiceReminderResult result;
  final int previousVisitCount;
}

List<VehicleServiceReminder> evaluateVehicleServiceReminders({
  required Iterable<RecordedServiceVisit> visits,
  required ServiceReminderSettings settings,
  DateTime? now,
}) {
  final grouped = <String, List<RecordedServiceVisit>>{};
  for (final visit in visits) {
    grouped.putIfAbsent(visit.vehicleId, () => []).add(visit);
  }

  final reminders = <VehicleServiceReminder>[];
  for (final entry in grouped.entries) {
    final history = entry.value
      ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    final latest = history.first;
    final previous = history.length > 1 ? history[1] : null;
    final result = ServiceReminderEngine.evaluate(
      customerName: latest.customerName,
      mobileNumber: latest.customerPhone,
      vehicleModel: latest.vehicleModel,
      registrationNumber: latest.registrationNumber,
      lastServiceDate: latest.deliveredAt,
      lastServiceOdometerKm: latest.intakeOdometerKm,
      previousServiceDate: previous?.deliveredAt,
      previousServiceOdometerKm: previous?.intakeOdometerKm,
      intervalKm: settings.intervalKm,
      intervalDays: settings.intervalDays,
      dueSoonDays: settings.dueSoonDays,
      now: now,
    );
    reminders.add(
      VehicleServiceReminder(
        vehicleId: entry.key,
        customerId: latest.customerId,
        whatsappConsent: latest.whatsappConsent,
        result: result,
        previousVisitCount: history.length,
      ),
    );
  }

  reminders.sort((a, b) {
    if (a.result.isOverdue != b.result.isOverdue) {
      return a.result.isOverdue ? -1 : 1;
    }
    return a.result.nextDueDate.compareTo(b.result.nextDueDate);
  });
  return reminders;
}

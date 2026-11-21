import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/reminders/service_reminder_models.dart';

void main() {
  test('evaluates only the latest two completed visits per vehicle', () {
    final reminders = evaluateVehicleServiceReminders(
      visits: [
        _visit(
          vehicleId: 'car-1',
          customerName: 'Previous owner',
          date: DateTime(2025, 12, 2),
          odometer: 19000,
          consent: true,
        ),
        _visit(
          vehicleId: 'car-2',
          customerName: 'Mina',
          date: DateTime(2026, 2, 1),
          odometer: 5000,
          consent: true,
        ),
        _visit(
          vehicleId: 'car-1',
          customerName: 'Asha',
          date: DateTime(2026, 1, 1),
          odometer: 20000,
          consent: false,
        ),
      ],
      settings: const ServiceReminderSettings(
        intervalKm: 1000,
        intervalDays: 180,
      ),
      now: DateTime(2026, 2, 15),
    );

    expect(reminders.map((item) => item.vehicleId), ['car-1', 'car-2']);
    expect(reminders.first.result.customerName, 'Asha');
    expect(reminders.first.result.mobileNumber, '9876543210');
    expect(reminders.first.previousVisitCount, 2);
    expect(reminders.first.result.hasMileageProjection, isTrue);
    expect(reminders.first.result.isOverdue, isTrue);
    expect(reminders.first.whatsappConsent, isFalse);
    expect(reminders.last.result.hasMileageProjection, isFalse);
  });

  test('a configured interval round-trips through the database row shape', () {
    final settings = ServiceReminderSettings.fromJson({
      'service_interval_km': 12000,
      'service_interval_days': 365,
      'due_soon_days': 21,
    });

    expect(settings.intervalKm, 12000);
    expect(settings.intervalDays, 365);
    expect(settings.dueSoonDays, 21);
    expect(settings.toJson(), {
      'service_interval_km': 12000,
      'service_interval_days': 365,
      'due_soon_days': 21,
    });
  });
}

RecordedServiceVisit _visit({
  required String vehicleId,
  required String customerName,
  required DateTime date,
  required int odometer,
  required bool consent,
}) => RecordedServiceVisit(
  vehicleId: vehicleId,
  customerId: 'customer-$vehicleId',
  registrationNumber: 'KA 01 AB 1234',
  vehicleModel: 'Example Hatchback',
  customerName: customerName,
  customerPhone: '9876543210',
  whatsappConsent: consent,
  deliveredAt: date,
  intakeOdometerKm: odometer,
);

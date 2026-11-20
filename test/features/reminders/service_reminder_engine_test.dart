import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/reminders/service_reminder_engine.dart';

void main() {
  final lastService = DateTime(2026, 1, 1);

  ServiceReminderResult evaluate({
    DateTime? previousServiceDate,
    int? previousServiceOdometerKm,
    int intervalKm = 10000,
    int intervalDays = 180,
    DateTime? now,
  }) => ServiceReminderEngine.evaluate(
    customerName: 'Asha',
    mobileNumber: '+91 98765 43210',
    vehicleModel: 'Example Hatchback',
    registrationNumber: 'KA 01 AB 1234',
    lastServiceDate: lastService,
    lastServiceOdometerKm: 20000,
    previousServiceDate: previousServiceDate,
    previousServiceOdometerKm: previousServiceOdometerKm,
    intervalKm: intervalKm,
    intervalDays: intervalDays,
    now: now ?? DateTime(2026, 2, 1),
  );

  test('does not invent a mileage forecast without two recorded visits', () {
    final result = evaluate();

    expect(result.hasMileageProjection, isFalse);
    expect(result.projectedCurrentKm, isNull);
    expect(result.projectedKmDueDate, isNull);
    expect(result.triggerReason, '180 day calendar interval');
  });

  test('uses a valid odometer trend and chooses the earlier due date', () {
    final result = evaluate(
      previousServiceDate: DateTime(2025, 12, 2),
      previousServiceOdometerKm: 19000,
      intervalKm: 1000,
      intervalDays: 180,
      now: DateTime(2026, 1, 20),
    );

    expect(result.hasMileageProjection, isTrue);
    expect(result.projectedCurrentKm, 20633);
    expect(result.projectedKmDueDate, DateTime(2026, 1, 31));
    expect(
      result.triggerReason,
      '1000 km mileage interval (based on recorded readings)',
    );
  });

  test('ignores invalid or reversed odometer history', () {
    final result = evaluate(
      previousServiceDate: DateTime(2025, 12, 2),
      previousServiceOdometerKm: 21000,
    );

    expect(result.hasMileageProjection, isFalse);
    expect(result.projectedCurrentKm, isNull);
  });

  test(
    'WhatsApp reminder contains no invented work or placeholder passport link',
    () {
      final result = evaluate();
      final url = Uri.parse(
        result.buildWhatsAppUrl(
          workshopName: 'Northside Garage',
          workshopPhone: '080 1234 5678',
          workshopAddress: 'Bengaluru',
        ),
      );
      final message = url.queryParameters['text']!;

      expect(url.host, 'wa.me');
      expect(url.path, '/919876543210');
      expect(message, contains('Last recorded service: 1 Jan 2026'));
      expect(message, isNot(contains('Engine Oil')));
      expect(message, isNot(contains('360')));
      expect(message, isNot(contains('workshop.app/passport')));
      expect(message, isNot(contains('Estimated current odometer')));
    },
  );

  test('rejects invalid service intervals and negative odometer readings', () {
    expect(() => evaluate(intervalKm: 0), throwsArgumentError);
    expect(
      () => ServiceReminderEngine.evaluate(
        customerName: 'Asha',
        mobileNumber: '9876543210',
        vehicleModel: 'Example Hatchback',
        registrationNumber: 'KA 01 AB 1234',
        lastServiceDate: lastService,
        lastServiceOdometerKm: -1,
        intervalKm: 10000,
        intervalDays: 180,
      ),
      throwsArgumentError,
    );
  });
}

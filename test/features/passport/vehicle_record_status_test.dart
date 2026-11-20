import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/passport/presentation/digital_passport_screen.dart';

void main() {
  test(
    'service history shows measured and not-applicable inspection values',
    () {
      final readings = formatMechanicalInspectionReadings(
        measurements: {'front_brake_pad_mm': 6.5, 'minimum_tyre_tread_mm': 4},
        notApplicable: [
          'rear_brake_pad_mm',
          'battery_voltage_v',
          'battery_cca',
        ],
      );

      expect(readings, hasLength(5));
      expect(readings, contains('Front brake pad thickness: 6.5 mm'));
      expect(readings, contains('Minimum tyre tread depth: 4 mm'));
      expect(readings, contains('Rear brake pad thickness: Not applicable'));
      expect(readings, contains('Battery measured CCA: Not applicable'));
    },
  );

  test('service history handles an incomplete or older inspection safely', () {
    final readings = formatMechanicalInspectionReadings(
      measurements: {'battery_voltage_v': 12.6},
      notApplicable: [],
    );

    expect(readings, contains('Front brake pad thickness: Not recorded'));
    expect(readings, contains('Battery resting voltage: 12.6 V'));
  });

  test('service history labels customer estimate decisions', () {
    expect(estimateDecisionLabel('APPROVED'), 'Approved');
    expect(estimateDecisionLabel('DECLINED'), 'Declined');
    expect(estimateDecisionLabel('REVISION_REQUESTED'), 'Changes requested');
    expect(estimateDecisionLabel('unexpected'), 'Unknown decision');
  });

  test('service record labels cover the current job lifecycle', () {
    expect(vehicleRecordStatusLabel('RECEIVED'), 'Check-in');
    expect(vehicleRecordStatusLabel('INSPECTION_PENDING'), 'Inspection');
    expect(vehicleRecordStatusLabel('ESTIMATE_SENT'), 'Waiting for approval');
    expect(
      vehicleRecordStatusLabel('ESTIMATE_REVISION_REQUIRED'),
      'Estimate update needed',
    );
    expect(vehicleRecordStatusLabel('WORK_IN_PROGRESS'), 'In service');
    expect(vehicleRecordStatusLabel('QC_PASSED'), 'Invoice pending');
    expect(vehicleRecordStatusLabel('READY_FOR_PICKUP'), 'Ready for pickup');
    expect(vehicleRecordStatusLabel('DELIVERED'), 'Completed');
    expect(vehicleRecordStatusLabel('CANCELLED'), 'Cancelled');
  });
}

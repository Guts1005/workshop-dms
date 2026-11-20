import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/passport/presentation/digital_passport_screen.dart';

void main() {
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

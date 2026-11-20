import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/job_card/estimate_status.dart';

void main() {
  group('estimateStatusLabel', () {
    test('labels an unsent estimate as draft', () {
      expect(
        estimateStatusLabel(
          jobStatus: 'INSPECTION_PENDING',
          hasEstimateItems: true,
          customerApproved: false,
        ),
        'DRAFT ESTIMATE',
      );
    });

    test('labels sent estimates as awaiting customer response', () {
      expect(
        estimateStatusLabel(
          jobStatus: 'ESTIMATE_SENT',
          hasEstimateItems: true,
          customerApproved: false,
        ),
        'AWAITING CUSTOMER',
      );
    });

    test('approval status is shown only when customer approval exists', () {
      expect(
        estimateStatusLabel(
          jobStatus: 'WORK_IN_PROGRESS',
          hasEstimateItems: true,
          customerApproved: true,
        ),
        'CUSTOMER APPROVED',
      );
    });
  });

  group('isEstimateLocked', () {
    test('keeps the estimate editable only before it is sent', () {
      expect(
        isEstimateLocked(
          jobStatus: 'INSPECTION_PENDING',
          customerApproved: false,
        ),
        isFalse,
      );
      expect(
        isEstimateLocked(jobStatus: 'ESTIMATE_SENT', customerApproved: false),
        isTrue,
      );
    });

    test('locks the estimate after customer approval', () {
      expect(
        isEstimateLocked(
          jobStatus: 'INSPECTION_PENDING',
          customerApproved: true,
        ),
        isTrue,
      );
    });
  });
}

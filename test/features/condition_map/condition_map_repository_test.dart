import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/condition_map/condition_map_repository.dart';

void main() {
  group('condition photo cleanup after a failed save', () {
    test('keeps the upload when the row reference cannot be confirmed', () {
      expect(
        shouldDeleteConditionPhotoAfterFailedSave(
          uploadedPath: 'workshop/job/new.jpg',
          previousPath: 'workshop/job/old.jpg',
          replacementIsReferenced: null,
        ),
        isFalse,
      );
    });

    test(
      'deletes the upload when the row is confirmed not to reference it',
      () {
        expect(
          shouldDeleteConditionPhotoAfterFailedSave(
            uploadedPath: 'workshop/job/new.jpg',
            previousPath: 'workshop/job/old.jpg',
            replacementIsReferenced: false,
          ),
          isTrue,
        );
      },
    );

    test(
      'keeps a confirmed replacement and never removes the old path here',
      () {
        expect(
          shouldDeleteConditionPhotoAfterFailedSave(
            uploadedPath: 'workshop/job/new.jpg',
            previousPath: 'workshop/job/old.jpg',
            replacementIsReferenced: true,
          ),
          isFalse,
        );
        expect(
          shouldDeleteConditionPhotoAfterFailedSave(
            uploadedPath: 'workshop/job/old.jpg',
            previousPath: 'workshop/job/old.jpg',
            replacementIsReferenced: false,
          ),
          isFalse,
        );
      },
    );
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:workshop_dms/features/condition_map/condition_map_controller.dart';
import 'package:workshop_dms/features/condition_map/condition_map_models.dart';
import 'package:workshop_dms/features/condition_map/condition_map_screen.dart';
import 'package:workshop_dms/features/condition_map/condition_map_repository.dart';

void main() {
  group('Condition photo URL refresh', () {
    test('keeps a signed URL until its refresh threshold', () {
      final now = DateTime(2026, 1, 1, 12);

      expect(
        shouldRefreshConditionPhotoUrl(
          now.add(const Duration(minutes: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('refreshes a signed URL at and after its threshold', () {
      final refreshAfter = DateTime(2026, 1, 1, 12);

      expect(
        shouldRefreshConditionPhotoUrl(refreshAfter, now: refreshAfter),
        isTrue,
      );
      expect(
        shouldRefreshConditionPhotoUrl(
          refreshAfter,
          now: refreshAfter.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });

  group('ConditionMapScreen Widget Tests', () {
    testWidgets('Renders vehicle condition areas and sign-off progress', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-101',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vehicle condition'), findsOneWidget);
      expect(find.text('Exterior check'), findsOneWidget);
      expect(find.textContaining('DL01AB9988'), findsOneWidget);
      expect(find.text('0/5 checked'), findsOneWidget);

      // Verify View Tabs
      expect(find.text('Left side'), findsOneWidget);
      expect(find.text('Right side'), findsOneWidget);
      expect(find.text('Front'), findsOneWidget);
      expect(find.text('Rear'), findsOneWidget);

      expect(find.text('Check 5 more areas'), findsOneWidget);
    });

    testWidgets('Adding pins updates defect ledger and canvas pin badges', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      final container = ProviderContainer(
        overrides: [
          conditionMapRepositoryProvider.overrideWithValue(
            LocalConditionMapRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-102',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Programmatically add a pin to the controller
      await container
          .read(conditionMapControllerProvider.notifier)
          .addPin(
            view: ConditionViewDirection.sideLeft,
            nx: 0.45,
            ny: 0.50,
            type: DefectType.dent,
            severity: DefectSeverity.severe,
            note: 'Left door dent',
          );
      await tester.pumpAndSettle();

      expect(container.read(conditionMapControllerProvider).totalPinCount, 1);
      expect(
        container.read(conditionMapControllerProvider).pins.single.note,
        'Left door dent',
      );
    });

    testWidgets('Finding form offers an optional photo attachment', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-PHOTO',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add finding').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Finding:'), findsOneWidget);
      expect(find.text('Add a photo (optional)'), findsOneWidget);
    });

    testWidgets('Photo sources launch directly from their user tap', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      final oldPicker = ImagePickerPlatform.instance;
      final fakePicker = _FakeImagePickerPlatform();
      ImagePickerPlatform.instance = fakePicker;
      addTearDown(() => ImagePickerPlatform.instance = oldPicker);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-PHOTO-TAP',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add finding').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add a photo (optional)'));
      await tester.pump();
      expect(fakePicker.sources, [ImageSource.gallery]);
      await tester.pumpAndSettle();
      expect(find.text('Add a photo (optional)'), findsOneWidget);

      await tester.tap(find.text('Take photo'));
      await tester.pump();
      expect(fakePicker.sources, [ImageSource.gallery, ImageSource.camera]);
      await tester.pumpAndSettle();
    });

    testWidgets('Finding dialog can be canceled while the photo picker waits', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      final oldPicker = ImagePickerPlatform.instance;
      final pendingImage = Completer<XFile?>();
      final fakePicker = _FakeImagePickerPlatform(
        imageResult: pendingImage.future,
      );
      ImagePickerPlatform.instance = fakePicker;
      addTearDown(() => ImagePickerPlatform.instance = oldPicker);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-PHOTO-CANCEL',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add finding').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a photo (optional)'));
      await tester.pump();

      expect(find.text('Opening photos...'), findsOneWidget);
      final cancelButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancelButton.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      pendingImage.complete(null);
      await tester.pump();

      expect(find.textContaining('Finding:'), findsNothing);
    });

    testWidgets('A picked finding photo previews and can be removed', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      final oldPicker = ImagePickerPlatform.instance;
      final fakePicker = _FakeImagePickerPlatform(
        imageResult: Future.value(
          XFile.fromData(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
            ),
            name: 'finding.png',
            mimeType: 'image/png',
          ),
        ),
      );
      ImagePickerPlatform.instance = fakePicker;
      addTearDown(() => ImagePickerPlatform.instance = oldPicker);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-PHOTO-PREVIEW',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add finding').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a photo (optional)'));
      await tester.pumpAndSettle();

      expect(find.text('Remove photo'), findsOneWidget);
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      expect(find.text('Add a photo (optional)'), findsOneWidget);
    });

    testWidgets('A failed finding photo URL can be retried', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      final requests = <Completer<String>>[];
      final container = ProviderContainer(
        overrides: [
          conditionMapRepositoryProvider.overrideWithValue(
            LocalConditionMapRepository(),
          ),
          conditionPhotoUrlLoaderProvider.overrideWithValue((path, seconds) {
            final request = Completer<String>();
            requests.add(request);
            return request.future;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-PHOTO-RETRY',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await container
          .read(conditionMapControllerProvider.notifier)
          .addPin(
            view: ConditionViewDirection.sideLeft,
            nx: .5,
            ny: .5,
            type: DefectType.paintChip,
            severity: DefectSeverity.minor,
            photoPath: 'test-workshop/test-job/finding.jpg',
          );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Photo attached'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(requests, hasLength(1));
      requests.first.completeError(Exception('Expired signed URL'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Photo unavailable · Retry'), findsOneWidget);
      await tester.tap(find.text('Photo unavailable · Retry'));
      await tester.pumpAndSettle();

      expect(requests, hasLength(2));
      requests.last.completeError(Exception('Expired signed URL'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Photo unavailable · Retry'), findsOneWidget);
    });

    testWidgets(
      'Pre-Work Sign-Off Modal validates fields and locks condition map on confirmation',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));

        final container = ProviderContainer(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: ConditionMapScreen(
                jobCardId: 'JC-MAP-103',
                registrationNumber: 'DL01AB9988',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Add 1 minor scratch
        await container
            .read(conditionMapControllerProvider.notifier)
            .addPin(
              view: ConditionViewDirection.sideLeft,
              nx: 0.2,
              ny: 0.5,
              type: DefectType.deepScratch,
              severity: DefectSeverity.minor,
            );
        for (final view in ConditionViewDirection.values) {
          await container
              .read(conditionMapControllerProvider.notifier)
              .markViewReviewed(view);
        }
        await tester.pumpAndSettle();

        await tester.tap(find.text('Review and save report'));
        await tester.pumpAndSettle();

        expect(find.text('Save condition report'), findsOneWidget);
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'Rohan Sharma');
        await tester.enterText(fields.at(1), '9876543210');
        await tester.enterText(fields.at(2), 'Manish Verma');
        await tester.tap(find.text('Customer reviewed this report'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm and save'));
        await tester.pumpAndSettle();
        expect(find.text('Save condition report'), findsNothing);
        expect(find.textContaining('Report saved'), findsOneWidget);
      },
    );
  });
}

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  _FakeImagePickerPlatform({Future<XFile?>? imageResult})
    : imageResult = imageResult ?? Future<XFile?>.value(null);

  final Future<XFile?> imageResult;
  final List<ImageSource> sources = [];

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    sources.add(source);
    return imageResult;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/ui_kit/gallery/gallery_screen.dart';
import 'package:workshop_dms/ui_kit/widgets/concentric_shutter_button.dart';
import 'package:workshop_dms/ui_kit/widgets/severity_pin.dart';
import 'package:workshop_dms/ui_kit/widgets/fuel_intake_slider.dart';
import 'package:workshop_dms/ui_kit/widgets/belongings_pills_group.dart';
import 'package:workshop_dms/ui_kit/widgets/traffic_light_matrix.dart';
import 'package:workshop_dms/ui_kit/widgets/calibrated_wear_input.dart';

void main() {
  group('GalleryScreen & UI Kit Components (Review Gate)', () {
    testWidgets(
      'GalleryScreen renders all Bucket 1 & Bucket 2 sections and headers',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: GalleryScreen()));
        await tester.pumpAndSettle();

        // Check App Bar
        expect(find.text('UI KIT COMPONENT GALLERY'), findsOneWidget);

        // Check Section Headers
        expect(
          find.text('BUCKET 2: NEW ARTWORK & PURE GEOMETRY'),
          findsOneWidget,
        );
        expect(find.text('BUCKET 1: TOKEN COMPOSITIONS'), findsOneWidget);

        // Check Bucket 2 cards
        expect(
          find.text('CONCENTRIC SHUTTER BUTTON (72x72 outer, 52x52 inner)'),
          findsOneWidget,
        );
        expect(
          find.text('INDIAN HIGH SECURITY REGISTRATION PLATES (HSRP)'),
          findsOneWidget,
        );
        expect(
          find.text('CONDITION DEFECT SEVERITY PINS (28x34 pt geometry)'),
          findsOneWidget,
        );

        // Check HSRP plates
        expect(find.text('RJ 27 CA 1024'), findsOneWidget);
        expect(find.text('HR 26 EB 9415'), findsOneWidget);

        // Check Severity Pins
        expect(find.text('L1'), findsOneWidget);
        expect(find.text('L2'), findsOneWidget);
        expect(find.text('L3'), findsNWidgets(2)); // Unselected + Selected

        // Check Bucket 1 items
        expect(find.text('FUEL LEVEL AT INTAKE'), findsOneWidget);
        expect(find.text('VALUABLES & BELONGINGS'), findsOneWidget);
        expect(
          find.text('TRAFFIC-LIGHT INSPECTION MATRIX (R / A / G)'),
          findsOneWidget,
        );
        expect(find.text('CALIBRATED WEAR MEASUREMENT INPUTS'), findsOneWidget);
      },
    );

    testWidgets('ConcentricShutterButton renders and handles tap interaction', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConcentricShutterButton(
                onPressed: () => tapped = true,
                state: ShutterButtonState.resting,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ConcentricShutterButton);
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets(
      'SeverityPinWidget renders given severity code and responds to tap',
      (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SeverityPinWidget(
                  level: DefectSeverityLevel.l2,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('L2'), findsOneWidget);
        await tester.tap(find.byType(SeverityPinWidget));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
      },
    );

    testWidgets('FuelIntakeSlider updates discrete step value', (tester) async {
      double currentVal = 0.50;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FuelIntakeSlider(
                  value: currentVal,
                  onChanged: (val) => setState(() => currentVal = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('50% TANK'), findsOneWidget);

      // Tap F (100%)
      await tester.tap(find.text('F'));
      await tester.pumpAndSettle();
      expect(currentVal, equals(1.0));
      expect(find.text('100% TANK'), findsOneWidget);
    });

    testWidgets('FuelIntakeSlider does not imply an unobserved reading', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FuelIntakeSlider(
              value: 0.5,
              isConfirmed: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('SELECT LEVEL'), findsOneWidget);
      expect(find.text('50% TANK'), findsNothing);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 0.0);
    });

    testWidgets('BelongingsPillsGroup toggles inventory items correctly', (
      tester,
    ) async {
      Set<String> items = {'Fastag'};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BelongingsPillsGroup(
                  selectedItems: items,
                  onChanged: (updated) => setState(() => items = updated),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('1 CONFIRMED'), findsOneWidget);

      // Toggle Spare Wheel
      await tester.tap(find.text('Spare Wheel'));
      await tester.pumpAndSettle();
      expect(items.contains('Spare Wheel'), isTrue);
      expect(find.text('2 CONFIRMED'), findsOneWidget);
    });

    testWidgets('TrafficLightItemRow selects status correctly', (tester) async {
      DiagnosticStatus? status = DiagnosticStatus.pass;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TrafficLightItemRow(
                  title: 'Brake Inspection',
                  subtitle: 'Checking thickness',
                  status: status,
                  onStatusChanged: (s) => setState(() => status = s),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('PASS'), findsOneWidget);
      expect(find.text('ADVISORY'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);

      await tester.tap(find.text('CRITICAL'));
      await tester.pumpAndSettle();
      expect(status, equals(DiagnosticStatus.critical));
    });

    testWidgets(
      'CalibratedWearInput displays health badge according to thresholds',
      (tester) async {
        double? value = 1.2;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return CalibratedWearInput(
                    label: 'Tyre Tread',
                    unit: 'mm',
                    value: value,
                    criticalThreshold: 1.6,
                    advisoryThreshold: 3.0,
                    onChanged: (val) => setState(() => value = val),
                  );
                },
              ),
            ),
          ),
        );

        // 1.2 <= 1.6 -> CRITICAL WEAR
        expect(find.text('CRITICAL WEAR'), findsOneWidget);
      },
    );
  });
}

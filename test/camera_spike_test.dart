import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/camera_spike_screen.dart';

void main() {
  group('Camera Spike Unit & Widget Tests', () {
    testWidgets(
      'Displays explanation screen on first use before requesting permission',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: CameraSpikeScreen()));

        // Verify the one-line explanation requirement is met
        expect(find.text('CAMERA ACCESS REQUIRED'), findsOneWidget);
        expect(
          find.text(
            'Workshop Check-in requires camera access to capture vehicle condition photos and odometer readings.',
          ),
          findsOneWidget,
        );
        expect(find.text('CONTINUE & ALLOW CAMERA'), findsOneWidget);
      },
    );

    testWidgets('Renders top bar with capture counter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CameraSpikeScreen()));

      expect(find.text('CAMERA CAPTURE SPIKE'), findsOneWidget);
      expect(find.text('CAPTURES: 0'), findsOneWidget);
    });
  });
}

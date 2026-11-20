import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/ui_kit/widgets/sharp_button.dart';

void main() {
  group('SharpButton Widget Tests', () {
    testWidgets('Renders label in uppercase and responds to tap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SharpButton(label: 'Proceed', onPressed: () => tapped = true),
          ),
        ),
      );

      expect(find.text('PROCEED'), findsOneWidget);
      await tester.tap(find.text('PROCEED'));
      expect(tapped, isTrue);
    });

    testWidgets('Disabled state does not trigger callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SharpButton(label: 'Locked', onPressed: null)),
        ),
      );

      expect(find.text('LOCKED'), findsOneWidget);
      await tester.tap(find.text('LOCKED'));
      // No crash, remains disabled
    });
  });
}

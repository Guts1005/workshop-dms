import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/ui_kit/widgets/swipe_to_confirm_slider.dart';

void main() {
  group('SwipeToConfirmSlider Widget Tests', () {
    testWidgets('Renders label and can be swiped to confirm', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SwipeToConfirmSlider(
                label: 'Swipe to Deliver',
                onConfirmed: () => confirmed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('SWIPE TO DELIVER'), findsOneWidget);

      // Drag the slider thumb across
      final thumbFinder = find.byIcon(Icons.arrow_forward);
      expect(thumbFinder, findsOneWidget);

      await tester.drag(thumbFinder, const Offset(260.0, 0.0));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('CONFIRMED'), findsOneWidget);
    });
  });
}

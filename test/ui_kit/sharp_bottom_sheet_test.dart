import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/ui_kit/widgets/sharp_bottom_sheet.dart';

void main() {
  group('SharpBottomSheet Widget Tests', () {
    testWidgets('Opens modal and displays title and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SharpBottomSheet.show(
                      context: context,
                      title: 'Credit Override',
                      child: const Text('Authorized By Manager'),
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('CREDIT OVERRIDE'), findsOneWidget);
      expect(find.text('Authorized By Manager'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('CREDIT OVERRIDE'), findsNothing);
    });
  });
}

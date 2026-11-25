import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/work_in_progress/work_in_progress_screen.dart';

void main() {
  testWidgets('requires a positive quantity within the available limit', (
    tester,
  ) async {
    String? submittedQuantity;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                submittedQuantity = await showDialog<String>(
                  context: context,
                  builder: (_) => const StockMovementDialog(
                    type: 'ISSUE',
                    description: 'Front brake pads',
                    maximum: 4,
                  ),
                );
              },
              child: const Text('Open stock movement'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open stock movement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '5');
    await tester.tap(find.text('Issue part'));
    await tester.pumpAndSettle();

    expect(find.text('Maximum available: 4'), findsOneWidget);
    expect(submittedQuantity, isNull);

    await tester.enterText(find.byType(TextFormField), '2.5');
    await tester.tap(find.text('Issue part'));
    await tester.pumpAndSettle();

    expect(submittedQuantity, '2.5');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel closes and disposes the stock movement input', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (_) => const StockMovementDialog(
                  type: 'RETURN',
                  description: 'Air filter',
                  maximum: 1,
                ),
              ),
              child: const Text('Open stock movement'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open stock movement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '1');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Return Air filter'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

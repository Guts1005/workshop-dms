import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/billing/gst_engine.dart';
import 'package:workshop_dms/features/job_card/presentation/job_card_screen.dart';

void main() {
  testWidgets('returns a validated estimate item and closes cleanly', (
    tester,
  ) async {
    EstimateLineItemDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<EstimateLineItemDraft>(
                  context: context,
                  builder: (_) =>
                      const EstimateLineItemDialog(type: LineItemType.labour),
                );
              },
              child: const Text('Open estimate dialog'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open estimate dialog'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Replace front brake pads');
    await tester.enterText(fields.at(1), '998714');
    await tester.enterText(fields.at(2), '1.5');
    await tester.enterText(fields.at(3), '2400.50');
    await tester.enterText(fields.at(4), '18');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(result?.description, 'Replace front brake pads');
    expect(result?.code, '998714');
    expect(result?.quantity, 1.5);
    expect(result?.unitRateInr, 2400.5);
    expect(result?.gstRatePercent, 18);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel disposes dialog fields after the close animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<EstimateLineItemDraft>(
                context: context,
                builder: (_) =>
                    const EstimateLineItemDialog(type: LineItemType.part),
              ),
              child: const Text('Open estimate dialog'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open estimate dialog'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Air filter');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Add part'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

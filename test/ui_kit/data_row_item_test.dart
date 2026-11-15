import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/ui_kit/widgets/data_row_item.dart';

void main() {
  group('DataRowItem Widget Tests', () {
    testWidgets('Renders label and value properly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataRowItem(
              label: 'Engine Oil',
              value: '5W-30 Synthetic',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('ENGINE OIL'), findsOneWidget);
      expect(find.text('5W-30 Synthetic'), findsOneWidget);

      await tester.tap(find.text('ENGINE OIL'));
      expect(tapped, isTrue);
    });
  });
}

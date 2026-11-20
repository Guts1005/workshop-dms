import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/ui_kit/widgets/status_chip.dart';

void main() {
  group('StatusChip Widget Tests', () {
    testWidgets('Renders critical, dueSoon, ok, and neutral chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusChip(
                  label: 'Critical',
                  icon: Icons.warning,
                  type: StatusType.critical,
                ),
                StatusChip(
                  label: 'Due Soon',
                  icon: Icons.schedule,
                  type: StatusType.dueSoon,
                ),
                StatusChip(
                  label: 'Healthy',
                  icon: Icons.check,
                  type: StatusType.ok,
                ),
                StatusChip(
                  label: 'Neutral',
                  icon: Icons.info,
                  type: StatusType.neutral,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('DUE SOON'), findsOneWidget);
      expect(find.text('HEALTHY'), findsOneWidget);
      expect(find.text('NEUTRAL'), findsOneWidget);
    });
  });
}

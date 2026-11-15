import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workshop_dms/main.dart';

void main() {
  testWidgets('Root Navigation Shell smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WorkshopDmsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WORKSHOP DMS'), findsOneWidget);
    expect(find.text('1. INTAKE'), findsOneWidget);
    expect(find.text('PAGE 1: VEHICLE & CUSTOMER INTAKE'), findsOneWidget);
  });
}

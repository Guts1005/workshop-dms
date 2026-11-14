import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/main.dart';

void main() {
  testWidgets('Workshop DMS App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkshopDmsApp());
    expect(find.text('SPEEDCRAFT WORKSHOP DMS'), findsOneWidget);
  });
}

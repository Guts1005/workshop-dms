import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workshop_dms/main.dart';

void main() {
  testWidgets(
    'Root app requires database configuration before showing records',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: WorkshopDmsApp()));
      await tester.pumpAndSettle();

      expect(find.text('Connect your database'), findsOneWidget);
      expect(find.textContaining('env.json'), findsOneWidget);
    },
  );
}

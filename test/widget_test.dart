import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/main.dart';

void main() {
  testWidgets('Camera Spike smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CameraSpikeApp());
    expect(find.text('CAMERA CAPTURE SPIKE'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/applications/presentation/applications_screen.dart';

void main() {
  test('application cards expose each implemented workflow action', () {
    for (final route in [
      '/bay-capture',
      '/condition-map',
      '/mechanical-inspection',
      '/job-card',
      '/whatsapp-dispatch',
      '/work-in-progress',
      '/qc-gate',
      '/gst-invoicing',
      '/payment-gate',
    ]) {
      expect(applicationRouteHasAction(route), isTrue, reason: route);
    }
  });

  test('application cards omit terminal or unknown routes', () {
    expect(applicationRouteHasAction('/applications'), isFalse);
    expect(applicationRouteHasAction('/reminders'), isFalse);
    expect(applicationRouteHasAction(null), isFalse);
  });
}

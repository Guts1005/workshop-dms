import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  test(
    'dashboard keeps each application next step and excludes terminal jobs',
    () {
      final items = dashboardAttentionApplications([
        {
          'id': 'job-wip',
          'statusCode': 'WORK_IN_PROGRESS',
          'route': '/work-in-progress',
          'nextActionLabel': 'Update work progress',
          'pendingItems': ['Add a technician progress update'],
        },
        {
          'statusCode': 'DELIVERED',
          'route': '/applications',
          'pendingItems': ['Application complete'],
        },
        {
          'statusCode': 'CANCELLED',
          'route': '/applications',
          'pendingItems': ['Application cancelled'],
        },
      ]);

      expect(items, hasLength(1));
      expect(items.single['route'], '/work-in-progress');
      expect(items.single['nextActionLabel'], 'Update work progress');
    },
  );

  test('dashboard limits attention list to three records', () {
    final items = List.generate(
      4,
      (index) => <String, dynamic>{
        'statusCode': 'WORK_IN_PROGRESS',
        'pendingItems': ['Pending $index'],
      },
    );

    expect(dashboardAttentionApplications(items), hasLength(3));
  });
}

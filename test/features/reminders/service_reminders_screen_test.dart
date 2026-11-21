import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/reminders/service_reminder_engine.dart';
import 'package:workshop_dms/features/reminders/service_reminder_models.dart';
import 'package:workshop_dms/features/reminders/service_reminder_repository.dart';
import 'package:workshop_dms/features/reminders/service_reminders_screen.dart';

class FakeServiceReminderRepository implements ServiceReminderRepository {
  FakeServiceReminderRepository(this.workspace, {this.currentConsent = true});

  ServiceReminderWorkspace workspace;
  final bool currentConsent;
  ServiceReminderSettings? savedSettings;
  int consentChecks = 0;

  @override
  Future<ServiceReminderWorkspace> load({DateTime? now}) async => workspace;

  @override
  Future<void> saveSettings(ServiceReminderSettings settings) async {
    savedSettings = settings;
    workspace = ServiceReminderWorkspace(
      workshopName: workspace.workshopName,
      memberRole: workspace.memberRole,
      settings: settings,
      reminders: workspace.reminders,
    );
  }

  @override
  Future<bool> hasWhatsAppConsent(String customerId) async {
    consentChecks++;
    return currentConsent;
  }
}

void main() {
  testWidgets('prompts the owner to set an interval before showing reminders', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final repository = FakeServiceReminderRepository(
      const ServiceReminderWorkspace(
        workshopName: 'Northside Garage',
        memberRole: 'owner',
        settings: null,
        reminders: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: ServiceRemindersScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reminder interval not set'), findsOneWidget);
    expect(find.text('Set your reminder interval'), findsOneWidget);
    expect(find.text('OVERDUE'), findsNothing);
  });

  testWidgets('saves intervals chosen by the workshop manager', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final repository = FakeServiceReminderRepository(
      const ServiceReminderWorkspace(
        workshopName: 'Northside Garage',
        memberRole: 'owner',
        settings: null,
        reminders: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: ServiceRemindersScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '12000');
    await tester.enterText(fields.at(1), '365');
    await tester.enterText(fields.at(2), '21');
    await tester.tap(find.text('Save interval'));
    await tester.pumpAndSettle();

    expect(repository.savedSettings?.intervalKm, 12000);
    expect(repository.savedSettings?.intervalDays, 365);
    expect(repository.savedSettings?.dueSoonDays, 21);
    expect(find.text('Reminder interval not set'), findsNothing);
  });

  testWidgets('rechecks consent before preparing a WhatsApp reminder', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final result = ServiceReminderEngine.evaluate(
      customerName: 'Asha',
      mobileNumber: '9876543210',
      vehicleModel: 'Example Hatchback',
      registrationNumber: 'KA 01 AB 1234',
      lastServiceDate: DateTime(2025, 1, 1),
      lastServiceOdometerKm: 20000,
      intervalKm: 10000,
      intervalDays: 180,
      now: DateTime(2026, 1, 1),
    );
    final repository = FakeServiceReminderRepository(
      ServiceReminderWorkspace(
        workshopName: 'Northside Garage',
        memberRole: 'advisor',
        settings: const ServiceReminderSettings(
          intervalKm: 10000,
          intervalDays: 180,
        ),
        reminders: [
          VehicleServiceReminder(
            vehicleId: 'vehicle-1',
            customerId: 'customer-1',
            whatsappConsent: true,
            result: result,
            previousVisitCount: 1,
          ),
        ],
      ),
      currentConsent: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: ServiceRemindersScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('OVERDUE'), findsOneWidget);
    await tester.tap(find.text('Prepare WhatsApp reminder'));
    await tester.pumpAndSettle();

    expect(repository.consentChecks, 1);
    expect(
      find.text('WhatsApp consent is no longer recorded.'),
      findsOneWidget,
    );
  });
}

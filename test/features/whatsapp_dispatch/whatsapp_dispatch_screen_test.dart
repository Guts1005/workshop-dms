import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/whatsapp_dispatch/estimate_response_controller.dart';
import 'package:workshop_dms/features/whatsapp_dispatch/estimate_response_models.dart';
import 'package:workshop_dms/features/whatsapp_dispatch/estimate_response_repository.dart';
import 'package:workshop_dms/features/whatsapp_dispatch/whatsapp_dispatch_screen.dart';

class _ScreenResponseRepository implements EstimateResponseRepository {
  _ScreenResponseRepository(this.whatsappConsent);

  final bool whatsappConsent;

  @override
  Future<EstimateResponseWorkspace> getWorkspace(String jobCardId) async =>
      EstimateResponseWorkspace(
        jobCardId: jobCardId,
        registrationNumber: 'KA01AB1234',
        customerName: 'Customer One',
        customerPhone: '9876543210',
        whatsappConsent: whatsappConsent,
        status: 'ESTIMATE_SENT',
        items: const [
          EstimateResponseItem(
            id: 'item-1',
            description: 'Brake pads',
            itemType: 'part',
            code: '8708',
            quantity: 1,
            unitRatePaise: 120000,
            gstRatePercent: 18,
            decision: EstimateItemDecision.pending,
            note: '',
          ),
        ],
      );

  @override
  Future<String> recordResponse({
    required String jobCardId,
    required String customerName,
    required List<EstimateResponseItem> items,
  }) async => 'WORK_IN_PROGRESS';

  @override
  Future<String?> confirmRecordedResponse({
    required String jobCardId,
    required String customerName,
    required List<EstimateResponseItem> items,
  }) async => null;
}

void main() {
  for (final consent in [false, true]) {
    testWidgets(
      'WhatsApp sending is ${consent ? 'enabled' : 'disabled'} with consent=$consent',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              estimateResponseRepositoryProvider.overrideWithValue(
                _ScreenResponseRepository(consent),
              ),
            ],
            child: const MaterialApp(
              home: WhatsAppDispatchScreen(jobCardId: 'job-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Customer response'), findsOneWidget);
        expect(find.text('Brake pads'), findsOneWidget);
        final sendButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Send WhatsApp follow-up'),
        );
        expect(sendButton.onPressed == null, isNot(consent));
      },
    );
  }
}

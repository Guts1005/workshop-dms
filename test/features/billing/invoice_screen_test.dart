import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/billing/gst_engine.dart';
import 'package:workshop_dms/features/billing/invoice_controller.dart';
import 'package:workshop_dms/features/billing/invoice_models.dart';
import 'package:workshop_dms/features/billing/invoice_repository.dart';
import 'package:workshop_dms/features/billing/invoice_screen.dart';

class _InvoiceScreenRepository implements InvoiceRepository {
  @override
  Future<InvoiceWorkspace> load(String jobCardId) async => InvoiceWorkspace(
    jobCardId: jobCardId,
    registrationNumber: 'KA01AB1234',
    workshopName: 'Workshop One',
    customerName: 'Customer One',
    items: const [
      InvoiceLineItem(
        id: 'line-1',
        type: LineItemType.labour,
        description: 'Brake service',
        code: '998714',
        quantity: 1,
        unitRatePaise: 120000,
        gstRatePercent: 18,
      ),
    ],
    existingInvoice: null,
  );

  @override
  Future<IssuedInvoice> issue({
    required String jobCardId,
    required InvoiceIssueDetails details,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('shows supplier/customer invoice details and approved items', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoiceRepositoryProvider.overrideWithValue(
            _InvoiceScreenRepository(),
          ),
        ],
        child: const MaterialApp(home: InvoiceScreen(jobCardId: 'job-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GST invoice'), findsOneWidget);
    expect(find.text('SUPPLIER DETAILS'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('CUSTOMER DETAILS'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('CUSTOMER DETAILS'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Brake service'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Brake service'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Review and issue tax invoice'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Review and issue tax invoice'), findsOneWidget);
  });
}

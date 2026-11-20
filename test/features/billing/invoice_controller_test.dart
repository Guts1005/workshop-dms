import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/billing/gst_engine.dart';
import 'package:workshop_dms/features/billing/invoice_controller.dart';
import 'package:workshop_dms/features/billing/invoice_models.dart';
import 'package:workshop_dms/features/billing/invoice_repository.dart';

class _MemoryInvoiceRepository implements InvoiceRepository {
  IssuedInvoice? issued;

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
        description: 'Repair work',
        code: '998714',
        quantity: 1,
        unitRatePaise: 10000,
        gstRatePercent: 18,
      ),
    ],
    existingInvoice: issued,
  );

  @override
  Future<IssuedInvoice> issue({
    required String jobCardId,
    required InvoiceIssueDetails details,
  }) async {
    issued = IssuedInvoice(
      id: 'invoice-1',
      invoiceNumber: 'INV/2026-27/00001',
      issueDate: DateTime.utc(2026, 11, 20),
      supplierName: details.supplierName,
      supplierAddress: details.supplierAddress,
      supplierGstin: details.supplierGstin,
      supplierStateCode: details.supplierStateCode,
      recipientName: 'Customer One',
      recipientAddress: details.recipientAddress,
      recipientGstin: details.recipientGstin.isEmpty
          ? null
          : details.recipientGstin,
      placeOfSupplyStateCode: details.placeOfSupplyStateCode,
      taxType: details.supplierStateCode == details.placeOfSupplyStateCode
          ? 'INTRA_STATE'
          : 'INTER_STATE',
      totalTaxablePaise: 10000,
      cgstPaise: 900,
      sgstPaise: 900,
      igstPaise: 0,
      totalTaxPaise: 1800,
      grandTotalPaise: 11800,
      lines: const [],
    );
    return issued!;
  }
}

void main() {
  group('InvoiceController', () {
    late _MemoryInvoiceRepository repository;
    late InvoiceController controller;

    setUp(() {
      repository = _MemoryInvoiceRepository();
      controller = InvoiceController(repository: repository);
    });

    tearDown(() => controller.dispose());

    test(
      'loads estimate snapshot only through the invoice repository',
      () async {
        await controller.load('job-1');

        expect(controller.state.workspace?.registrationNumber, 'KA01AB1234');
        expect(controller.state.workspace?.items, hasLength(1));
      },
    );

    test('issues and retains the immutable invoice snapshot', () async {
      await controller.load('job-1');
      const details = InvoiceIssueDetails(
        supplierName: 'Workshop One',
        supplierAddress: '1 Main Road, Bengaluru',
        supplierGstin: '29ABCDE1234F1Z5',
        supplierStateCode: '29',
        recipientAddress: '2 Market Road, Bengaluru',
        recipientGstin: '',
        placeOfSupplyStateCode: '29',
      );

      final saved = await controller.issue(details);

      expect(saved, isTrue);
      expect(
        controller.state.issuedInvoice?.invoiceNumber,
        'INV/2026-27/00001',
      );
      expect(controller.state.issuedInvoice?.grandTotalPaise, 11800);
    });
  });
}

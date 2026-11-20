import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/billing/gst_engine.dart';

void main() {
  group('AutomotiveGstEngine', () {
    test('applies the stored line rate to decimal quantities in paise', () {
      const item = InvoiceLineItem(
        id: 'line-1',
        type: LineItemType.part,
        description: 'Part',
        code: '8708',
        quantity: 1.5,
        unitRatePaise: 10001,
        gstRatePercent: 18,
      );

      expect(item.taxableAmountPaise, 15002);
      expect(item.gstAmountPaise, 2700);
      expect(item.totalAmountPaise, 17702);
    });

    test('splits intra-state tax per line without paise drift', () {
      const items = [
        InvoiceLineItem(
          id: 'line-1',
          type: LineItemType.part,
          description: 'Part one',
          code: '8708',
          quantity: 1,
          unitRatePaise: 3,
          gstRatePercent: 18,
        ),
        InvoiceLineItem(
          id: 'line-2',
          type: LineItemType.part,
          description: 'Part two',
          code: '8708',
          quantity: 1,
          unitRatePaise: 3,
          gstRatePercent: 18,
        ),
      ];

      final result = AutomotiveGstEngine.calculate(
        items: items,
        isIntraState: true,
        totalPaidPaise: 0,
      );

      expect(result.cgstAmountPaise, 2);
      expect(result.sgstAmountPaise, 0);
      expect(result.igstAmountPaise, 0);
      expect(result.grandTotalPaise, 8);
    });

    test(
      'uses IGST for inter-state invoices and caps paid balance at zero',
      () {
        const item = InvoiceLineItem(
          id: 'line-1',
          type: LineItemType.labour,
          description: 'Repair work',
          code: '998714',
          quantity: 1,
          unitRatePaise: 10000,
          gstRatePercent: 18,
        );

        final result = AutomotiveGstEngine.calculate(
          items: const [item],
          isIntraState: false,
          totalPaidPaise: 20000,
        );

        expect(result.igstAmountPaise, 1800);
        expect(result.cgstAmountPaise, 0);
        expect(result.sgstAmountPaise, 0);
        expect(result.balanceDuePaise, 0);
      },
    );
  });
}

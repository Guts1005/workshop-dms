enum LineItemType {
  labour,
  part,
}

enum PaymentMode {
  cash('CASH'),
  upi('UPI / QR'),
  card('DEBIT / CREDIT CARD'),
  bankTransfer('NET BANKING / NEFT');

  final String label;
  const PaymentMode(this.label);
}

class InvoiceLineItem {
  final String id;
  final LineItemType type;
  final String description;
  final String code; // SAC 998729 for labour, HSN for parts
  final int quantity; // Units (or hours for labour)
  final int unitRatePaise; // 1 INR = 100 paise
  final int discountPaise;
  final int gstRatePercent; // 18 or 28

  const InvoiceLineItem({
    required this.id,
    required this.type,
    required this.description,
    required this.code,
    required this.quantity,
    required this.unitRatePaise,
    this.discountPaise = 0,
    required this.gstRatePercent,
  });

  int get taxableAmountPaise {
    final subtotal = (unitRatePaise * quantity) - discountPaise;
    return subtotal > 0 ? subtotal : 0;
  }

  int get gstAmountPaise {
    return ((taxableAmountPaise * gstRatePercent) / 100).round();
  }

  int get totalAmountPaise {
    return taxableAmountPaise + gstAmountPaise;
  }
}

class InvoiceTaxSummary {
  final int totalTaxablePaise;
  final int totalLabourTaxablePaise;
  final int totalPartsTaxablePaise;
  final int cgstAmountPaise;
  final int sgstAmountPaise;
  final int igstAmountPaise;
  final int grandTotalPaise;
  final int totalPaidPaise;
  final int balanceDuePaise;

  const InvoiceTaxSummary({
    required this.totalTaxablePaise,
    required this.totalLabourTaxablePaise,
    required this.totalPartsTaxablePaise,
    required this.cgstAmountPaise,
    required this.sgstAmountPaise,
    required this.igstAmountPaise,
    required this.grandTotalPaise,
    required this.totalPaidPaise,
    required this.balanceDuePaise,
  });
}

class CreditOverride {
  final String authorizedBy;
  final DateTime promisedDueDate;
  final String reason;
  final DateTime timestamp;

  const CreditOverride({
    required this.authorizedBy,
    required this.promisedDueDate,
    required this.reason,
    required this.timestamp,
  });
}

class AutomotiveGstEngine {
  /// Computes GST breakdown adhering strictly to Indian Automotive tax slabs
  static InvoiceTaxSummary calculate({
    required List<InvoiceLineItem> items,
    required bool isIntraState,
    required int totalPaidPaise,
  }) {
    int taxableLabour = 0;
    int taxableParts = 0;
    int totalGst = 0;

    for (final item in items) {
      if (item.type == LineItemType.labour) {
        taxableLabour += item.taxableAmountPaise;
      } else {
        taxableParts += item.taxableAmountPaise;
      }
      totalGst += item.gstAmountPaise;
    }

    final totalTaxable = taxableLabour + taxableParts;
    final grandTotal = totalTaxable + totalGst;
    final balanceDue = grandTotal - totalPaidPaise;

    int cgst = 0;
    int sgst = 0;
    int igst = 0;

    if (isIntraState) {
      cgst = (totalGst / 2).round();
      sgst = totalGst - cgst; // Ensure zero roundoff loss
    } else {
      igst = totalGst;
    }

    return InvoiceTaxSummary(
      totalTaxablePaise: totalTaxable,
      totalLabourTaxablePaise: taxableLabour,
      totalPartsTaxablePaise: taxableParts,
      cgstAmountPaise: cgst,
      sgstAmountPaise: sgst,
      igstAmountPaise: igst,
      grandTotalPaise: grandTotal,
      totalPaidPaise: totalPaidPaise,
      balanceDuePaise: balanceDue > 0 ? balanceDue : 0,
    );
  }

  /// Formats integer paise into standard Indian Rupee string (e.g. 747672 -> ₹7,476.72)
  static String formatRupees(int paise) {
    final double inr = paise / 100.0;
    return '₹${inr.toStringAsFixed(2)}';
  }
}

enum PaymentMethod {
  cash('CASH', 'Cash'),
  upi('UPI', 'UPI'),
  card('CARD', 'Card'),
  bankTransfer('BANK_TRANSFER', 'Bank transfer'),
  other('OTHER', 'Other');

  const PaymentMethod(this.databaseValue, this.label);
  final String databaseValue;
  final String label;
}

class PaymentEntry {
  const PaymentEntry({
    required this.amountPaise,
    required this.method,
    required this.reference,
    required this.receivedBy,
    required this.createdAt,
  });

  final int amountPaise;
  final PaymentMethod method;
  final String reference;
  final String receivedBy;
  final DateTime createdAt;
}

class PaymentWorkspace {
  const PaymentWorkspace({
    required this.jobCardId,
    required this.registrationNumber,
    required this.customerName,
    required this.invoiceNumber,
    required this.invoiceTotalPaise,
    required this.payments,
    required this.isOwner,
    required this.deliveredAt,
    required this.creditOverrideReason,
  });

  final String jobCardId;
  final String registrationNumber;
  final String customerName;
  final String invoiceNumber;
  final int invoiceTotalPaise;
  final List<PaymentEntry> payments;
  final bool isOwner;
  final DateTime? deliveredAt;
  final String? creditOverrideReason;

  int get paidPaise =>
      payments.fold(0, (sum, entry) => sum + entry.amountPaise);
  int get balancePaise => invoiceTotalPaise - paidPaise;
  bool get delivered => deliveredAt != null;
}

String formatPaymentRupees(int paise) {
  final rupees = (paise.abs() / 100).toStringAsFixed(2);
  return '${paise < 0 ? '-' : ''}₹$rupees';
}

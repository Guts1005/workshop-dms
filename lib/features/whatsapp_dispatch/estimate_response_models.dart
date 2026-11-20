enum EstimateItemDecision {
  pending,
  approved,
  declined,
  revisionRequested;

  String get databaseValue => switch (this) {
    EstimateItemDecision.pending => 'PENDING',
    EstimateItemDecision.approved => 'APPROVED',
    EstimateItemDecision.declined => 'DECLINED',
    EstimateItemDecision.revisionRequested => 'REVISION_REQUESTED',
  };

  String get label => switch (this) {
    EstimateItemDecision.pending => 'Choose response',
    EstimateItemDecision.approved => 'Approved',
    EstimateItemDecision.declined => 'Declined',
    EstimateItemDecision.revisionRequested => 'Change requested',
  };
}

class EstimateResponseItem {
  const EstimateResponseItem({
    required this.id,
    required this.description,
    required this.itemType,
    required this.code,
    required this.quantity,
    required this.unitRatePaise,
    required this.gstRatePercent,
    required this.decision,
    required this.note,
  });

  final String id;
  final String description;
  final String itemType;
  final String code;
  final num quantity;
  final int unitRatePaise;
  final num gstRatePercent;
  final EstimateItemDecision decision;
  final String note;

  int get taxableAmountPaise => (quantity * unitRatePaise).round();
  int get gstAmountPaise => (taxableAmountPaise * gstRatePercent / 100).round();
}

class EstimateResponseWorkspace {
  const EstimateResponseWorkspace({
    required this.jobCardId,
    required this.registrationNumber,
    required this.customerName,
    required this.customerPhone,
    required this.whatsappConsent,
    required this.status,
    required this.items,
  });

  final String jobCardId;
  final String registrationNumber;
  final String customerName;
  final String customerPhone;
  final bool whatsappConsent;
  final String status;
  final List<EstimateResponseItem> items;
}

String? validateEstimateResponse({
  required String customerName,
  required List<EstimateResponseItem> items,
}) {
  if (customerName.trim().length < 2) {
    return 'Enter the name of the customer who responded.';
  }
  if (items.isEmpty) return 'There are no estimate items to review.';
  if (items.any((item) => item.decision == EstimateItemDecision.pending)) {
    return 'Choose a response for every estimate item.';
  }
  if (items.any((item) => item.note.trim().length > 1000)) {
    return 'Each response note must be 1,000 characters or fewer.';
  }
  return null;
}

String estimateShareMessage(EstimateResponseWorkspace workspace) {
  final lines = <String>[
    'Workshop estimate for ${workspace.registrationNumber}',
    'Customer: ${workspace.customerName}',
    '',
    ...workspace.items.map(
      (item) =>
          '• ${item.description} × ${item.quantity} — ₹${(item.taxableAmountPaise / 100).toStringAsFixed(2)}',
    ),
    '',
    'Total including GST: ₹${(workspace.items.fold<int>(0, (sum, item) => sum + item.taxableAmountPaise + item.gstAmountPaise) / 100).toStringAsFixed(2)}',
    'Please review each item and reply with your decision or questions.',
  ];
  return lines.join('\n');
}

String estimateStatusLabel({
  required String jobStatus,
  required bool hasEstimateItems,
  required bool customerApproved,
}) {
  if (customerApproved) return 'CUSTOMER APPROVED';
  if (jobStatus == 'ESTIMATE_SENT' || jobStatus == 'WAITING_APPROVAL') {
    return 'AWAITING CUSTOMER';
  }
  if (jobStatus == 'ESTIMATE_REVISION_REQUIRED') return 'REVISION NEEDED';
  return hasEstimateItems ? 'DRAFT ESTIMATE' : 'NO ESTIMATE ITEMS';
}

bool isEstimateLocked({
  required String jobStatus,
  required bool customerApproved,
}) =>
    customerApproved ||
    (jobStatus != 'INSPECTION_PENDING' &&
        jobStatus != 'ESTIMATE_REVISION_REQUIRED');

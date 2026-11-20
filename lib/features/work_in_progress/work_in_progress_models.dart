enum WorkUpdateType {
  progressNote('PROGRESS_NOTE', 'Progress note'),
  waitingForParts('WAITING_FOR_PARTS', 'Waiting for parts'),
  customerUpdate('CUSTOMER_UPDATE', 'Customer contact note');

  const WorkUpdateType(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static WorkUpdateType fromDatabase(String value) => values.firstWhere(
    (type) => type.databaseValue == value,
    orElse: () => WorkUpdateType.progressNote,
  );
}

class WorkScopeItem {
  const WorkScopeItem({
    required this.description,
    required this.itemType,
    required this.quantity,
  });

  final String description;
  final String itemType;
  final num quantity;
}

class JobWorkUpdate {
  const JobWorkUpdate({
    required this.type,
    required this.note,
    required this.createdBy,
    required this.createdAt,
  });

  final WorkUpdateType type;
  final String note;
  final String createdBy;
  final DateTime createdAt;
}

class WorkInProgressWorkspace {
  const WorkInProgressWorkspace({
    required this.jobCardId,
    required this.registrationNumber,
    required this.scope,
    required this.updates,
  });

  final String jobCardId;
  final String registrationNumber;
  final List<WorkScopeItem> scope;
  final List<JobWorkUpdate> updates;
}

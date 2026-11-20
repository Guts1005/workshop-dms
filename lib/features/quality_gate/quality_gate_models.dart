enum RoadTestResult {
  passed('PASSED', 'Passed'),
  failed('FAILED', 'Failed'),
  notRequired('NOT_REQUIRED', 'Not required');

  const RoadTestResult(this.databaseValue, this.label);
  final String databaseValue;
  final String label;
}

class QualityCheckSpec {
  const QualityCheckSpec(this.id, this.label);
  final String id;
  final String label;
}

const qualityCheckSpecs = [
  QualityCheckSpec('fluids_ok', 'Fluid levels and visible leaks checked'),
  QualityCheckSpec('brakes_ok', 'Brake operation checked'),
  QualityCheckSpec('warning_lights_clear', 'Warning lights checked'),
  QualityCheckSpec('tools_removed', 'Tools and protective covers removed'),
];

class QualityGateWorkspace {
  const QualityGateWorkspace({
    required this.jobCardId,
    required this.registrationNumber,
  });

  final String jobCardId;
  final String registrationNumber;
}

class MechanicalMeasurementSpec {
  const MechanicalMeasurementSpec({
    required this.id,
    required this.label,
    required this.unit,
    required this.maxValue,
  });

  final String id;
  final String label;
  final String unit;
  final double maxValue;
}

const mechanicalMeasurementSpecs = <MechanicalMeasurementSpec>[
  MechanicalMeasurementSpec(
    id: 'front_brake_pad_mm',
    label: 'Front brake pad thickness',
    unit: 'mm',
    maxValue: 100,
  ),
  MechanicalMeasurementSpec(
    id: 'rear_brake_pad_mm',
    label: 'Rear brake pad thickness',
    unit: 'mm',
    maxValue: 100,
  ),
  MechanicalMeasurementSpec(
    id: 'minimum_tyre_tread_mm',
    label: 'Minimum tyre tread depth',
    unit: 'mm',
    maxValue: 50,
  ),
  MechanicalMeasurementSpec(
    id: 'battery_voltage_v',
    label: 'Battery resting voltage',
    unit: 'V',
    maxValue: 100,
  ),
  MechanicalMeasurementSpec(
    id: 'battery_cca',
    label: 'Battery measured CCA',
    unit: 'A',
    maxValue: 5000,
  ),
];

class MechanicalInspectionRecord {
  const MechanicalInspectionRecord({
    required this.inspectorName,
    required this.odometerKm,
    required this.measurements,
    required this.notApplicable,
    required this.notes,
    required this.completedAt,
  });

  final String inspectorName;
  final int odometerKm;
  final Map<String, double> measurements;
  final Set<String> notApplicable;
  final String notes;
  final DateTime completedAt;
}

String? validateMechanicalInspection({
  required String inspectorName,
  required int? odometerKm,
  required int minimumOdometerKm,
  required Map<String, String> measurementTexts,
  required Set<String> notApplicable,
}) {
  if (inspectorName.trim().isEmpty) return 'Enter the inspector name.';
  if (odometerKm == null || odometerKm < minimumOdometerKm) {
    return 'Enter a valid odometer reading of at least $minimumOdometerKm km.';
  }

  for (final spec in mechanicalMeasurementSpecs) {
    if (notApplicable.contains(spec.id)) continue;
    final text = measurementTexts[spec.id]?.trim() ?? '';
    final value = double.tryParse(text);
    if (text.isEmpty || value == null || !value.isFinite || value < 0) {
      return 'Enter ${spec.label.toLowerCase()} or mark it not applicable.';
    }
    if (value > spec.maxValue) {
      final maxValue = spec.maxValue == spec.maxValue.roundToDouble()
          ? spec.maxValue.toInt().toString()
          : spec.maxValue.toString();
      return '${spec.label} must be no greater than $maxValue ${spec.unit}.';
    }
  }

  if (notApplicable.length >= mechanicalMeasurementSpecs.length) {
    return 'Record at least one measured value.';
  }
  return null;
}

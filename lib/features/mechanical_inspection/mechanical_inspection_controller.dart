import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mechanical_inspection_models.dart';
import 'mechanical_inspection_repository.dart';

final mechanicalInspectionRepositoryProvider =
    Provider<MechanicalInspectionRepository>((ref) {
      return SupabaseMechanicalInspectionRepository(Supabase.instance.client);
    });

final mechanicalInspectionControllerProvider =
    StateNotifierProvider.autoDispose<
      MechanicalInspectionController,
      MechanicalInspectionState
    >((ref) {
      return MechanicalInspectionController(
        repository: ref.watch(mechanicalInspectionRepositoryProvider),
      );
    });

class MechanicalInspectionState {
  const MechanicalInspectionState({
    this.jobCardId = '',
    this.registrationNumber = '',
    this.intakeOdometerKm = 0,
    this.inspectorName = '',
    this.odometerText = '',
    this.measurementTexts = const {},
    this.notApplicable = const {},
    this.notes = '',
    this.loading = false,
    this.ready = false,
    this.saving = false,
    this.saved = false,
    this.errorMessage,
  });

  final String jobCardId;
  final String registrationNumber;
  final int intakeOdometerKm;
  final String inspectorName;
  final String odometerText;
  final Map<String, String> measurementTexts;
  final Set<String> notApplicable;
  final String notes;
  final bool loading;
  final bool ready;
  final bool saving;
  final bool saved;
  final String? errorMessage;

  MechanicalInspectionState copyWith({
    String? jobCardId,
    String? registrationNumber,
    int? intakeOdometerKm,
    String? inspectorName,
    String? odometerText,
    Map<String, String>? measurementTexts,
    Set<String>? notApplicable,
    String? notes,
    bool? loading,
    bool? ready,
    bool? saving,
    bool? saved,
    String? errorMessage,
    bool clearError = false,
  }) => MechanicalInspectionState(
    jobCardId: jobCardId ?? this.jobCardId,
    registrationNumber: registrationNumber ?? this.registrationNumber,
    intakeOdometerKm: intakeOdometerKm ?? this.intakeOdometerKm,
    inspectorName: inspectorName ?? this.inspectorName,
    odometerText: odometerText ?? this.odometerText,
    measurementTexts: measurementTexts ?? this.measurementTexts,
    notApplicable: notApplicable ?? this.notApplicable,
    notes: notes ?? this.notes,
    loading: loading ?? this.loading,
    ready: ready ?? this.ready,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class MechanicalInspectionController
    extends StateNotifier<MechanicalInspectionState> {
  MechanicalInspectionController({required this.repository})
    : super(const MechanicalInspectionState());

  final MechanicalInspectionRepository repository;
  int _loadAttempt = 0;

  Future<void> initSession({
    required String jobCardId,
    required String registrationNumber,
  }) async {
    final attempt = ++_loadAttempt;
    state = state.copyWith(
      jobCardId: jobCardId,
      registrationNumber: registrationNumber,
      loading: true,
      ready: false,
      clearError: true,
    );
    try {
      final results = await Future.wait<Object?>([
        repository.getIntakeOdometer(jobCardId),
        repository.getInspection(jobCardId),
      ]);
      final intakeOdometer = results[0] as int;
      final inspection = results[1] as MechanicalInspectionRecord?;
      if (attempt != _loadAttempt) return;
      state = state.copyWith(
        intakeOdometerKm: intakeOdometer,
        inspectorName: inspection?.inspectorName ?? '',
        odometerText:
            inspection?.odometerKm.toString() ?? intakeOdometer.toString(),
        measurementTexts: {
          for (final spec in mechanicalMeasurementSpecs)
            spec.id: inspection?.measurements[spec.id]?.toString() ?? '',
        },
        notApplicable: inspection?.notApplicable ?? const {},
        notes: inspection?.notes ?? '',
        saved: inspection != null,
        loading: false,
        ready: true,
        clearError: true,
      );
    } catch (_) {
      if (attempt != _loadAttempt) return;
      state = state.copyWith(
        loading: false,
        ready: false,
        errorMessage:
            'Could not load the inspection. Check your connection and retry.',
      );
    }
  }

  void setInspectorName(String value) => state = state.copyWith(
    inspectorName: value,
    saved: false,
    clearError: true,
  );

  void setOdometer(String value) => state = state.copyWith(
    odometerText: value,
    saved: false,
    clearError: true,
  );

  void setMeasurement(String id, String value) {
    state = state.copyWith(
      measurementTexts: {...state.measurementTexts, id: value},
      saved: false,
      clearError: true,
    );
  }

  void setNotApplicable(String id, bool value) {
    final updated = Set<String>.from(state.notApplicable);
    if (value) {
      updated.add(id);
    } else {
      updated.remove(id);
    }
    state = state.copyWith(
      notApplicable: updated,
      saved: false,
      clearError: true,
    );
  }

  void setNotes(String value) =>
      state = state.copyWith(notes: value, saved: false, clearError: true);

  Future<bool> save() async {
    if (!state.ready) {
      state = state.copyWith(
        errorMessage: 'Load the application before saving this inspection.',
      );
      return false;
    }
    final odometer = int.tryParse(state.odometerText.trim());
    final error = validateMechanicalInspection(
      inspectorName: state.inspectorName,
      odometerKm: odometer,
      minimumOdometerKm: state.intakeOdometerKm,
      measurementTexts: state.measurementTexts,
      notApplicable: state.notApplicable,
    );
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return false;
    }

    final measurements = <String, double>{};
    for (final spec in mechanicalMeasurementSpecs) {
      if (state.notApplicable.contains(spec.id)) continue;
      measurements[spec.id] = double.parse(state.measurementTexts[spec.id]!);
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      await repository.saveInspection(
        jobCardId: state.jobCardId,
        inspection: MechanicalInspectionRecord(
          inspectorName: state.inspectorName.trim(),
          odometerKm: odometer!,
          measurements: measurements,
          notApplicable: state.notApplicable,
          notes: state.notes.trim(),
          completedAt: DateTime.now(),
        ),
      );
      state = state.copyWith(saving: false, saved: true, clearError: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Inspection could not be saved. Your entries are still here; retry when connected.',
      );
      return false;
    }
  }
}

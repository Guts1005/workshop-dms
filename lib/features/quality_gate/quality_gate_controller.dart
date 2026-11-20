import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'quality_gate_models.dart';
import 'quality_gate_repository.dart';

final qualityGateRepositoryProvider = Provider<QualityGateRepository>((ref) {
  return SupabaseQualityGateRepository(Supabase.instance.client);
});

final qualityGateControllerProvider =
    StateNotifierProvider.autoDispose<QualityGateController, QualityGateState>(
      (ref) => QualityGateController(
        repository: ref.watch(qualityGateRepositoryProvider),
      ),
    );

class QualityGateState {
  const QualityGateState({
    this.workspace,
    this.loading = false,
    this.saving = false,
    this.workCompleted = false,
    this.checks = const {},
    this.roadTestResult = RoadTestResult.passed,
    this.roadTestNote = '',
    this.notes = '',
    this.inspectorName = '',
    this.result,
    this.errorMessage,
  });

  final QualityGateWorkspace? workspace;
  final bool loading;
  final bool saving;
  final bool workCompleted;
  final Map<String, bool> checks;
  final RoadTestResult roadTestResult;
  final String roadTestNote;
  final String notes;
  final String inspectorName;
  final String? result;
  final String? errorMessage;

  QualityGateState copyWith({
    QualityGateWorkspace? workspace,
    bool? loading,
    bool? saving,
    bool? workCompleted,
    Map<String, bool>? checks,
    RoadTestResult? roadTestResult,
    String? roadTestNote,
    String? notes,
    String? inspectorName,
    String? result,
    String? errorMessage,
    bool clearError = false,
  }) => QualityGateState(
    workspace: workspace ?? this.workspace,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    workCompleted: workCompleted ?? this.workCompleted,
    checks: checks ?? this.checks,
    roadTestResult: roadTestResult ?? this.roadTestResult,
    roadTestNote: roadTestNote ?? this.roadTestNote,
    notes: notes ?? this.notes,
    inspectorName: inspectorName ?? this.inspectorName,
    result: result ?? this.result,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class QualityGateController extends StateNotifier<QualityGateState> {
  QualityGateController({required this.repository})
    : super(const QualityGateState());

  final QualityGateRepository repository;
  String _jobCardId = '';

  Future<void> load(String jobCardId) async {
    _jobCardId = jobCardId;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final workspace = await repository.load(jobCardId);
      state = state.copyWith(
        workspace: workspace,
        loading: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage:
            'Could not load the quality gate. Check the connection and retry.',
      );
    }
  }

  void setWorkCompleted(bool value) =>
      state = state.copyWith(workCompleted: value, clearError: true);

  void setCheck(String id, bool passed) => state = state.copyWith(
    checks: {...state.checks, id: passed},
    clearError: true,
  );

  void setRoadTestResult(RoadTestResult value) =>
      state = state.copyWith(roadTestResult: value, clearError: true);

  void setRoadTestNote(String value) =>
      state = state.copyWith(roadTestNote: value, clearError: true);

  void setNotes(String value) => state = state.copyWith(notes: value);
  void setInspectorName(String value) =>
      state = state.copyWith(inspectorName: value, clearError: true);

  Future<bool> save() async {
    if (state.inspectorName.trim().length < 2) {
      state = state.copyWith(errorMessage: 'Enter the inspector name.');
      return false;
    }
    if (!state.workCompleted) {
      state = state.copyWith(
        errorMessage: 'Confirm that the approved work is complete.',
      );
      return false;
    }
    if (qualityCheckSpecs.any((spec) => !state.checks.containsKey(spec.id))) {
      state = state.copyWith(errorMessage: 'Complete each quality check.');
      return false;
    }
    if (state.roadTestResult != RoadTestResult.passed &&
        state.roadTestNote.trim().length < 2) {
      state = state.copyWith(
        errorMessage: 'Add a reason for a failed or skipped road test.',
      );
      return false;
    }

    state = state.copyWith(saving: true, clearError: true);
    try {
      final result = await repository.save(
        jobCardId: _jobCardId,
        inspectorName: state.inspectorName,
        workCompleted: state.workCompleted,
        checks: state.checks,
        roadTestResult: state.roadTestResult,
        roadTestNote: state.roadTestNote,
        notes: state.notes,
      );
      state = state.copyWith(saving: false, result: result, clearError: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Quality check was not saved. Your entries are still here; retry when connected.',
      );
      return false;
    }
  }
}

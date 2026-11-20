import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'work_in_progress_models.dart';
import 'work_in_progress_repository.dart';

final workInProgressRepositoryProvider = Provider<WorkInProgressRepository>((
  ref,
) {
  return SupabaseWorkInProgressRepository(Supabase.instance.client);
});

final workInProgressControllerProvider =
    StateNotifierProvider.autoDispose<
      WorkInProgressController,
      WorkInProgressState
    >((ref) {
      return WorkInProgressController(
        repository: ref.watch(workInProgressRepositoryProvider),
      );
    });

class WorkInProgressState {
  const WorkInProgressState({
    this.workspace,
    this.loading = false,
    this.saving = false,
    this.updateType = WorkUpdateType.progressNote,
    this.note = '',
    this.errorMessage,
  });

  final WorkInProgressWorkspace? workspace;
  final bool loading;
  final bool saving;
  final WorkUpdateType updateType;
  final String note;
  final String? errorMessage;

  WorkInProgressState copyWith({
    WorkInProgressWorkspace? workspace,
    bool? loading,
    bool? saving,
    WorkUpdateType? updateType,
    String? note,
    String? errorMessage,
    bool clearError = false,
  }) => WorkInProgressState(
    workspace: workspace ?? this.workspace,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    updateType: updateType ?? this.updateType,
    note: note ?? this.note,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class WorkInProgressController extends StateNotifier<WorkInProgressState> {
  WorkInProgressController({required this.repository})
    : super(const WorkInProgressState());

  final WorkInProgressRepository repository;
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
            'Could not load work progress. Check the connection and retry.',
      );
    }
  }

  void setType(WorkUpdateType value) =>
      state = state.copyWith(updateType: value, clearError: true);

  void setNote(String value) =>
      state = state.copyWith(note: value, clearError: true);

  Future<bool> save() async {
    final note = state.note.trim();
    if (note.length < 2 || note.length > 1000) {
      state = state.copyWith(
        errorMessage: 'Enter a note between 2 and 1000 characters.',
      );
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      await repository.addUpdate(
        jobCardId: _jobCardId,
        type: state.updateType,
        note: note,
      );
      final workspace = await repository.load(_jobCardId);
      state = state.copyWith(
        workspace: workspace,
        note: '',
        saving: false,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Update was not saved. Your note is still here; retry when connected.',
      );
      return false;
    }
  }
}

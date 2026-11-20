import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'estimate_response_models.dart';
import 'estimate_response_repository.dart';

final estimateResponseRepositoryProvider = Provider<EstimateResponseRepository>(
  (ref) {
    return SupabaseEstimateResponseRepository(Supabase.instance.client);
  },
);

final estimateResponseControllerProvider =
    StateNotifierProvider.autoDispose<
      EstimateResponseController,
      EstimateResponseState
    >((ref) {
      return EstimateResponseController(
        repository: ref.watch(estimateResponseRepositoryProvider),
      );
    });

class EstimateResponseState {
  const EstimateResponseState({
    this.workspace,
    this.customerName = '',
    this.decisions = const {},
    this.notes = const {},
    this.loading = false,
    this.saving = false,
    this.errorMessage,
    this.completedStatus,
  });

  final EstimateResponseWorkspace? workspace;
  final String customerName;
  final Map<String, EstimateItemDecision> decisions;
  final Map<String, String> notes;
  final bool loading;
  final bool saving;
  final String? errorMessage;
  final String? completedStatus;

  EstimateResponseState copyWith({
    EstimateResponseWorkspace? workspace,
    String? customerName,
    Map<String, EstimateItemDecision>? decisions,
    Map<String, String>? notes,
    bool? loading,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
    String? completedStatus,
  }) => EstimateResponseState(
    workspace: workspace ?? this.workspace,
    customerName: customerName ?? this.customerName,
    decisions: decisions ?? this.decisions,
    notes: notes ?? this.notes,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    completedStatus: completedStatus ?? this.completedStatus,
  );
}

class EstimateResponseController extends StateNotifier<EstimateResponseState> {
  EstimateResponseController({required this.repository})
    : super(const EstimateResponseState());

  final EstimateResponseRepository repository;

  Future<void> load(String jobCardId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final workspace = await repository.getWorkspace(jobCardId);
      state = state.copyWith(
        workspace: workspace,
        customerName: workspace.customerName,
        decisions: {for (final item in workspace.items) item.id: item.decision},
        notes: {for (final item in workspace.items) item.id: item.note},
        loading: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Could not load the estimate response. Check your connection and retry.',
      );
    }
  }

  void setCustomerName(String value) =>
      state = state.copyWith(customerName: value, clearError: true);

  void setDecision(String itemId, EstimateItemDecision decision) {
    state = state.copyWith(
      decisions: {...state.decisions, itemId: decision},
      clearError: true,
    );
  }

  void setNote(String itemId, String note) => state = state.copyWith(
    notes: {...state.notes, itemId: note},
    clearError: true,
  );

  String? validateCurrent() {
    final workspace = state.workspace;
    if (workspace == null) return 'The estimate is not loaded.';
    final error = validateEstimateResponse(
      customerName: state.customerName,
      items: [
        for (final item in workspace.items)
          EstimateResponseItem(
            id: item.id,
            description: item.description,
            itemType: item.itemType,
            code: item.code,
            quantity: item.quantity,
            unitRatePaise: item.unitRatePaise,
            gstRatePercent: item.gstRatePercent,
            decision: state.decisions[item.id] ?? EstimateItemDecision.pending,
            note: state.notes[item.id] ?? '',
          ),
      ],
    );
    if (error != null) state = state.copyWith(errorMessage: error);
    return error;
  }

  Future<bool> save() async {
    final workspace = state.workspace;
    if (workspace == null) return false;
    final items = [
      for (final item in workspace.items)
        EstimateResponseItem(
          id: item.id,
          description: item.description,
          itemType: item.itemType,
          code: item.code,
          quantity: item.quantity,
          unitRatePaise: item.unitRatePaise,
          gstRatePercent: item.gstRatePercent,
          decision: state.decisions[item.id] ?? EstimateItemDecision.pending,
          note: state.notes[item.id] ?? '',
        ),
    ];
    final validation = validateCurrent();
    if (validation != null) {
      state = state.copyWith(errorMessage: validation);
      return false;
    }

    state = state.copyWith(saving: true, clearError: true);
    try {
      final status = await repository.recordResponse(
        jobCardId: workspace.jobCardId,
        customerName: state.customerName.trim(),
        items: items,
      );
      state = state.copyWith(saving: false, completedStatus: status);
      return true;
    } catch (_) {
      try {
        final confirmedStatus = await repository.confirmRecordedResponse(
          jobCardId: workspace.jobCardId,
          customerName: state.customerName.trim(),
          items: items,
        );
        if (confirmedStatus != null) {
          state = state.copyWith(
            saving: false,
            completedStatus: confirmedStatus,
            clearError: true,
          );
          return true;
        }
      } catch (_) {
        // Keep the original message if persisted state cannot be confirmed.
      }
      state = state.copyWith(
        saving: false,
        errorMessage: 'Customer response was not saved. Your entries are still here; retry when connected.',
      );
      return false;
    }
  }
}

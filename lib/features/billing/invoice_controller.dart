import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'invoice_models.dart';
import 'invoice_repository.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return SupabaseInvoiceRepository(Supabase.instance.client);
});

final invoiceControllerProvider =
    StateNotifierProvider.autoDispose<InvoiceController, InvoiceState>(
      (ref) =>
          InvoiceController(repository: ref.watch(invoiceRepositoryProvider)),
    );

class InvoiceState {
  const InvoiceState({
    this.workspace,
    this.issuedInvoice,
    this.loading = false,
    this.issuing = false,
    this.errorMessage,
  });

  final InvoiceWorkspace? workspace;
  final IssuedInvoice? issuedInvoice;
  final bool loading;
  final bool issuing;
  final String? errorMessage;

  InvoiceState copyWith({
    InvoiceWorkspace? workspace,
    IssuedInvoice? issuedInvoice,
    bool? loading,
    bool? issuing,
    String? errorMessage,
    bool clearError = false,
  }) => InvoiceState(
    workspace: workspace ?? this.workspace,
    issuedInvoice: issuedInvoice ?? this.issuedInvoice,
    loading: loading ?? this.loading,
    issuing: issuing ?? this.issuing,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class InvoiceController extends StateNotifier<InvoiceState> {
  InvoiceController({required this.repository}) : super(const InvoiceState());

  final InvoiceRepository repository;
  String _jobCardId = '';

  Future<void> load(String jobCardId) async {
    _jobCardId = jobCardId;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final workspace = await repository.load(jobCardId);
      state = state.copyWith(
        workspace: workspace,
        issuedInvoice: workspace.existingInvoice,
        loading: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage:
            'Could not load the invoice. Check the connection and retry.',
      );
    }
  }

  Future<bool> issue(InvoiceIssueDetails details) async {
    if (_jobCardId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Open an invoice from an application.',
      );
      return false;
    }
    if (state.issuedInvoice != null) {
      state = state.copyWith(
        errorMessage: 'This job already has an issued invoice.',
      );
      return false;
    }
    state = state.copyWith(issuing: true, clearError: true);
    try {
      final invoice = await repository.issue(
        jobCardId: _jobCardId,
        details: details,
      );
      state = state.copyWith(
        issuedInvoice: invoice,
        issuing: false,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        issuing: false,
        errorMessage: 'Invoice was not issued. Check the details and retry.',
      );
      return false;
    }
  }
}

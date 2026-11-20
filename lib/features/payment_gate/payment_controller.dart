import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'payment_models.dart';
import 'payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository(Supabase.instance.client);
});

final paymentControllerProvider =
    StateNotifierProvider.autoDispose<PaymentController, PaymentState>(
      (ref) =>
          PaymentController(repository: ref.watch(paymentRepositoryProvider)),
    );

class PaymentState {
  const PaymentState({
    this.workspace,
    this.loading = false,
    this.saving = false,
    this.errorMessage,
    this.successMessage,
  });

  final PaymentWorkspace? workspace;
  final bool loading;
  final bool saving;
  final String? errorMessage;
  final String? successMessage;

  PaymentState copyWith({
    PaymentWorkspace? workspace,
    bool? loading,
    bool? saving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) => PaymentState(
    workspace: workspace ?? this.workspace,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    successMessage: clearSuccess
        ? null
        : (successMessage ?? this.successMessage),
  );
}

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController({required this.repository}) : super(const PaymentState());
  final PaymentRepository repository;
  final _uuid = const Uuid();
  String _jobCardId = '';
  String? _pendingPaymentRequestId;

  Future<void> load(String jobCardId) async {
    _jobCardId = jobCardId;
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.copyWith(
        workspace: await repository.load(jobCardId),
        loading: false,
        saving: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        saving: false,
        errorMessage:
            'Could not load payment details. Check your connection and retry.',
      );
    }
  }

  Future<bool> record({
    required String amountText,
    required PaymentMethod method,
    required String reference,
  }) async {
    final paise = _parseAmountPaise(amountText);
    if (paise == null || paise <= 0) {
      state = state.copyWith(errorMessage: 'Enter a valid payment amount.');
      return false;
    }
    final workspace = state.workspace;
    if (workspace == null || paise > workspace.balancePaise) {
      state = state.copyWith(
        errorMessage: 'Payment cannot exceed the outstanding balance.',
      );
      return false;
    }
    state = state.copyWith(saving: true, clearError: true, clearSuccess: true);
    try {
      await repository.record(
        jobCardId: _jobCardId,
        amountPaise: paise,
        method: method,
        reference: reference,
        requestId: _pendingPaymentRequestId ??= _uuid.v4(),
      );
      _pendingPaymentRequestId = null;
      await load(_jobCardId);
      state = state.copyWith(successMessage: 'Payment recorded.');
      return true;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Payment was not saved. Your entry is still here; retry when connected.',
      );
      return false;
    }
  }

  Future<bool> deliver(String creditOverrideReason) async {
    final workspace = state.workspace;
    if (workspace == null) return false;
    if (workspace.balancePaise > 0 &&
        (!workspace.isOwner || creditOverrideReason.trim().length < 5)) {
      state = state.copyWith(
        errorMessage: workspace.isOwner
            ? 'Add a reason of at least five characters for the credit override.'
            : 'The balance must be cleared before handover.',
      );
      return false;
    }
    state = state.copyWith(saving: true, clearError: true, clearSuccess: true);
    try {
      await repository.deliver(
        jobCardId: _jobCardId,
        creditOverrideReason: creditOverrideReason,
      );
      await load(_jobCardId);
      state = state.copyWith(successMessage: 'Vehicle handover recorded.');
      return true;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Delivery was not recorded. Refresh and try again.',
      );
      return false;
    }
  }

  int? _parseAmountPaise(String raw) {
    final value = raw.trim();
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(value)) return null;
    final parts = value.split('.');
    final rupees = int.tryParse(parts.first);
    if (rupees == null) return null;
    final fraction = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
    final minor = int.tryParse(fraction);
    if (minor == null) return null;
    return rupees * 100 + minor;
  }
}

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'condition_map_models.dart';
import 'condition_map_repository.dart';

final conditionMapRepositoryProvider = Provider<ConditionMapRepository>((ref) {
  return SupabaseConditionMapRepository(Supabase.instance.client);
});

final conditionMapControllerProvider =
    StateNotifierProvider.autoDispose<
      ConditionMapController,
      ConditionMapState
    >((ref) {
      final repo = ref.watch(conditionMapRepositoryProvider);
      return ConditionMapController(repository: repo);
    });

class ConditionMapController extends StateNotifier<ConditionMapState> {
  static int _lastPinId = 0;
  final ConditionMapRepository repository;
  PreWorkSignOff? _pendingSignOff;

  ConditionMapController({
    required this.repository,
    String? initialJobCardId,
    String? initialRegistration,
  }) : super(
         ConditionMapState(
           jobCardId: initialJobCardId ?? '',
           registrationNumber: initialRegistration ?? '',
         ),
       );

  Future<void> initSession({
    required String jobCardId,
    required String registrationNumber,
  }) async {
    if (state.jobCardId != jobCardId) {
      _pendingSignOff = null;
    }
    state = state.copyWith(
      jobCardId: jobCardId,
      registrationNumber: registrationNumber,
      clearError: true,
    );

    try {
      final pins = await repository.getPinsForJobCard(jobCardId);
      final signOff = await repository.getSignOff(jobCardId);
      final reviewedViews = await repository.getReviewedViews(jobCardId);
      state = state.copyWith(
        pins: pins,
        signOff: signOff,
        reviewedViews: reviewedViews,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load condition map: $e');
    }
  }

  void switchView(ConditionViewDirection view) {
    state = state.copyWith(
      activeView: view,
      clearSelectedPin: true,
      clearError: true,
    );
  }

  Future<void> markViewReviewed(ConditionViewDirection view) async {
    final reviewed = Set<ConditionViewDirection>.from(state.reviewedViews)
      ..add(view);
    await repository.saveReviewedViews(state.jobCardId, reviewed);
    state = state.copyWith(reviewedViews: reviewed, clearError: true);
  }

  void selectPin(ConditionPin? pin) {
    state = state.copyWith(
      selectedPin: pin,
      clearSelectedPin: pin == null,
      clearError: true,
    );
  }

  Future<ConditionPin> addPin({
    required ConditionViewDirection view,
    required double nx,
    required double ny,
    required DefectType type,
    required DefectSeverity severity,
    String? note,
    String? photoPath,
    String? photoHash,
    Uint8List? photoBytes,
    String? photoContentType,
  }) async {
    _ensureEditable();

    final nowId = DateTime.now().microsecondsSinceEpoch;
    final newId = nowId > _lastPinId ? nowId : _lastPinId + 1;
    _lastPinId = newId;
    final pin = ConditionPin(
      id: newId,
      view: view,
      normalizedX: nx.clamp(0.0, 1.0),
      normalizedY: ny.clamp(0.0, 1.0),
      type: type,
      severity: severity,
      note: note,
      photoPath: photoPath,
      photoHash: photoHash,
      createdAt: DateTime.now(),
    );

    final savedPin = await repository.savePin(
      jobCardId: state.jobCardId,
      pin: pin,
      photoBytes: photoBytes,
      photoContentType: photoContentType,
    );
    final reviewed = Set<ConditionViewDirection>.from(state.reviewedViews)
      ..add(view);
    await repository.saveReviewedViews(state.jobCardId, reviewed);

    final updatedPins = List<ConditionPin>.from(state.pins)..add(savedPin);
    state = state.copyWith(
      pins: updatedPins,
      reviewedViews: reviewed,
      selectedPin: savedPin,
      clearError: true,
    );

    return savedPin;
  }

  Future<void> updatePin(ConditionPin updatedPin) async {
    _ensureEditable();

    final savedPin = await repository.savePin(
      jobCardId: state.jobCardId,
      pin: updatedPin,
    );

    final updatedPins = state.pins
        .map((p) => p.id == savedPin.id ? savedPin : p)
        .toList();
    state = state.copyWith(
      pins: updatedPins,
      selectedPin: savedPin,
      clearError: true,
    );
  }

  Future<void> deletePin(int pinId) async {
    _ensureEditable();

    await repository.deletePin(jobCardId: state.jobCardId, pinId: pinId);

    final updatedPins = state.pins.where((p) => p.id != pinId).toList();
    state = state.copyWith(
      pins: updatedPins,
      clearSelectedPin: state.selectedPin?.id == pinId,
      clearError: true,
    );
  }

  String? validateSignOffInput({
    required String customerName,
    required String customerPhone,
    required String advisorName,
  }) {
    if (state.reviewedViews.length != ConditionViewDirection.values.length) {
      return 'Review all five vehicle views before saving this report';
    }
    if (customerName.trim().length < 2) {
      return 'Customer name must be at least 2 characters';
    }
    final digits = customerPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Enter a valid 10-digit customer mobile number for pre-work record';
    }
    if (advisorName.trim().length < 2) {
      return 'Service advisor name must be at least 2 characters';
    }
    return null;
  }

  void _ensureEditable() {
    if (state.isLocked || _pendingSignOff != null) {
      throw StateError(
        'This condition report is signed or awaiting sign-off confirmation.',
      );
    }
  }

  Future<bool> confirmPreWorkSignOff({
    required String customerName,
    required String customerPhone,
    required String advisorName,
  }) async {
    final validationError = validateSignOffInput(
      customerName: customerName,
      customerPhone: customerPhone,
      advisorName: advisorName,
    );
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    final pending = _pendingSignOff;
    if (pending != null &&
        (pending.customerName != customerName.trim() ||
            pending.customerPhone != customerPhone.trim() ||
            pending.advisorName != advisorName.trim())) {
      state = state.copyWith(
        errorMessage: 'Retry with the same customer and advisor details to safely confirm the saved sign-off.',
      );
      return false;
    }

    state = state.copyWith(status: ConditionMapStatus.saving, clearError: true);

    try {
      final now = pending?.signedAt ?? DateTime.now();
      final checksum = PreWorkSignOff.generateChecksum(
        jobCardId: state.jobCardId,
        registrationNumber: state.registrationNumber,
        pins: state.pins,
        customerPhone: customerPhone,
        timestamp: now,
      );
      if (pending != null && pending.sha256Checksum != checksum) {
        state = state.copyWith(
          status: ConditionMapStatus.error,
          errorMessage: 'The condition details changed after sign-off began. Reload this report before continuing.',
        );
        return false;
      }

      final signOff =
          pending ??
          PreWorkSignOff(
            customerName: customerName.trim(),
            customerPhone: customerPhone.trim(),
            advisorName: advisorName.trim(),
            signedAt: now,
            customerAcknowledged: true,
            sha256Checksum: checksum,
          );
      _pendingSignOff = signOff;

      await repository.saveSignOff(
        jobCardId: state.jobCardId,
        signOff: signOff,
      );

      state = state.copyWith(
        signOff: signOff,
        status: ConditionMapStatus.completed,
        clearSelectedPin: true,
      );
      _pendingSignOff = null;
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ConditionMapStatus.error,
        errorMessage: 'Failed to record pre-work sign-off: $e',
      );
      return false;
    }
  }
}

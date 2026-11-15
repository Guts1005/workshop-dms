import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'condition_map_models.dart';
import 'condition_map_repository.dart';

final conditionMapRepositoryProvider = Provider<ConditionMapRepository>((ref) {
  return LocalConditionMapRepository();
});

final conditionMapControllerProvider =
    StateNotifierProvider.autoDispose<ConditionMapController, ConditionMapState>((ref) {
  final repo = ref.watch(conditionMapRepositoryProvider);
  return ConditionMapController(repository: repo);
});

class ConditionMapController extends StateNotifier<ConditionMapState> {
  final ConditionMapRepository repository;

  ConditionMapController({
    required this.repository,
    String? initialJobCardId,
    String? initialRegistration,
  }) : super(ConditionMapState(
          jobCardId: initialJobCardId ?? 'JC-TEMP-${DateTime.now().millisecondsSinceEpoch}',
          registrationNumber: initialRegistration ?? 'MH02CL8899',
        ));

  Future<void> initSession({
    required String jobCardId,
    required String registrationNumber,
  }) async {
    state = state.copyWith(
      jobCardId: jobCardId,
      registrationNumber: registrationNumber,
      clearError: true,
    );

    try {
      final pins = await repository.getPinsForJobCard(jobCardId);
      final signOff = await repository.getSignOff(jobCardId);
      state = state.copyWith(
        pins: pins,
        signOff: signOff,
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
  }) async {
    if (state.isLocked) {
      throw StateError('Condition map is signed off and locked against modifications.');
    }

    final newId = state.pins.isEmpty ? 1 : (state.pins.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1);
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

    await repository.savePin(jobCardId: state.jobCardId, pin: pin);

    final updatedPins = List<ConditionPin>.from(state.pins)..add(pin);
    state = state.copyWith(
      pins: updatedPins,
      selectedPin: pin,
      clearError: true,
    );

    return pin;
  }

  Future<void> updatePin(ConditionPin updatedPin) async {
    if (state.isLocked) {
      throw StateError('Condition map is locked. Cannot edit pins.');
    }

    await repository.savePin(jobCardId: state.jobCardId, pin: updatedPin);

    final updatedPins = state.pins.map((p) => p.id == updatedPin.id ? updatedPin : p).toList();
    state = state.copyWith(
      pins: updatedPins,
      selectedPin: updatedPin,
      clearError: true,
    );
  }

  Future<void> deletePin(int pinId) async {
    if (state.isLocked) {
      throw StateError('Condition map is locked. Cannot delete pins.');
    }

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

    state = state.copyWith(status: ConditionMapStatus.saving, clearError: true);

    try {
      final now = DateTime.now();
      final checksum = PreWorkSignOff.generateChecksum(
        jobCardId: state.jobCardId,
        registrationNumber: state.registrationNumber,
        pins: state.pins,
        customerPhone: customerPhone,
        timestamp: now,
      );

      final signOff = PreWorkSignOff(
        customerName: customerName.trim(),
        customerPhone: customerPhone.trim(),
        advisorName: advisorName.trim(),
        signedAt: now,
        customerAcknowledged: true,
        sha256Checksum: checksum,
      );

      await repository.saveSignOff(jobCardId: state.jobCardId, signOff: signOff);

      state = state.copyWith(
        signOff: signOff,
        status: ConditionMapStatus.completed,
        clearSelectedPin: true,
      );
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

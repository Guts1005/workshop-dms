import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bay_capture_models.dart';
import 'bay_capture_repository.dart';

final bayCaptureRepositoryProvider = Provider<BayCaptureRepository>((ref) {
  return LocalBayCaptureRepository();
});

final bayCaptureControllerProvider =
    StateNotifierProvider.autoDispose<BayCaptureController, BayCaptureState>((ref) {
  final repo = ref.watch(bayCaptureRepositoryProvider);
  return BayCaptureController(repository: repo);
});

class BayCaptureController extends StateNotifier<BayCaptureState> {
  final BayCaptureRepository repository;

  BayCaptureController({
    required this.repository,
    String? initialJobCardId,
    String? initialRegistration,
  }) : super(BayCaptureState(
          jobCardId: initialJobCardId ?? 'JC-TEMP-${DateTime.now().millisecondsSinceEpoch}',
          registrationNumber: initialRegistration ?? 'MH02CL8899',
        ));

  Future<void> initSession({required String jobCardId, required String registrationNumber}) async {
    state = state.copyWith(
      jobCardId: jobCardId,
      registrationNumber: registrationNumber,
    );
    try {
      final existingPhotos = await repository.getPhotosForJobCard(jobCardId);
      final override = await repository.getManagerOverride(jobCardId);
      state = state.copyWith(
        capturedPhotos: {...existingPhotos, ...state.capturedPhotos},
        managerOverride: override ?? state.managerOverride,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load session photos: $e');
    }
  }

  void selectShot(CheckInShotType shotType) {
    state = state.copyWith(activeShotType: shotType, clearError: true);
  }

  Future<void> recordCapturedPhoto({
    required CheckInShotType shotType,
    required String filePath,
    required String sha256Hash,
    required int fileSizeBytes,
  }) async {
    state = state.copyWith(status: BayCaptureStatus.saving, clearError: true);

    try {
      final photo = CapturedCheckInPhoto(
        shotType: shotType,
        localFilePath: filePath,
        sha256Hash: sha256Hash,
        capturedAt: DateTime.now(),
        fileSizeBytes: fileSizeBytes,
      );

      await repository.savePhoto(
        jobCardId: state.jobCardId,
        photo: photo,
      );

      final updatedMap = Map<CheckInShotType, CapturedCheckInPhoto>.from(state.capturedPhotos);
      updatedMap[shotType] = photo;

      // Determine next uncaptured mandatory shot (if any)
      CheckInShotType nextShot = shotType;
      for (final s in CheckInShotType.values) {
        if (s.isMandatory && !updatedMap.containsKey(s)) {
          nextShot = s;
          break;
        }
      }

      state = state.copyWith(
        status: BayCaptureStatus.idle,
        capturedPhotos: updatedMap,
        activeShotType: nextShot,
      );
    } catch (e) {
      state = state.copyWith(
        status: BayCaptureStatus.error,
        errorMessage: 'Failed to save photo: $e',
      );
    }
  }

  void retakeShot(CheckInShotType shotType) {
    final updatedMap = Map<CheckInShotType, CapturedCheckInPhoto>.from(state.capturedPhotos);
    updatedMap.remove(shotType);
    repository.removePhoto(jobCardId: state.jobCardId, shotType: shotType);
    state = state.copyWith(
      activeShotType: shotType,
      capturedPhotos: updatedMap,
      clearError: true,
    );
  }

  String? validateManagerOverride({
    required String authorizedBy,
    required String reason,
  }) {
    if (authorizedBy.trim().length < 2) {
      return 'Manager name or ID must be at least 2 characters';
    }
    if (reason.trim().length < 5) {
      return 'Override justification must be at least 5 characters (e.g. damaged bumper, missing plate)';
    }
    return null;
  }

  Future<bool> applyManagerOverride({
    required String authorizedBy,
    required String reason,
  }) async {
    final validationError = validateManagerOverride(
      authorizedBy: authorizedBy,
      reason: reason,
    );
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(status: BayCaptureStatus.saving, clearError: true);

    try {
      final override = ManagerOverrideRecord(
        authorizedBy: authorizedBy.trim(),
        reason: reason.trim(),
        timestamp: DateTime.now(),
        missingShots: state.missingMandatoryShots,
      );

      await repository.recordManagerOverride(
        jobCardId: state.jobCardId,
        override: override,
      );

      state = state.copyWith(
        status: BayCaptureStatus.idle,
        managerOverride: override,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: BayCaptureStatus.error,
        errorMessage: 'Failed to apply Manager Override: $e',
      );
      return false;
    }
  }

  void removeManagerOverride() {
    state = state.copyWith(clearOverride: true, clearError: true);
  }

  Future<bool> finalizeCheckIn() async {
    if (!state.canFinalizeCheckIn) {
      state = state.copyWith(
        errorMessage:
            'Gating Error: All 6 mandatory shots required (${state.mandatoryCompletedCount}/6 complete) or Manager Override authorization.',
      );
      return false;
    }

    state = state.copyWith(status: BayCaptureStatus.saving, clearError: true);

    try {
      await repository.finalizeBayCheckIn(
        jobCardId: state.jobCardId,
        override: state.managerOverride,
      );

      state = state.copyWith(status: BayCaptureStatus.completed);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: BayCaptureStatus.error,
        errorMessage: 'Failed to finalize check-in: $e',
      );
      return false;
    }
  }
}

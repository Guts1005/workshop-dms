import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:typed_data';

import 'bay_capture_models.dart';
import 'bay_capture_repository.dart';

final bayCaptureRepositoryProvider = Provider<BayCaptureRepository>((ref) {
  return SupabaseBayCaptureRepository(Supabase.instance.client);
});

final bayCaptureControllerProvider =
    StateNotifierProvider.autoDispose<BayCaptureController, BayCaptureState>((
      ref,
    ) {
      final repo = ref.watch(bayCaptureRepositoryProvider);
      return BayCaptureController(repository: repo);
    });

class BayCaptureController extends StateNotifier<BayCaptureState> {
  final BayCaptureRepository repository;

  BayCaptureController({
    required this.repository,
    String? initialJobCardId,
    String? initialRegistration,
  }) : super(
         BayCaptureState(
           jobCardId: initialJobCardId ?? '',
           registrationNumber: initialRegistration ?? '',
         ),
       );

  Future<void> initSession({
    required String jobCardId,
    required String registrationNumber,
  }) async {
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
    Uint8List? bytes,
  }) async {
    state = state.copyWith(status: BayCaptureStatus.saving, clearError: true);

    try {
      final photo = CapturedCheckInPhoto(
        shotType: shotType,
        localFilePath: filePath,
        sha256Hash: sha256Hash,
        capturedAt: DateTime.now(),
        fileSizeBytes: fileSizeBytes,
        bytes: bytes,
      );

      final savedPhoto = await repository.savePhoto(
        jobCardId: state.jobCardId,
        photo: photo,
      );

      final updatedMap = Map<CheckInShotType, CapturedCheckInPhoto>.from(
        state.capturedPhotos,
      );
      updatedMap[shotType] = savedPhoto;

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

  Future<void> retakeShot(CheckInShotType shotType) async {
    try {
      await repository.removePhoto(
        jobCardId: state.jobCardId,
        shotType: shotType,
      );
      final updatedMap = Map<CheckInShotType, CapturedCheckInPhoto>.from(
        state.capturedPhotos,
      )..remove(shotType);
      state = state.copyWith(
        activeShotType: shotType,
        capturedPhotos: updatedMap,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: BayCaptureStatus.error,
        errorMessage: 'Could not remove the saved photo: $error',
      );
    }
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
        errorMessage: state.status == BayCaptureStatus.saving
            ? 'Check-in is already being saved.'
            : 'Capture all mandatory photos or record a manager override before continuing.',
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

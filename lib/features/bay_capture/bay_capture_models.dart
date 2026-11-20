import 'package:crypto/crypto.dart';

import 'dart:typed_data';

enum CheckInShotType {
  frontLeft45(
    'FRONT-LEFT 45° CORNER (HERO)',
    true,
    'Align front bumper and driver side along guide',
  ),
  frontRight45(
    'FRONT-RIGHT 45° CORNER',
    true,
    'Align front bumper and passenger side along guide',
  ),
  rearLeft45(
    'REAR-LEFT 45° CORNER',
    true,
    'Align rear bumper and driver side along guide',
  ),
  rearRight45(
    'REAR-RIGHT 45° CORNER',
    true,
    'Align rear bumper and passenger side along guide',
  ),
  plateCloseup(
    'NUMBER PLATE CLOSE-UP',
    true,
    'Center license plate inside the target box',
  ),
  odometerReading(
    'ODOMETER / CLUSTER',
    true,
    'Focus on odometer digits with ignition ON',
  ),
  dashboardCluster(
    'DASHBOARD WARNING LIGHTS (OPTIONAL)',
    false,
    'Capture instrument cluster with engine idling',
  ),
  vinPlate(
    'VIN / B-PILLAR CODE (OPTIONAL)',
    false,
    'Capture manufacturer compliance plate',
  );

  final String title;
  final bool isMandatory;
  final String instruction;

  const CheckInShotType(this.title, this.isMandatory, this.instruction);
}

class CapturedCheckInPhoto {
  final CheckInShotType shotType;
  final String localFilePath;
  final String sha256Hash;
  final DateTime capturedAt;
  final int fileSizeBytes;
  final Uint8List? bytes;

  const CapturedCheckInPhoto({
    required this.shotType,
    required this.localFilePath,
    required this.sha256Hash,
    required this.capturedAt,
    required this.fileSizeBytes,
    this.bytes,
  });

  static String computeHash(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> toJson() => {
    'shotType': shotType.name,
    'localFilePath': localFilePath,
    'sha256Hash': sha256Hash,
    'capturedAt': capturedAt.toIso8601String(),
    'fileSizeBytes': fileSizeBytes,
  };

  factory CapturedCheckInPhoto.fromJson(Map<String, dynamic> json) {
    return CapturedCheckInPhoto(
      shotType: CheckInShotType.values.firstWhere(
        (e) => e.name == json['shotType'],
      ),
      localFilePath: json['localFilePath'] as String,
      sha256Hash: json['sha256Hash'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      fileSizeBytes: json['fileSizeBytes'] as int,
    );
  }
}

class ManagerOverrideRecord {
  final String authorizedBy;
  final String reason;
  final DateTime timestamp;
  final List<CheckInShotType> missingShots;

  const ManagerOverrideRecord({
    required this.authorizedBy,
    required this.reason,
    required this.timestamp,
    required this.missingShots,
  });

  Map<String, dynamic> toJson() => {
    'authorizedBy': authorizedBy,
    'reason': reason,
    'timestamp': timestamp.toIso8601String(),
    'missingShots': missingShots.map((s) => s.name).toList(),
  };

  factory ManagerOverrideRecord.fromJson(Map<String, dynamic> json) {
    return ManagerOverrideRecord(
      authorizedBy: json['authorizedBy'] as String,
      reason: json['reason'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      missingShots: (json['missingShots'] as List<dynamic>)
          .map(
            (name) => CheckInShotType.values.firstWhere((s) => s.name == name),
          )
          .toList(),
    );
  }
}

enum BayCaptureStatus { idle, capturing, reviewing, saving, completed, error }

class BayCaptureState {
  final String jobCardId;
  final String registrationNumber;
  final CheckInShotType activeShotType;
  final Map<CheckInShotType, CapturedCheckInPhoto> capturedPhotos;
  final ManagerOverrideRecord? managerOverride;
  final BayCaptureStatus status;
  final String? errorMessage;

  const BayCaptureState({
    this.jobCardId = '',
    this.registrationNumber = '',
    this.activeShotType = CheckInShotType.frontLeft45,
    this.capturedPhotos = const {},
    this.managerOverride,
    this.status = BayCaptureStatus.idle,
    this.errorMessage,
  });

  int get mandatoryCompletedCount {
    return CheckInShotType.values
        .where((shot) => shot.isMandatory && capturedPhotos.containsKey(shot))
        .length;
  }

  int get totalMandatoryCount {
    return CheckInShotType.values.where((shot) => shot.isMandatory).length;
  }

  bool get isAllMandatoryCaptured =>
      mandatoryCompletedCount == totalMandatoryCount;

  bool get isOverrideActive => managerOverride != null;

  /// Let the advisor continue when a camera or vehicle access is unavailable.
  /// Any missing shots stay visible as incomplete follow-up work.
  bool get canFinalizeCheckIn => true;

  List<CheckInShotType> get missingMandatoryShots {
    return CheckInShotType.values
        .where((shot) => shot.isMandatory && !capturedPhotos.containsKey(shot))
        .toList();
  }

  BayCaptureState copyWith({
    String? jobCardId,
    String? registrationNumber,
    CheckInShotType? activeShotType,
    Map<CheckInShotType, CapturedCheckInPhoto>? capturedPhotos,
    ManagerOverrideRecord? managerOverride,
    bool clearOverride = false,
    BayCaptureStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BayCaptureState(
      jobCardId: jobCardId ?? this.jobCardId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      activeShotType: activeShotType ?? this.activeShotType,
      capturedPhotos: capturedPhotos ?? this.capturedPhotos,
      managerOverride: clearOverride
          ? null
          : (managerOverride ?? this.managerOverride),
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

import 'package:crypto/crypto.dart';

enum CheckInShotType {
  frontLeft45('FRONT-LEFT 45° CORNER (HERO)', true, 'Align front bumper and driver side along guide'),
  frontRight45('FRONT-RIGHT 45° CORNER', true, 'Align front bumper and passenger side along guide'),
  rearLeft45('REAR-LEFT 45° CORNER', true, 'Align rear bumper and driver side along guide'),
  rearRight45('REAR-RIGHT 45° CORNER', true, 'Align rear bumper and passenger side along guide'),
  plateCloseup('NUMBER PLATE CLOSE-UP', true, 'Center license plate inside the target box'),
  odometerReading('ODOMETER / CLUSTER', true, 'Focus on odometer digits with ignition ON'),
  dashboardCluster('DASHBOARD WARNING LIGHTS (OPTIONAL)', false, 'Capture instrument cluster with engine idling'),
  vinPlate('VIN / B-PILLAR CODE (OPTIONAL)', false, 'Capture manufacturer compliance plate');

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

  const CapturedCheckInPhoto({
    required this.shotType,
    required this.localFilePath,
    required this.sha256Hash,
    required this.capturedAt,
    required this.fileSizeBytes,
  });

  static String computeHash(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}

class BayCheckInSession {
  final String jobCardTempId;
  final Map<CheckInShotType, CapturedCheckInPhoto> capturedPhotos = {};

  BayCheckInSession({required this.jobCardTempId});

  bool get isComplete {
    return CheckInShotType.values
        .where((shot) => shot.isMandatory)
        .every((shot) => capturedPhotos.containsKey(shot));
  }

  int get mandatoryCompletedCount {
    return CheckInShotType.values
        .where((shot) => shot.isMandatory && capturedPhotos.containsKey(shot))
        .length;
  }

  int get totalMandatoryCount {
    return CheckInShotType.values.where((shot) => shot.isMandatory).length;
  }
}

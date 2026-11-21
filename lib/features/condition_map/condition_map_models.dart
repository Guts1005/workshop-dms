import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

enum ConditionViewDirection {
  sideLeft('LEFT PROFILE'),
  sideRight('RIGHT PROFILE'),
  front('FRONT NOSE'),
  rear('REAR TAIL'),
  top('ROOF / TOP');

  final String label;
  const ConditionViewDirection(this.label);
}

enum DefectType {
  dent('DENT'),
  deepScratch('DEEP SCRATCH'),
  surfaceScuff('SURFACE SCUFF'),
  paintChip('PAINT CHIP'),
  glassCrack('GLASS CRACK'),
  rust('RUST / CORROSION'),
  misalignedPanel('PANEL GAP / MISALIGNMENT'),
  missingPart('MISSING TRIM / BADGE');

  final String label;
  const DefectType(this.label);
}

enum DefectSeverity {
  minor('LEVEL 1 - MINOR', Color(0xFF2E6B3F)),
  moderate('LEVEL 2 - MODERATE', Color(0xFFF8A348)),
  severe('LEVEL 3 - SEVERE', Color(0xFFDB4A2B));

  final String label;
  final Color accentColor;
  const DefectSeverity(this.label, this.accentColor);
}

class ConditionPin {
  final int id;
  final ConditionViewDirection view;
  final double normalizedX; // 0.0 to 1.0 relative to canvas width
  final double normalizedY; // 0.0 to 1.0 relative to canvas height
  final DefectType type;
  final DefectSeverity severity;
  final String? note;
  final String? photoPath;
  final String? photoHash;
  final DateTime createdAt;

  const ConditionPin({
    required this.id,
    required this.view,
    required this.normalizedX,
    required this.normalizedY,
    required this.type,
    required this.severity,
    this.note,
    this.photoPath,
    this.photoHash,
    required this.createdAt,
  });

  Offset get relativeOffset => Offset(normalizedX, normalizedY);

  ConditionPin copyWith({
    int? id,
    ConditionViewDirection? view,
    double? normalizedX,
    double? normalizedY,
    DefectType? type,
    DefectSeverity? severity,
    String? note,
    String? photoPath,
    String? photoHash,
    DateTime? createdAt,
  }) {
    return ConditionPin(
      id: id ?? this.id,
      view: view ?? this.view,
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      photoHash: photoHash ?? this.photoHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'view': view.name,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
    'type': type.name,
    'severity': severity.name,
    'note': note,
    'photoPath': photoPath,
    'photoHash': photoHash,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ConditionPin.fromJson(Map<String, dynamic> json) => ConditionPin(
    id: json['id'] as int,
    view: ConditionViewDirection.values.firstWhere(
      (v) => v.name == json['view'],
    ),
    normalizedX: (json['normalizedX'] as num).toDouble(),
    normalizedY: (json['normalizedY'] as num).toDouble(),
    type: DefectType.values.firstWhere((t) => t.name == json['type']),
    severity: DefectSeverity.values.firstWhere(
      (s) => s.name == json['severity'],
    ),
    note: json['note'] as String?,
    photoPath: json['photoPath'] as String?,
    photoHash: json['photoHash'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class PreWorkSignOff {
  final String customerName;
  final String customerPhone;
  final String advisorName;
  final DateTime signedAt;
  final bool customerAcknowledged;
  final String sha256Checksum;

  const PreWorkSignOff({
    required this.customerName,
    required this.customerPhone,
    required this.advisorName,
    required this.signedAt,
    required this.customerAcknowledged,
    required this.sha256Checksum,
  });

  static String generateChecksum({
    required String jobCardId,
    required String registrationNumber,
    required List<ConditionPin> pins,
    required String customerPhone,
    required DateTime timestamp,
  }) {
    final canonicalPins = pins.toList()
      ..sort((first, second) => first.id.compareTo(second.id));
    final payload = jsonEncode({
      'jobCardId': jobCardId,
      'registrationNumber': registrationNumber,
      'customerPhone': customerPhone,
      'signedAt': timestamp.toUtc().toIso8601String(),
      'findings': canonicalPins
          .map(
            (pin) => {
              'id': pin.id,
              'area': pin.view.name,
              'type': pin.type.name,
              'severity': pin.severity.name,
              'x': pin.normalizedX,
              'y': pin.normalizedY,
              'note': pin.note,
              'photoPath': pin.photoPath,
            },
          )
          .toList(),
    });

    return sha256.convert(utf8.encode(payload)).toString();
  }

  Map<String, dynamic> toJson() => {
    'customerName': customerName,
    'customerPhone': customerPhone,
    'advisorName': advisorName,
    'signedAt': signedAt.toIso8601String(),
    'customerAcknowledged': customerAcknowledged,
    'sha256Checksum': sha256Checksum,
  };

  factory PreWorkSignOff.fromJson(Map<String, dynamic> json) => PreWorkSignOff(
    customerName: json['customerName'] as String,
    customerPhone: json['customerPhone'] as String,
    advisorName: json['advisorName'] as String,
    signedAt: DateTime.parse(json['signedAt'] as String),
    customerAcknowledged: json['customerAcknowledged'] as bool,
    sha256Checksum: json['sha256Checksum'] as String,
  );
}

enum ConditionMapStatus { idle, saving, completed, error }

class ConditionMapState {
  final String jobCardId;
  final String registrationNumber;
  final ConditionViewDirection activeView;
  final List<ConditionPin> pins;
  final Set<ConditionViewDirection> reviewedViews;
  final ConditionPin? selectedPin;
  final PreWorkSignOff? signOff;
  final ConditionMapStatus status;
  final String? errorMessage;

  const ConditionMapState({
    required this.jobCardId,
    required this.registrationNumber,
    this.activeView = ConditionViewDirection.sideLeft,
    this.pins = const [],
    this.reviewedViews = const {},
    this.selectedPin,
    this.signOff,
    this.status = ConditionMapStatus.idle,
    this.errorMessage,
  });

  bool get isLocked => signOff != null;
  int get totalPinCount => pins.length;
  int get reviewedCount => reviewedViews.length;

  int get severeCount =>
      pins.where((p) => p.severity == DefectSeverity.severe).length;
  int get moderateCount =>
      pins.where((p) => p.severity == DefectSeverity.moderate).length;
  int get minorCount =>
      pins.where((p) => p.severity == DefectSeverity.minor).length;

  List<ConditionPin> get activeViewPins =>
      pins.where((p) => p.view == activeView).toList();

  ConditionMapState copyWith({
    String? jobCardId,
    String? registrationNumber,
    ConditionViewDirection? activeView,
    List<ConditionPin>? pins,
    Set<ConditionViewDirection>? reviewedViews,
    ConditionPin? selectedPin,
    bool clearSelectedPin = false,
    PreWorkSignOff? signOff,
    ConditionMapStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConditionMapState(
      jobCardId: jobCardId ?? this.jobCardId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      activeView: activeView ?? this.activeView,
      pins: pins ?? this.pins,
      reviewedViews: reviewedViews ?? this.reviewedViews,
      selectedPin: clearSelectedPin ? null : (selectedPin ?? this.selectedPin),
      signOff: signOff ?? this.signOff,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

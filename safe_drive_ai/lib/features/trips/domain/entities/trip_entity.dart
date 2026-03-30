import 'package:equatable/equatable.dart';

enum TripType { normal, relocation, free }

enum TripStatus {
  // Viajes de empresa
  scheduled,
  inProgress,
  pendingApproval,
  approved,
  cancelled,
  withImpediment,
  // Viajes libres
  completed,
}

enum ImpedimentCategory {
  flatTire,
  weather,
  accident,
  mechanical,
  other,
}

extension ImpedimentCategoryLabel on ImpedimentCategory {
  String get label {
    switch (this) {
      case ImpedimentCategory.flatTire:
        return 'Llanta pinchada';
      case ImpedimentCategory.weather:
        return 'Condiciones climáticas';
      case ImpedimentCategory.accident:
        return 'Accidente de tránsito';
      case ImpedimentCategory.mechanical:
        return 'Falla mecánica';
      case ImpedimentCategory.other:
        return 'Otro';
    }
  }
}

class TripEntity extends Equatable {
  const TripEntity({
    required this.id,
    required this.driverId,
    required this.tripType,
    required this.status,
    required this.hasCameraPermission,
    this.companyId,
    this.companyName,
    this.originLat,
    this.originLng,
    this.originAddress,
    this.destinationLat,
    this.destinationLng,
    this.destinationAddress,
    this.scheduledDepartureTime,
    this.estimatedArrivalTime,
    this.actualStartTime,
    this.actualEndTime,
    this.impedimentCategory,
    this.impedimentDescription,
    this.impedimentReportedAt,
    this.sequenceOrder,
    this.tripCode,
  });

  final String id;
  final String driverId;
  final TripType tripType;
  final TripStatus status;
  final bool hasCameraPermission;

  // Company trip fields
  final String? companyId;
  final String? companyName;

  // Route
  final double? originLat;
  final double? originLng;
  final String? originAddress;

  // Trip code (user-friendly ID)
  final String? tripCode;
  final double? destinationLat;
  final double? destinationLng;
  final String? destinationAddress;

  // Scheduling
  final DateTime? scheduledDepartureTime;
  final DateTime? estimatedArrivalTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  // Impediment
  final ImpedimentCategory? impedimentCategory;
  final String? impedimentDescription;
  final DateTime? impedimentReportedAt;

  // Sequence
  final int? sequenceOrder;

  // ── Computed ────────────────────────────────────────────────────────────────

  bool get isCompanyTrip => tripType != TripType.free;
  bool get isFreeTrip => tripType == TripType.free;
  bool get isRelocation => tripType == TripType.relocation;

  bool get hasOrigin => originLat != null && originLng != null;
  bool get hasDestination => destinationLat != null && destinationLng != null;

  bool get canBeStarted =>
      status == TripStatus.scheduled &&
      impedimentCategory == null;

  bool get isActive => status == TripStatus.inProgress;

  Duration get elapsed {
    final start = actualStartTime;
    if (start == null) return Duration.zero;
    final end = actualEndTime ?? DateTime.now();
    return end.difference(start);
  }

  TripEntity copyWith({
    String? id,
    String? driverId,
    TripType? tripType,
    TripStatus? status,
    bool? hasCameraPermission,
    String? companyId,
    String? companyName,
    double? originLat,
    double? originLng,
    String? originAddress,
    double? destinationLat,
    double? destinationLng,
    String? destinationAddress,
    DateTime? scheduledDepartureTime,
    DateTime? estimatedArrivalTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    ImpedimentCategory? impedimentCategory,
    String? impedimentDescription,
    DateTime? impedimentReportedAt,
    int? sequenceOrder,
    String? tripCode,
  }) {
    return TripEntity(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      tripType: tripType ?? this.tripType,
      status: status ?? this.status,
      hasCameraPermission: hasCameraPermission ?? this.hasCameraPermission,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      originAddress: originAddress ?? this.originAddress,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      scheduledDepartureTime:
          scheduledDepartureTime ?? this.scheduledDepartureTime,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      impedimentCategory: impedimentCategory ?? this.impedimentCategory,
      impedimentDescription:
          impedimentDescription ?? this.impedimentDescription,
      impedimentReportedAt: impedimentReportedAt ?? this.impedimentReportedAt,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      tripCode: tripCode ?? this.tripCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        tripType,
        status,
        hasCameraPermission,
        companyId,
        companyName,
        originLat,
        originLng,
        originAddress,
        destinationLat,
        destinationLng,
        destinationAddress,
        scheduledDepartureTime,
        estimatedArrivalTime,
        actualStartTime,
        actualEndTime,
        impedimentCategory,
        impedimentDescription,
        impedimentReportedAt,
        sequenceOrder,
        tripCode,
      ];
}

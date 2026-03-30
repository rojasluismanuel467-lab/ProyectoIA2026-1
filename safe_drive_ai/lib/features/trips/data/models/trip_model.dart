import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/trip_entity.dart';

class TripModel extends TripEntity {
  const TripModel({
    required super.id,
    required super.driverId,
    required super.tripType,
    required super.status,
    required super.hasCameraPermission,
    super.companyId,
    super.companyName,
    super.originLat,
    super.originLng,
    super.originAddress,
    super.destinationLat,
    super.destinationLng,
    super.destinationAddress,
    super.scheduledDepartureTime,
    super.estimatedArrivalTime,
    super.actualStartTime,
    super.actualEndTime,
    super.impedimentCategory,
    super.impedimentDescription,
    super.impedimentReportedAt,
    super.sequenceOrder,
    super.tripCode,
  });

  factory TripModel.fromMap(String id, Map<String, dynamic> map) {
    return TripModel(
      id: id,
      driverId: map['driverId'] as String,
      tripType: _parseTripType(map['tripType'] as String?),
      status: _parseTripStatus(map['status'] as String?),
      hasCameraPermission: map['hasCameraPermission'] as bool? ?? false,
      companyId: map['companyId'] as String?,
      companyName: map['companyName'] as String?,
      originLat: (map['originLat'] as num?)?.toDouble(),
      originLng: (map['originLng'] as num?)?.toDouble(),
      originAddress: map['originAddress'] as String?,
      destinationLat: (map['destinationLat'] as num?)?.toDouble(),
      destinationLng: (map['destinationLng'] as num?)?.toDouble(),
      destinationAddress: map['destinationAddress'] as String?,
      scheduledDepartureTime: map['scheduledDepartureTime'] != null
          ? (map['scheduledDepartureTime'] as Timestamp).toDate()
          : null,
      estimatedArrivalTime: map['estimatedArrivalTime'] != null
          ? (map['estimatedArrivalTime'] as Timestamp).toDate()
          : null,
      actualStartTime: map['actualStartTime'] != null
          ? (map['actualStartTime'] as Timestamp).toDate()
          : null,
      actualEndTime: map['actualEndTime'] != null
          ? (map['actualEndTime'] as Timestamp).toDate()
          : null,
      impedimentCategory:
          _parseImpedimentCategory(map['impedimentCategory'] as String?),
      impedimentDescription: map['impedimentDescription'] as String?,
      impedimentReportedAt: map['impedimentReportedAt'] != null
          ? (map['impedimentReportedAt'] as Timestamp).toDate()
          : null,
      sequenceOrder: map['sequenceOrder'] as int?,
      tripCode: map['tripCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'tripType': _tripTypeToString(tripType),
      'status': _tripStatusToString(status),
      'hasCameraPermission': hasCameraPermission,
      if (companyId != null) 'companyId': companyId,
      if (companyName != null) 'companyName': companyName,
      if (originLat != null) 'originLat': originLat,
      if (originLng != null) 'originLng': originLng,
      if (originAddress != null) 'originAddress': originAddress,
      if (destinationLat != null) 'destinationLat': destinationLat,
      if (destinationLng != null) 'destinationLng': destinationLng,
      if (destinationAddress != null) 'destinationAddress': destinationAddress,
      if (scheduledDepartureTime != null)
        'scheduledDepartureTime': Timestamp.fromDate(scheduledDepartureTime!),
      if (estimatedArrivalTime != null)
        'estimatedArrivalTime': Timestamp.fromDate(estimatedArrivalTime!),
      if (actualStartTime != null)
        'actualStartTime': Timestamp.fromDate(actualStartTime!),
      if (actualEndTime != null)
        'actualEndTime': Timestamp.fromDate(actualEndTime!),
      if (impedimentCategory != null)
        'impedimentCategory': _impedimentCategoryToString(impedimentCategory!),
      if (impedimentDescription != null)
        'impedimentDescription': impedimentDescription,
      if (impedimentReportedAt != null)
        'impedimentReportedAt': Timestamp.fromDate(impedimentReportedAt!),
      if (sequenceOrder != null) 'sequenceOrder': sequenceOrder,
      if (tripCode != null) 'tripCode': tripCode,
    };
  }

  // ── Parsers ──────────────────────────────────────────────────────────────────

  static TripType _parseTripType(String? value) {
    switch (value) {
      case 'relocation':
        return TripType.relocation;
      case 'free':
        return TripType.free;
      default:
        return TripType.normal;
    }
  }

  static String _tripTypeToString(TripType type) {
    switch (type) {
      case TripType.relocation:
        return 'relocation';
      case TripType.free:
        return 'free';
      case TripType.normal:
        return 'normal';
    }
  }

  static TripStatus _parseTripStatus(String? value) {
    switch (value) {
      case 'scheduled':
        return TripStatus.scheduled;
      case 'inProgress':
        return TripStatus.inProgress;
      case 'pendingApproval':
        return TripStatus.pendingApproval;
      case 'approved':
        return TripStatus.approved;
      case 'cancelled':
        return TripStatus.cancelled;
      case 'withImpediment':
        return TripStatus.withImpediment;
      case 'completed':
        return TripStatus.completed;
      default:
        return TripStatus.scheduled;
    }
  }

  static String _tripStatusToString(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
        return 'scheduled';
      case TripStatus.inProgress:
        return 'inProgress';
      case TripStatus.pendingApproval:
        return 'pendingApproval';
      case TripStatus.approved:
        return 'approved';
      case TripStatus.cancelled:
        return 'cancelled';
      case TripStatus.withImpediment:
        return 'withImpediment';
      case TripStatus.completed:
        return 'completed';
    }
  }

  static ImpedimentCategory? _parseImpedimentCategory(String? value) {
    switch (value) {
      case 'flatTire':
        return ImpedimentCategory.flatTire;
      case 'weather':
        return ImpedimentCategory.weather;
      case 'accident':
        return ImpedimentCategory.accident;
      case 'mechanical':
        return ImpedimentCategory.mechanical;
      case 'other':
        return ImpedimentCategory.other;
      default:
        return null;
    }
  }

  static String _impedimentCategoryToString(ImpedimentCategory cat) {
    switch (cat) {
      case ImpedimentCategory.flatTire:
        return 'flatTire';
      case ImpedimentCategory.weather:
        return 'weather';
      case ImpedimentCategory.accident:
        return 'accident';
      case ImpedimentCategory.mechanical:
        return 'mechanical';
      case ImpedimentCategory.other:
        return 'other';
    }
  }
}

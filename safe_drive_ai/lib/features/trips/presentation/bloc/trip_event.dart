import 'package:equatable/equatable.dart';

import '../../domain/entities/trip_entity.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

/// Carga los viajes scheduled del conductor y verifica si hay uno en progreso.
class LoadDriverTrips extends TripEvent {
  const LoadDriverTrips({required this.driverId});
  final String driverId;

  @override
  List<Object?> get props => [driverId];
}

/// Inicia un viaje de empresa (scheduled → inProgress).
class StartTrip extends TripEvent {
  const StartTrip({
    required this.tripId,
    required this.hasCameraPermission,
  });
  final String tripId;
  final bool hasCameraPermission;

  @override
  List<Object?> get props => [tripId, hasCameraPermission];
}

/// Finaliza el viaje de empresa activo (inProgress → pendingApproval).
class EndTrip extends TripEvent {
  const EndTrip({required this.tripId});
  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// Inicia un viaje libre (crea nuevo trip free + inProgress).
class StartFreeTrip extends TripEvent {
  const StartFreeTrip({
    required this.driverId,
    required this.hasCameraPermission,
  });
  final String driverId;
  final bool hasCameraPermission;

  @override
  List<Object?> get props => [driverId, hasCameraPermission];
}

/// Finaliza el viaje libre activo (inProgress → completed).
class EndFreeTrip extends TripEvent {
  const EndFreeTrip({required this.tripId});
  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// El conductor reporta un impedimento en el viaje activo.
class ReportImpediment extends TripEvent {
  const ReportImpediment({
    required this.tripId,
    required this.category,
    this.description,
  });
  final String tripId;
  final ImpedimentCategory category;
  final String? description;

  @override
  List<Object?> get props => [tripId, category, description];
}

/// Tick interno del timer (cada segundo).
class TripTick extends TripEvent {
  const TripTick();
}

/// Actualización de posición GPS.
class TripLocationUpdated extends TripEvent {
  const TripLocationUpdated({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}

/// Carga el historial de viajes terminados del conductor.
class LoadDriverTripHistory extends TripEvent {
  const LoadDriverTripHistory({required this.driverId});
  final String driverId;

  @override
  List<Object?> get props => [driverId];
}

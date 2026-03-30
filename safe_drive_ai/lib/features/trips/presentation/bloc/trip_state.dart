import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/trip_entity.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cualquier carga.
class TripInitial extends TripState {
  const TripInitial();
}

/// Operación asíncrona en progreso.
class TripLoading extends TripState {
  const TripLoading();
}

/// Lista de viajes scheduled cargada; no hay viaje en progreso.
class TripListLoaded extends TripState {
  const TripListLoaded({
    required this.scheduledTrips,
    this.hasActiveImpediment = false,
  });

  final List<TripEntity> scheduledTrips;

  /// true si alguno de los viajes está en estado withImpediment — bloquea el inicio.
  final bool hasActiveImpediment;

  @override
  List<Object?> get props => [scheduledTrips, hasActiveImpediment];
}

/// Hay un viaje de empresa en progreso.
class TripInProgress extends TripState {
  const TripInProgress({
    required this.trip,
    required this.elapsed,
    this.route = const [],
    this.isNewlyStarted = false,
  });

  final TripEntity trip;
  final Duration elapsed;
  final List<LatLng> route;

  /// true solo en la primera emisión al iniciar — abre el mapa automáticamente.
  final bool isNewlyStarted;

  TripInProgress copyWith({
    TripEntity? trip,
    Duration? elapsed,
    List<LatLng>? route,
  }) {
    return TripInProgress(
      trip: trip ?? this.trip,
      elapsed: elapsed ?? this.elapsed,
      route: route ?? this.route,
      isNewlyStarted: false,
    );
  }

  @override
  List<Object?> get props => [trip, elapsed, route, isNewlyStarted];
}

/// El conductor finalizó el viaje de empresa; espera aprobación.
class TripPendingApproval extends TripState {
  const TripPendingApproval({required this.trip});
  final TripEntity trip;

  @override
  List<Object?> get props => [trip];
}

/// El conductor reportó un impedimento.
class TripWithImpediment extends TripState {
  const TripWithImpediment({required this.trip});
  final TripEntity trip;

  @override
  List<Object?> get props => [trip];
}

/// Hay un viaje libre en progreso.
class FreeTripInProgress extends TripState {
  const FreeTripInProgress({
    required this.trip,
    required this.elapsed,
    this.route = const [],
    this.isNewlyStarted = false,
  });

  final TripEntity trip;
  final Duration elapsed;
  final List<LatLng> route;
  final bool isNewlyStarted;

  FreeTripInProgress copyWith({
    TripEntity? trip,
    Duration? elapsed,
    List<LatLng>? route,
  }) {
    return FreeTripInProgress(
      trip: trip ?? this.trip,
      elapsed: elapsed ?? this.elapsed,
      route: route ?? this.route,
      isNewlyStarted: false,
    );
  }

  @override
  List<Object?> get props => [trip, elapsed, route, isNewlyStarted];
}

/// No hay nada en curso (estado neutro para el conductor).
class TripIdle extends TripState {
  const TripIdle();
}

/// El viaje terminó (empresa aprobó o viaje libre completado).
class TripEnded extends TripState {
  const TripEnded({required this.trip});
  final TripEntity trip;

  @override
  List<Object?> get props => [trip];
}

/// Error genérico del módulo de viajes.
class TripError extends TripState {
  const TripError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Historial de viajes terminados del conductor cargado correctamente.
/// La lista puede estar vacía si el conductor no tiene viajes finalizados.
class TripHistoryLoaded extends TripState {
  const TripHistoryLoaded({required this.trips});
  final List<TripEntity> trips;

  @override
  List<Object?> get props => [trips];
}

/// Estado de carga exclusivo para el historial, para no interferir con el
/// [TripLoading] que usan los demás flujos.
class TripHistoryLoading extends TripState {
  const TripHistoryLoading();
}

/// Error exclusivo para la carga del historial.
class TripHistoryError extends TripState {
  const TripHistoryError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

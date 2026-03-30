import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/route_point_entity.dart';
import '../entities/trip_entity.dart';

abstract class TripRepository {
  // ── Conductor: viajes programados ──────────────────────────────────────────

  /// Retorna todos los viajes `scheduled` del conductor ordenados por
  /// [scheduledDepartureTime] ascendente.
  Future<Either<Failure, List<TripEntity>>> getDriverScheduledTrips(
    String driverId,
  );

  /// Retorna el viaje actualmente `inProgress` del conductor, o null si no hay.
  Future<Either<Failure, TripEntity?>> getActiveTrip(String driverId);

  /// Inicia un viaje `scheduled` (empresa) — cambia a `inProgress`.
  Future<Either<Failure, TripEntity>> startTrip({
    required String tripId,
    required bool hasCameraPermission,
  });

  /// Finaliza un viaje `inProgress` de empresa — cambia a `pendingApproval`.
  Future<Either<Failure, TripEntity>> endCompanyTrip(String tripId);

  // ── Conductor: viaje libre ──────────────────────────────────────────────────

  /// Crea y arranca un viaje libre (`free` + `inProgress`).
  Future<Either<Failure, TripEntity>> startFreeTrip({
    required String driverId,
    required bool hasCameraPermission,
  });

  /// Finaliza un viaje libre — cambia a `completed`.
  Future<Either<Failure, TripEntity>> endFreeTrip(String tripId);

  // ── Conductor: impedimento ──────────────────────────────────────────────────

  /// Reporta un impedimento en un viaje `scheduled` o `inProgress`.
  Future<Either<Failure, TripEntity>> reportImpediment({
    required String tripId,
    required ImpedimentCategory category,
    String? description,
  });

  // ── Empresa ─────────────────────────────────────────────────────────────────

  /// Aprueba un viaje en estado `pendingApproval` — cambia a `approved`.
  Future<Either<Failure, void>> approveTrip(String tripId);

  /// Cancela un viaje (solo empresa) — cambia a `cancelled`.
  Future<Either<Failure, void>> cancelTrip(String tripId);

  /// Resuelve un impedimento activo — vuelve a `scheduled`.
  Future<Either<Failure, void>> resolveImpediment(String tripId);

  /// Crea un viaje de empresa para un conductor.
  Future<Either<Failure, TripEntity>> createCompanyTrip({
    required String companyId,
    required String driverId,
    required TripType tripType,
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    required DateTime scheduledDepartureTime,
    required DateTime estimatedArrivalTime,
  });

  /// Retorna todos los viajes `pendingApproval` de los conductores de la empresa.
  Future<Either<Failure, List<TripEntity>>> getCompanyPendingApprovalTrips(
    String companyId,
  );

  /// Retorna todos los viajes `withImpediment` de los conductores de la empresa.
  Future<Either<Failure, List<TripEntity>>> getCompanyImpedimentTrips(
    String companyId,
  );

  // ── Ruta GPS ─────────────────────────────────────────────────────────────────

  Future<Either<Failure, void>> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, List<RoutePointEntity>>> getTripRoute(String tripId);

  Future<Either<Failure, List<TripEntity>>> getDriverTrips(String driverId);

  /// Retorna hasta 50 viajes terminados del conductor (approved / cancelled /
  /// completed), ordenados por actualEndTime descendente.
  Future<Either<Failure, List<TripEntity>>> getDriverTripHistory(
    String driverId,
  );
}

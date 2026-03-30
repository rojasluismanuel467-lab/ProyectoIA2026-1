import '../models/route_point_model.dart';
import '../models/trip_model.dart';
import '../../domain/entities/trip_entity.dart';

abstract class TripDatasource {
  // ── Conductor: viajes programados ──────────────────────────────────────────
  Future<List<TripModel>> getDriverScheduledTrips(String driverId);
  Future<TripModel?> getActiveTrip(String driverId);
  Future<TripModel> startTrip({
    required String tripId,
    required bool hasCameraPermission,
  });
  Future<TripModel> endCompanyTrip(String tripId);

  // ── Conductor: viaje libre ──────────────────────────────────────────────────
  Future<TripModel> startFreeTrip({
    required String driverId,
    required bool hasCameraPermission,
  });
  Future<TripModel> endFreeTrip(String tripId);

  // ── Conductor: impedimento ──────────────────────────────────────────────────
  Future<TripModel> reportImpediment({
    required String tripId,
    required ImpedimentCategory category,
    String? description,
  });

  // ── Empresa ─────────────────────────────────────────────────────────────────
  Future<void> approveTrip(String tripId);
  Future<void> cancelTrip(String tripId);
  Future<void> resolveImpediment(String tripId);
  Future<TripModel> createCompanyTrip({
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
    String? companyName,
  });
  Future<List<TripModel>> getCompanyPendingApprovalTrips(String companyId);
  Future<List<TripModel>> getCompanyImpedimentTrips(String companyId);

  // ── Ruta GPS ─────────────────────────────────────────────────────────────────
  Future<void> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  });
  Future<List<RoutePointModel>> getTripRoute(String tripId);
  Future<List<TripModel>> getDriverTrips(String driverId);

  /// Retorna hasta 50 viajes terminados del conductor (approved / cancelled /
  /// completed), ordenados por actualEndTime descendente.
  Future<List<TripModel>> getDriverTripHistory(String driverId);
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/route_point_entity.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  const TripRepositoryImpl(this._datasource);

  final TripDatasource _datasource;

  // ── Conductor: viajes programados ──────────────────────────────────────────

  @override
  Future<Either<Failure, List<TripEntity>>> getDriverScheduledTrips(
      String driverId) async {
    try {
      final trips = await _datasource.getDriverScheduledTrips(driverId);
      return Right(trips);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity?>> getActiveTrip(String driverId) async {
    try {
      final trip = await _datasource.getActiveTrip(driverId);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> startTrip({
    required String tripId,
    required bool hasCameraPermission,
  }) async {
    try {
      final trip = await _datasource.startTrip(
        tripId: tripId,
        hasCameraPermission: hasCameraPermission,
      );
      return Right(trip);
    } on TripAlreadyActiveException {
      return const Left(TripAlreadyActiveFailure());
    } on DocumentNotFoundException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> endCompanyTrip(String tripId) async {
    try {
      final trip = await _datasource.endCompanyTrip(tripId);
      return Right(trip);
    } on DocumentNotFoundException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Conductor: viaje libre ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, TripEntity>> startFreeTrip({
    required String driverId,
    required bool hasCameraPermission,
  }) async {
    try {
      final trip = await _datasource.startFreeTrip(
        driverId: driverId,
        hasCameraPermission: hasCameraPermission,
      );
      return Right(trip);
    } on TripAlreadyActiveException {
      return const Left(TripAlreadyActiveFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> endFreeTrip(String tripId) async {
    try {
      final trip = await _datasource.endFreeTrip(tripId);
      return Right(trip);
    } on DocumentNotFoundException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Conductor: impedimento ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, TripEntity>> reportImpediment({
    required String tripId,
    required ImpedimentCategory category,
    String? description,
  }) async {
    try {
      final trip = await _datasource.reportImpediment(
        tripId: tripId,
        category: category,
        description: description,
      );
      return Right(trip);
    } on DocumentNotFoundException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Empresa ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> approveTrip(String tripId) async {
    try {
      await _datasource.approveTrip(tripId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelTrip(String tripId) async {
    try {
      await _datasource.cancelTrip(tripId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resolveImpediment(String tripId) async {
    try {
      await _datasource.resolveImpediment(tripId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final trip = await _datasource.createCompanyTrip(
        companyId: companyId,
        driverId: driverId,
        tripType: tripType,
        originLat: originLat,
        originLng: originLng,
        originAddress: originAddress,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationAddress: destinationAddress,
        scheduledDepartureTime: scheduledDepartureTime,
        estimatedArrivalTime: estimatedArrivalTime,
      );
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getCompanyPendingApprovalTrips(
      String companyId) async {
    try {
      final trips =
          await _datasource.getCompanyPendingApprovalTrips(companyId);
      return Right(trips);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getCompanyImpedimentTrips(
      String companyId) async {
    try {
      final trips = await _datasource.getCompanyImpedimentTrips(companyId);
      return Right(trips);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Ruta GPS ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _datasource.saveRoutePoint(tripId: tripId, lat: lat, lng: lng);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoutePointEntity>>> getTripRoute(
      String tripId) async {
    try {
      final points = await _datasource.getTripRoute(tripId);
      return Right(points);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getDriverTrips(
      String driverId) async {
    try {
      final trips = await _datasource.getDriverTrips(driverId);
      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getDriverTripHistory(
      String driverId) async {
    try {
      final trips = await _datasource.getDriverTripHistory(driverId);
      return Right(trips);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

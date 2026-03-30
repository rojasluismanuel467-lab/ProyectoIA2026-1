import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../domain/entities/invitation_entity.dart';
import '../../domain/entities/saved_location_entity.dart';
import '../../domain/repositories/company_repository.dart';
import '../datasources/company_datasource.dart';
import '../models/saved_location_model.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  const CompanyRepositoryImpl(this._datasource);

  final CompanyDatasource _datasource;

  @override
  Future<Either<Failure, List<CompanyLinkEntity>>> getCompanyDrivers(
    String companyId,
  ) async {
    try {
      final models = await _datasource.getCompanyDrivers(companyId);
      return Right(models);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getDriverProfile(
    String driverId,
  ) async {
    try {
      final model = await _datasource.getDriverProfile(driverId);
      return Right(model);
    } on DocumentNotFoundException {
      return const Left(DocumentNotFoundFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> unlinkDriver(String linkId) async {
    try {
      await _datasource.unlinkDriver(linkId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendInvitation({
    required String companyId,
    required String companyName,
    required String driverEmail,
  }) async {
    try {
      await _datasource.sendInvitation(
        companyId: companyId,
        companyName: companyName,
        driverEmail: driverEmail,
      );
      return const Right(null);
    } on DriverNotFoundException {
      return const Left(
        ValidationFailure(
            message:
                'No existe ningún conductor registrado con ese email. Debes registrarlo primero.'),
      );
    } on InvitationAlreadyExistsException {
      return const Left(InvitationAlreadyExistsFailure());
    } on DriverAlreadyLinkedException {
      return const Left(DriverAlreadyLinkedFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<InvitationEntity>>> getCompanyInvitations(
    String companyId,
  ) async {
    try {
      final models = await _datasource.getCompanyInvitations(companyId);
      return Right(models);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> cancelInvitation(
    String invitationId,
  ) async {
    try {
      await _datasource.cancelInvitation(invitationId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, CompanyEntity>> updateCompanyProfile({
    required String companyId,
    required String name,
    required String representativeName,
  }) async {
    try {
      final entity = await _datasource.updateCompanyProfile(
        companyId: companyId,
        name: name,
        representativeName: representativeName,
      );
      return Right(entity);
    } on DocumentNotFoundException {
      return const Left(DocumentNotFoundFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> registerDriverByCompany({
    required String companyId,
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String cargo,
  }) async {
    try {
      await _datasource.registerDriverByCompany(
        companyId: companyId,
        name: name,
        cedula: cedula,
        email: email,
        phone: phone,
        cargo: cargo,
      );
      return const Right(null);
    } on CedulaAlreadyRegisteredException {
      return const Left(CedulaAlreadyRegisteredFailure());
    } on EmailAlreadyRegisteredException {
      return const Left(EmailAlreadyRegisteredFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  // ── Viajes ───────────────────────────────────────────────────────────────────

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
    String? tripCode,
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
        tripCode: tripCode,
      );
      return Right(trip);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
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
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getCompanyImpedimentTrips(
      String companyId) async {
    try {
      final trips = await _datasource.getCompanyImpedimentTrips(companyId);
      return Right(trips);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> approveTrip(String tripId) async {
    try {
      await _datasource.approveTrip(tripId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> cancelTrip(String tripId) async {
    try {
      await _datasource.cancelTrip(tripId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resolveImpediment(String tripId) async {
    try {
      await _datasource.resolveImpediment(tripId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getCompanyTripHistory(
    String companyId,
  ) async {
    try {
      final trips = await _datasource.getCompanyTripHistory(companyId);
      return Right(trips);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getCompanyScheduledTrips(
    String companyId,
  ) async {
    try {
      final trips = await _datasource.getCompanyScheduledTrips(companyId);
      return Right(trips);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  // ── Ubicaciones guardadas ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<SavedLocationEntity>>> getSavedLocations(
    String companyId,
  ) async {
    try {
      final models = await _datasource.getSavedLocations(companyId);
      return Right(models);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveLocation(
    String companyId,
    SavedLocationEntity location,
  ) async {
    try {
      final model = SavedLocationModel(
        id: location.id,
        name: location.name,
        address: location.address,
        lat: location.lat,
        lng: location.lng,
        createdAt: location.createdAt,
      );
      await _datasource.saveLocation(companyId, model);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteSavedLocation(
    String companyId,
    String locationId,
  ) async {
    try {
      await _datasource.deleteSavedLocation(companyId, locationId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

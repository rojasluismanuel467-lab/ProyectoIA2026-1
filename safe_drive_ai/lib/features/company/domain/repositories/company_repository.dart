import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../entities/invitation_entity.dart';
import '../entities/saved_location_entity.dart';

/// Contrato del repositorio de gestión de empresa.
abstract class CompanyRepository {
  // ── Conductores ─────────────────────────────────────────────────────────────

  Future<Either<Failure, List<CompanyLinkEntity>>> getCompanyDrivers(
    String companyId,
  );

  Future<Either<Failure, UserEntity>> getDriverProfile(String driverId);

  Future<Either<Failure, void>> unlinkDriver(String linkId);

  // ── Invitaciones ─────────────────────────────────────────────────────────────

  Future<Either<Failure, void>> sendInvitation({
    required String companyId,
    required String companyName,
    required String driverEmail,
  });

  Future<Either<Failure, List<InvitationEntity>>> getCompanyInvitations(
    String companyId,
  );

  Future<Either<Failure, void>> cancelInvitation(String invitationId);

  // ── Perfil ────────────────────────────────────────────────────────────────────

  Future<Either<Failure, CompanyEntity>> updateCompanyProfile({
    required String companyId,
    required String name,
    required String representativeName,
  });

  Future<Either<Failure, void>> registerDriverByCompany({
    required String companyId,
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String cargo,
  });

  // ── Viajes ───────────────────────────────────────────────────────────────────

  /// Crea un viaje de empresa para un conductor con todos los campos del nuevo modelo.
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
  });

  /// Obtiene los viajes `pendingApproval` de los conductores de la empresa.
  Future<Either<Failure, List<TripEntity>>> getCompanyPendingApprovalTrips(
    String companyId,
  );

  /// Obtiene los viajes `withImpediment` de los conductores de la empresa.
  Future<Either<Failure, List<TripEntity>>> getCompanyImpedimentTrips(
    String companyId,
  );

  /// Obtiene todos los viajes `scheduled` (programados) de la empresa.
  Future<Either<Failure, List<TripEntity>>> getCompanyScheduledTrips(
    String companyId,
  );

  /// Aprueba un viaje `pendingApproval` — cambia a `approved`.
  Future<Either<Failure, void>> approveTrip(String tripId);

  /// Cancela un viaje — cambia a `cancelled`. Solo empresa.
  Future<Either<Failure, void>> cancelTrip(String tripId);

  /// Resuelve un impedimento activo — el viaje vuelve a `scheduled`.
  Future<Either<Failure, void>> resolveImpediment(String tripId);

  /// Obtiene el historial de viajes finalizados (approved, cancelled, completed)
  /// de todos los conductores de la empresa, ordenados por fecha descendente.
  Future<Either<Failure, List<TripEntity>>> getCompanyTripHistory(
    String companyId,
  );

  // ── Ubicaciones guardadas ─────────────────────────────────────────────────

  /// Obtiene la lista de ubicaciones guardadas de una empresa.
  Future<Either<Failure, List<SavedLocationEntity>>> getSavedLocations(
    String companyId,
  );

  /// Guarda una nueva ubicación para la empresa.
  Future<Either<Failure, void>> saveLocation(
    String companyId,
    SavedLocationEntity location,
  );

  /// Elimina una ubicación guardada de la empresa.
  Future<Either<Failure, void>> deleteSavedLocation(
    String companyId,
    String locationId,
  );
}

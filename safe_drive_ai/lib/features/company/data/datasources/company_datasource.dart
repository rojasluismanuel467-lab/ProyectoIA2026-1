import '../../../auth/data/models/company_link_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../models/invitation_model.dart';
import '../models/saved_location_model.dart';

/// Contrato de la fuente de datos remota para el feature de empresa.
abstract class CompanyDatasource {
  Future<List<CompanyLinkModel>> getCompanyDrivers(String companyId);
  Future<UserModel> getDriverProfile(String driverId);
  Future<void> unlinkDriver(String linkId);

  Future<void> sendInvitation({
    required String companyId,
    required String companyName,
    required String driverEmail,
  });

  Future<List<InvitationModel>> getCompanyInvitations(String companyId);
  Future<void> cancelInvitation(String invitationId);

  Future<CompanyEntity> updateCompanyProfile({
    required String companyId,
    required String name,
    required String representativeName,
  });

  Future<void> registerDriverByCompany({
    required String companyId,
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String cargo,
  });

  // ── Viajes ────────────────────────────────────────────────────────────────────

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
    String? tripCode,
    String? companyName,
  });

  Future<List<TripModel>> getCompanyPendingApprovalTrips(String companyId);
  Future<List<TripModel>> getCompanyImpedimentTrips(String companyId);
  Future<List<TripModel>> getCompanyScheduledTrips(String companyId);
  Future<void> approveTrip(String tripId);
  Future<void> cancelTrip(String tripId);
  Future<void> resolveImpediment(String tripId);
  Future<List<TripModel>> getCompanyTripHistory(String companyId);

  // ── Ubicaciones guardadas ─────────────────────────────────────────────────

  Future<List<SavedLocationModel>> getSavedLocations(String companyId);
  Future<void> saveLocation(
    String companyId,
    SavedLocationModel location,
  );
  Future<void> deleteSavedLocation(String companyId, String locationId);
}

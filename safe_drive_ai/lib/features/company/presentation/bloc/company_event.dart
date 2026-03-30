import 'package:equatable/equatable.dart';

import '../../../trips/domain/entities/trip_entity.dart';

abstract class CompanyEvent extends Equatable {
  const CompanyEvent();

  @override
  List<Object?> get props => [];
}

class CompanyDriversRequested extends CompanyEvent {
  const CompanyDriversRequested({required this.companyId});
  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

class CompanyDriverUnlinkRequested extends CompanyEvent {
  const CompanyDriverUnlinkRequested({
    required this.linkId,
    required this.companyId,
  });
  final String linkId;
  final String companyId;

  @override
  List<Object?> get props => [linkId, companyId];
}

class CompanyInvitationSendRequested extends CompanyEvent {
  const CompanyInvitationSendRequested({
    required this.companyId,
    required this.companyName,
    required this.driverEmail,
  });
  final String companyId;
  final String companyName;
  final String driverEmail;

  @override
  List<Object?> get props => [companyId, companyName, driverEmail];
}

class CompanyInvitationsRequested extends CompanyEvent {
  const CompanyInvitationsRequested({required this.companyId});
  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

class CompanyInvitationCancelRequested extends CompanyEvent {
  const CompanyInvitationCancelRequested({
    required this.invitationId,
    required this.companyId,
  });
  final String invitationId;
  final String companyId;

  @override
  List<Object?> get props => [invitationId, companyId];
}

class CompanyProfileRequested extends CompanyEvent {
  const CompanyProfileRequested({required this.companyId});
  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

class CompanyProfileUpdateRequested extends CompanyEvent {
  const CompanyProfileUpdateRequested({
    required this.companyId,
    required this.name,
    required this.representativeName,
  });
  final String companyId;
  final String name;
  final String representativeName;

  @override
  List<Object?> get props => [companyId, name, representativeName];
}

class CompanyDriverRegisterRequested extends CompanyEvent {
  const CompanyDriverRegisterRequested({
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.cedula,
    required this.email,
    required this.phone,
    required this.cargo,
  });
  final String companyId;
  final String companyName;
  final String name;
  final String cedula;
  final String email;
  final String phone;
  final String cargo;

  @override
  List<Object?> get props =>
      [companyId, companyName, name, cedula, email, phone, cargo];
}

// ── Viajes ───────────────────────────────────────────────────────────────────

/// Solicita la lista de viajes pendientes de aprobación.
class CompanyPendingTripsRequested extends CompanyEvent {
  const CompanyPendingTripsRequested({required this.companyId});
  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Solicita la lista de viajes con impedimento activo.
class CompanyImpedimentTripsRequested extends CompanyEvent {
  const CompanyImpedimentTripsRequested({required this.companyId});
  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Solicita la lista de viajes programados (scheduled) de la empresa.
class CompanyScheduledTripsRequested extends CompanyEvent {
  const CompanyScheduledTripsRequested({required this.companyId});
  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Empresa aprueba un viaje en `pendingApproval`.
class CompanyTripApproved extends CompanyEvent {
  const CompanyTripApproved({
    required this.tripId,
    required this.companyId,
  });
  final String tripId;
  final String companyId;

  @override
  List<Object?> get props => [tripId, companyId];
}

/// Empresa cancela un viaje.
class CompanyTripCancelled extends CompanyEvent {
  const CompanyTripCancelled({
    required this.tripId,
    required this.companyId,
  });
  final String tripId;
  final String companyId;

  @override
  List<Object?> get props => [tripId, companyId];
}

/// Empresa resuelve un impedimento activo — el viaje vuelve a scheduled.
class CompanyImpedimentResolved extends CompanyEvent {
  const CompanyImpedimentResolved({
    required this.tripId,
    required this.companyId,
  });
  final String tripId;
  final String companyId;

  @override
  List<Object?> get props => [tripId, companyId];
}

// ── Ubicaciones guardadas ─────────────────────────────────────────────────────

/// Solicita la lista de ubicaciones guardadas de la empresa.
class LoadSavedLocations extends CompanyEvent {
  const LoadSavedLocations({required this.companyId});
  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Solicita guardar una nueva ubicación.
class SaveLocationRequested extends CompanyEvent {
  const SaveLocationRequested({
    required this.companyId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String companyId;
  final String name;
  final String address;
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [companyId, name, address, lat, lng];
}

/// Solicita eliminar una ubicación guardada.
class DeleteSavedLocationRequested extends CompanyEvent {
  const DeleteSavedLocationRequested({
    required this.companyId,
    required this.locationId,
  });

  final String companyId;
  final String locationId;

  @override
  List<Object?> get props => [companyId, locationId];
}

/// Solicita el historial de viajes finalizados de la empresa.
class LoadCompanyTripHistory extends CompanyEvent {
  const LoadCompanyTripHistory({required this.companyId});
  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Empresa crea un viaje para un conductor.
class CompanyTripCreateRequested extends CompanyEvent {
  const CompanyTripCreateRequested({
    required this.companyId,
    required this.driverId,
    required this.tripType,
    required this.originLat,
    required this.originLng,
    required this.originAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationAddress,
    required this.scheduledDepartureTime,
    required this.estimatedArrivalTime,
    this.tripCode,
  });

  final String companyId;
  final String driverId;
  final TripType tripType;
  final double originLat;
  final double originLng;
  final String originAddress;
  final double destinationLat;
  final double destinationLng;
  final String destinationAddress;
  final DateTime scheduledDepartureTime;
  final DateTime estimatedArrivalTime;
  final String? tripCode;

  @override
  List<Object?> get props => [
        companyId,
        driverId,
        tripType,
        originLat,
        originLng,
        originAddress,
        destinationLat,
        destinationLng,
        destinationAddress,
        scheduledDepartureTime,
        estimatedArrivalTime,
        tripCode,
      ];
}

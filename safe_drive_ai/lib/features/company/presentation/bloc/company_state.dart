import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/company_entity.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../domain/entities/invitation_entity.dart';
import '../../domain/entities/saved_location_entity.dart';

abstract class CompanyState extends Equatable {
  const CompanyState();

  @override
  List<Object?> get props => [];
}

class CompanyInitial extends CompanyState {
  const CompanyInitial();
}

class CompanyLoading extends CompanyState {
  const CompanyLoading();
}

class CompanyDriversLoaded extends CompanyState {
  const CompanyDriversLoaded({required this.drivers});
  final List<CompanyLinkEntity> drivers;

  @override
  List<Object?> get props => [drivers];
}

class CompanyInvitationsLoaded extends CompanyState {
  const CompanyInvitationsLoaded({required this.invitations});
  final List<InvitationEntity> invitations;

  @override
  List<Object?> get props => [invitations];
}

class CompanyProfileLoaded extends CompanyState {
  const CompanyProfileLoaded({required this.company});
  final CompanyEntity company;

  @override
  List<Object?> get props => [company];
}

class CompanyActionSuccess extends CompanyState {
  const CompanyActionSuccess({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class CompanyError extends CompanyState {
  const CompanyError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Viajes pendientes de aprobación cargados.
class CompanyPendingTripsLoaded extends CompanyState {
  const CompanyPendingTripsLoaded({required this.pendingTrips});
  final List<TripEntity> pendingTrips;

  @override
  List<Object?> get props => [pendingTrips];
}

/// Viajes con impedimento activo cargados.
class CompanyImpedimentTripsLoaded extends CompanyState {
  const CompanyImpedimentTripsLoaded({required this.impedimentTrips});
  final List<TripEntity> impedimentTrips;

  @override
  List<Object?> get props => [impedimentTrips];
}

/// Viajes programados (scheduled) cargados.
class CompanyScheduledTripsLoaded extends CompanyState {
  const CompanyScheduledTripsLoaded({required this.scheduledTrips});
  final List<TripEntity> scheduledTrips;

  @override
  List<Object?> get props => [scheduledTrips];
}

/// Historial de viajes finalizados de la empresa cargado.
class CompanyTripHistoryLoaded extends CompanyState {
  const CompanyTripHistoryLoaded({required this.trips});
  final List<TripEntity> trips;

  @override
  List<Object?> get props => [trips];
}

/// Ubicaciones guardadas de la empresa cargadas.
class SavedLocationsLoaded extends CompanyState {
  const SavedLocationsLoaded({required this.locations});
  final List<SavedLocationEntity> locations;

  @override
  List<Object?> get props => [locations];
}

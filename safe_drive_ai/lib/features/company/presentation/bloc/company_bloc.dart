import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/approve_trip_usecase.dart';
import '../../domain/usecases/get_company_trip_history_usecase.dart';
import '../../domain/usecases/cancel_invitation_usecase.dart';
import '../../domain/usecases/cancel_trip_usecase.dart';
import '../../domain/usecases/create_company_trip_usecase.dart';
import '../../domain/usecases/delete_saved_location_usecase.dart';
import '../../domain/usecases/get_company_drivers_usecase.dart';
import '../../domain/usecases/get_company_impediment_trips_usecase.dart';
import '../../domain/usecases/get_company_invitations_usecase.dart';
import '../../domain/usecases/get_company_pending_trips_usecase.dart';
import '../../domain/usecases/get_company_scheduled_trips_usecase.dart';
import '../../domain/usecases/get_saved_locations_usecase.dart';
import '../../domain/usecases/register_driver_by_company_usecase.dart';
import '../../domain/usecases/resolve_impediment_company_usecase.dart';
import '../../domain/usecases/save_location_usecase.dart';
import '../../domain/usecases/send_invitation_usecase.dart';
import '../../domain/usecases/unlink_driver_usecase.dart';
import '../../domain/usecases/update_company_profile_usecase.dart';
import 'company_event.dart';
import 'company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  CompanyBloc({
    required GetCompanyDriversUseCase getCompanyDriversUseCase,
    required UnlinkDriverUseCase unlinkDriverUseCase,
    required SendInvitationUseCase sendInvitationUseCase,
    required GetCompanyInvitationsUseCase getCompanyInvitationsUseCase,
    required CancelInvitationUseCase cancelInvitationUseCase,
    required UpdateCompanyProfileUseCase updateCompanyProfileUseCase,
    required RegisterDriverByCompanyUseCase registerDriverByCompanyUseCase,
    required GetCompanyPendingTripsUseCase getCompanyPendingTripsUseCase,
    required GetCompanyImpedimentTripsUseCase getCompanyImpedimentTripsUseCase,
    required GetCompanyScheduledTripsUseCase getCompanyScheduledTripsUseCase,
    required ApproveTripUseCase approveTripUseCase,
    required CancelTripUseCase cancelTripUseCase,
    required ResolveImpedimentCompanyUseCase resolveImpedimentCompanyUseCase,
    required CreateCompanyTripUseCase createCompanyTripUseCase,
    required GetSavedLocationsUseCase getSavedLocationsUseCase,
    required SaveLocationUseCase saveLocationUseCase,
    required DeleteSavedLocationUseCase deleteSavedLocationUseCase,
    required GetCompanyTripHistoryUseCase getCompanyTripHistoryUseCase,
  })  : _getCompanyDriversUseCase = getCompanyDriversUseCase,
        _unlinkDriverUseCase = unlinkDriverUseCase,
        _sendInvitationUseCase = sendInvitationUseCase,
        _getCompanyInvitationsUseCase = getCompanyInvitationsUseCase,
        _cancelInvitationUseCase = cancelInvitationUseCase,
        _updateCompanyProfileUseCase = updateCompanyProfileUseCase,
        _registerDriverByCompanyUseCase = registerDriverByCompanyUseCase,
        _getCompanyPendingTripsUseCase = getCompanyPendingTripsUseCase,
        _getCompanyImpedimentTripsUseCase = getCompanyImpedimentTripsUseCase,
        _getCompanyScheduledTripsUseCase = getCompanyScheduledTripsUseCase,
        _approveTripUseCase = approveTripUseCase,
        _cancelTripUseCase = cancelTripUseCase,
        _resolveImpedimentCompanyUseCase = resolveImpedimentCompanyUseCase,
        _createCompanyTripUseCase = createCompanyTripUseCase,
        _getSavedLocationsUseCase = getSavedLocationsUseCase,
        _saveLocationUseCase = saveLocationUseCase,
        _deleteSavedLocationUseCase = deleteSavedLocationUseCase,
        _getCompanyTripHistoryUseCase = getCompanyTripHistoryUseCase,
        super(const CompanyInitial()) {
    on<CompanyDriversRequested>(_onDriversRequested);
    on<CompanyDriverUnlinkRequested>(_onDriverUnlinkRequested);
    on<CompanyInvitationSendRequested>(_onInvitationSendRequested);
    on<CompanyInvitationsRequested>(_onInvitationsRequested);
    on<CompanyInvitationCancelRequested>(_onInvitationCancelRequested);
    on<CompanyProfileRequested>(_onProfileRequested);
    on<CompanyProfileUpdateRequested>(_onProfileUpdateRequested);
    on<CompanyDriverRegisterRequested>(_onDriverRegisterRequested);
    on<CompanyPendingTripsRequested>(_onPendingTripsRequested);
    on<CompanyImpedimentTripsRequested>(_onImpedimentTripsRequested);
    on<CompanyScheduledTripsRequested>(_onScheduledTripsRequested);
    on<CompanyTripApproved>(_onTripApproved);
    on<CompanyTripCancelled>(_onTripCancelled);
    on<CompanyImpedimentResolved>(_onImpedimentResolved);
    on<CompanyTripCreateRequested>(_onTripCreateRequested);
    on<LoadSavedLocations>(_onLoadSavedLocations);
    on<SaveLocationRequested>(_onSaveLocationRequested);
    on<DeleteSavedLocationRequested>(_onDeleteSavedLocationRequested);
    on<LoadCompanyTripHistory>(_onTripHistoryRequested);
  }

  final GetCompanyDriversUseCase _getCompanyDriversUseCase;
  final UnlinkDriverUseCase _unlinkDriverUseCase;
  final SendInvitationUseCase _sendInvitationUseCase;
  final GetCompanyInvitationsUseCase _getCompanyInvitationsUseCase;
  final CancelInvitationUseCase _cancelInvitationUseCase;
  final UpdateCompanyProfileUseCase _updateCompanyProfileUseCase;
  final RegisterDriverByCompanyUseCase _registerDriverByCompanyUseCase;
  final GetCompanyPendingTripsUseCase _getCompanyPendingTripsUseCase;
  final GetCompanyImpedimentTripsUseCase _getCompanyImpedimentTripsUseCase;
  final GetCompanyScheduledTripsUseCase _getCompanyScheduledTripsUseCase;
  final ApproveTripUseCase _approveTripUseCase;
  final CancelTripUseCase _cancelTripUseCase;
  final ResolveImpedimentCompanyUseCase _resolveImpedimentCompanyUseCase;
  final CreateCompanyTripUseCase _createCompanyTripUseCase;
  final GetSavedLocationsUseCase _getSavedLocationsUseCase;
  final SaveLocationUseCase _saveLocationUseCase;
  final DeleteSavedLocationUseCase _deleteSavedLocationUseCase;
  final GetCompanyTripHistoryUseCase _getCompanyTripHistoryUseCase;

  // ── Conductores ──────────────────────────────────────────────────────────────

  Future<void> _onDriversRequested(
    CompanyDriversRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _getCompanyDriversUseCase(
      GetCompanyDriversParams(companyId: event.companyId),
    );
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (drivers) => emit(CompanyDriversLoaded(drivers: drivers)),
    );
  }

  Future<void> _onDriverUnlinkRequested(
    CompanyDriverUnlinkRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result =
        await _unlinkDriverUseCase(UnlinkDriverParams(linkId: event.linkId));
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(
            message: 'Conductor desvinculado correctamente.'));
        final driversResult = await _getCompanyDriversUseCase(
          GetCompanyDriversParams(companyId: event.companyId),
        );
        driversResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (drivers) => emit(CompanyDriversLoaded(drivers: drivers)),
        );
      },
    );
  }

  Future<void> _onInvitationSendRequested(
    CompanyInvitationSendRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _sendInvitationUseCase(
      SendInvitationParams(
        companyId: event.companyId,
        companyName: event.companyName,
        driverEmail: event.driverEmail,
      ),
    );
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(
            message: 'Invitación enviada correctamente.'));
        final invitationsResult = await _getCompanyInvitationsUseCase(
          GetCompanyInvitationsParams(companyId: event.companyId),
        );
        invitationsResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (invitations) =>
              emit(CompanyInvitationsLoaded(invitations: invitations)),
        );
      },
    );
  }

  Future<void> _onInvitationsRequested(
    CompanyInvitationsRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _getCompanyInvitationsUseCase(
      GetCompanyInvitationsParams(companyId: event.companyId),
    );
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (invitations) => emit(CompanyInvitationsLoaded(invitations: invitations)),
    );
  }

  Future<void> _onInvitationCancelRequested(
    CompanyInvitationCancelRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _cancelInvitationUseCase(
      CancelInvitationParams(invitationId: event.invitationId),
    );
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(
            message: 'Invitación cancelada correctamente.'));
        final invitationsResult = await _getCompanyInvitationsUseCase(
          GetCompanyInvitationsParams(companyId: event.companyId),
        );
        invitationsResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (invitations) =>
              emit(CompanyInvitationsLoaded(invitations: invitations)),
        );
      },
    );
  }

  Future<void> _onProfileRequested(
    CompanyProfileRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyError(
        message: 'Use el perfil provisto en la navegación.'));
  }

  Future<void> _onProfileUpdateRequested(
    CompanyProfileUpdateRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _updateCompanyProfileUseCase(
      UpdateCompanyProfileParams(
        companyId: event.companyId,
        name: event.name,
        representativeName: event.representativeName,
      ),
    );
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (company) => emit(CompanyProfileLoaded(company: company)),
    );
  }

  Future<void> _onDriverRegisterRequested(
    CompanyDriverRegisterRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _registerDriverByCompanyUseCase(
      RegisterDriverByCompanyParams(
        companyId: event.companyId,
        name: event.name,
        cedula: event.cedula,
        email: event.email,
        phone: event.phone,
        cargo: event.cargo,
      ),
    );
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(
          message:
              'Conductor registrado exitosamente. Se enviaron las credenciales a su correo.',
        ));
        final driversResult = await _getCompanyDriversUseCase(
          GetCompanyDriversParams(companyId: event.companyId),
        );
        driversResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (drivers) => emit(CompanyDriversLoaded(drivers: drivers)),
        );
      },
    );
  }

  // ── Viajes ───────────────────────────────────────────────────────────────────

  Future<void> _onPendingTripsRequested(
    CompanyPendingTripsRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result =
        await _getCompanyPendingTripsUseCase(event.companyId);
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (trips) => emit(CompanyPendingTripsLoaded(pendingTrips: trips)),
    );
  }

  Future<void> _onImpedimentTripsRequested(
    CompanyImpedimentTripsRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result =
        await _getCompanyImpedimentTripsUseCase(event.companyId);
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (trips) => emit(CompanyImpedimentTripsLoaded(impedimentTrips: trips)),
    );
  }

  Future<void> _onScheduledTripsRequested(
    CompanyScheduledTripsRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result =
        await _getCompanyScheduledTripsUseCase(event.companyId);
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (trips) => emit(CompanyScheduledTripsLoaded(scheduledTrips: trips)),
    );
  }

  Future<void> _onTripApproved(
    CompanyTripApproved event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _approveTripUseCase(event.tripId);
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(
            message: 'Viaje aprobado correctamente.'));
        final pendingResult =
            await _getCompanyPendingTripsUseCase(event.companyId);
        pendingResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (trips) => emit(CompanyPendingTripsLoaded(pendingTrips: trips)),
        );
      },
    );
  }

  Future<void> _onTripCancelled(
    CompanyTripCancelled event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _cancelTripUseCase(event.tripId);
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(message: 'Viaje cancelado.'));
        final pendingResult =
            await _getCompanyPendingTripsUseCase(event.companyId);
        pendingResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (trips) => emit(CompanyPendingTripsLoaded(pendingTrips: trips)),
        );
      },
    );
  }

  Future<void> _onImpedimentResolved(
    CompanyImpedimentResolved event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _resolveImpedimentCompanyUseCase(event.tripId);
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(
            message: 'Impedimento resuelto. El viaje vuelve a programado.'));
        final impedimentResult =
            await _getCompanyImpedimentTripsUseCase(event.companyId);
        impedimentResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (trips) => emit(CompanyImpedimentTripsLoaded(impedimentTrips: trips)),
        );
      },
    );
  }

  Future<void> _onTripCreateRequested(
    CompanyTripCreateRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _createCompanyTripUseCase(
      CreateCompanyTripParams(
        companyId: event.companyId,
        driverId: event.driverId,
        tripType: event.tripType,
        originLat: event.originLat,
        originLng: event.originLng,
        originAddress: event.originAddress,
        destinationLat: event.destinationLat,
        destinationLng: event.destinationLng,
        destinationAddress: event.destinationAddress,
        scheduledDepartureTime: event.scheduledDepartureTime,
        estimatedArrivalTime: event.estimatedArrivalTime,
        tripCode: event.tripCode,
      ),
    );
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (_) => emit(const CompanyActionSuccess(
          message: 'Viaje creado correctamente.')),
    );
  }

  // ── Ubicaciones guardadas ─────────────────────────────────────────────────

  Future<void> _onLoadSavedLocations(
    LoadSavedLocations event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _getSavedLocationsUseCase(event.companyId);
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (locations) => emit(SavedLocationsLoaded(locations: locations)),
    );
  }

  Future<void> _onSaveLocationRequested(
    SaveLocationRequested event,
    Emitter<CompanyState> emit,
  ) async {
    final result = await _saveLocationUseCase(
      SaveLocationParams(
        companyId: event.companyId,
        name: event.name,
        address: event.address,
        lat: event.lat,
        lng: event.lng,
      ),
    );
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(
            message: 'Ubicación guardada correctamente.'));
        final locationsResult =
            await _getSavedLocationsUseCase(event.companyId);
        locationsResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (locations) => emit(SavedLocationsLoaded(locations: locations)),
        );
      },
    );
  }

  Future<void> _onDeleteSavedLocationRequested(
    DeleteSavedLocationRequested event,
    Emitter<CompanyState> emit,
  ) async {
    final result = await _deleteSavedLocationUseCase(
      companyId: event.companyId,
      locationId: event.locationId,
    );
    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(const CompanyActionSuccess(
            message: 'Ubicación eliminada.'));
        final locationsResult =
            await _getSavedLocationsUseCase(event.companyId);
        locationsResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (locations) => emit(SavedLocationsLoaded(locations: locations)),
        );
      },
    );
  }

  // ── Historial de viajes ───────────────────────────────────────────────────

  Future<void> _onTripHistoryRequested(
    LoadCompanyTripHistory event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());
    final result = await _getCompanyTripHistoryUseCase(event.companyId);
    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (trips) => emit(CompanyTripHistoryLoaded(trips: trips)),
    );
  }
}

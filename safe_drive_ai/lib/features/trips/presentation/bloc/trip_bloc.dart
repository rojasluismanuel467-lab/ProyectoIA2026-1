import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/trip_entity.dart';
import '../../domain/usecases/end_free_trip_usecase.dart';
import '../../domain/usecases/end_trip_usecase.dart';
import '../../domain/usecases/get_active_trip_usecase.dart';
import '../../domain/usecases/get_driver_scheduled_trips_usecase.dart';
import '../../domain/usecases/get_driver_trip_history_usecase.dart';
import '../../domain/usecases/report_impediment_usecase.dart';
import '../../domain/usecases/save_route_point_usecase.dart';
import '../../domain/usecases/start_free_trip_usecase.dart';
import '../../domain/usecases/start_trip_usecase.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc({
    required GetDriverScheduledTripsUseCase getDriverScheduledTripsUseCase,
    required GetActiveTripUseCase getActiveTripUseCase,
    required StartTripUseCase startTripUseCase,
    required EndTripUseCase endTripUseCase,
    required StartFreeTripUseCase startFreeTripUseCase,
    required EndFreeTripUseCase endFreeTripUseCase,
    required ReportImpedimentUseCase reportImpedimentUseCase,
    required SaveRoutePointUseCase saveRoutePointUseCase,
    required GetDriverTripHistoryUseCase getDriverTripHistoryUseCase,
  })  : _getDriverScheduledTripsUseCase = getDriverScheduledTripsUseCase,
        _getActiveTripUseCase = getActiveTripUseCase,
        _startTripUseCase = startTripUseCase,
        _endTripUseCase = endTripUseCase,
        _startFreeTripUseCase = startFreeTripUseCase,
        _endFreeTripUseCase = endFreeTripUseCase,
        _reportImpedimentUseCase = reportImpedimentUseCase,
        _saveRoutePointUseCase = saveRoutePointUseCase,
        _getDriverTripHistoryUseCase = getDriverTripHistoryUseCase,
        super(const TripInitial()) {
    on<LoadDriverTrips>(_onLoadDriverTrips);
    on<StartTrip>(_onStartTrip);
    on<EndTrip>(_onEndTrip);
    on<StartFreeTrip>(_onStartFreeTrip);
    on<EndFreeTrip>(_onEndFreeTrip);
    on<ReportImpediment>(_onReportImpediment);
    on<TripTick>(_onTick);
    on<TripLocationUpdated>(_onLocationUpdated);
    on<LoadDriverTripHistory>(_onLoadDriverTripHistory);
  }

  final GetDriverScheduledTripsUseCase _getDriverScheduledTripsUseCase;
  final GetActiveTripUseCase _getActiveTripUseCase;
  final StartTripUseCase _startTripUseCase;
  final EndTripUseCase _endTripUseCase;
  final StartFreeTripUseCase _startFreeTripUseCase;
  final EndFreeTripUseCase _endFreeTripUseCase;
  final ReportImpedimentUseCase _reportImpedimentUseCase;
  final SaveRoutePointUseCase _saveRoutePointUseCase;
  final GetDriverTripHistoryUseCase _getDriverTripHistoryUseCase;

  Timer? _timer;
  StreamSubscription<Position>? _positionSub;

  // ── Timer ───────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TripTick());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Location ────────────────────────────────────────────────────────────────

  Future<void> _startLocationTracking() async {
    _positionSub?.cancel();
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        add(TripLocationUpdated(lat: pos.latitude, lng: pos.longitude));
      });
    } catch (_) {}
  }

  void _stopLocationTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  Future<void> _onLoadDriverTrips(
    LoadDriverTrips event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());

    // 1. ¿Hay un viaje en progreso?
    final activeResult =
        await _getActiveTripUseCase(GetActiveTripParams(driverId: event.driverId));

    final TripEntity? activeTrip = activeResult.fold((_) => null, (t) => t);

    if (activeTrip != null) {
      if (activeTrip.isFreeTrip) {
        emit(FreeTripInProgress(
          trip: activeTrip,
          elapsed: activeTrip.elapsed,
        ));
        _startTimer();
        _startLocationTracking();
        return;
      } else {
        emit(TripInProgress(
          trip: activeTrip,
          elapsed: activeTrip.elapsed,
        ));
        _startTimer();
        _startLocationTracking();
        return;
      }
    }

    // 2. Cargar viajes scheduled
    final scheduledResult =
        await _getDriverScheduledTripsUseCase(event.driverId);

    scheduledResult.fold(
      (failure) => emit(TripError(message: failure.message)),
      (trips) {
        // Verificar si alguno tiene impedimento activo
        final hasImpediment = trips
            .any((t) => t.status == TripStatus.withImpediment);

        // Si hay uno con impedimento, mostrar ese estado
        if (hasImpediment) {
          final impedimentTrip =
              trips.firstWhere((t) => t.status == TripStatus.withImpediment);
          emit(TripWithImpediment(trip: impedimentTrip));
          return;
        }

        // Solo viajes en estado scheduled (los demás no se muestran al conductor)
        final pending =
            trips.where((t) => t.status == TripStatus.scheduled).toList();

        emit(TripListLoaded(
          scheduledTrips: pending,
          hasActiveImpediment: false,
        ));
      },
    );
  }

  Future<void> _onStartTrip(
    StartTrip event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());

    final result = await _startTripUseCase(
      StartTripParams(
        tripId: event.tripId,
        hasCameraPermission: event.hasCameraPermission,
      ),
    );

    result.fold(
      (failure) => emit(TripError(message: failure.message)),
      (trip) {
        emit(TripInProgress(
          trip: trip,
          elapsed: Duration.zero,
          isNewlyStarted: true,
        ));
        _startTimer();
        _startLocationTracking();
      },
    );
  }

  Future<void> _onEndTrip(
    EndTrip event,
    Emitter<TripState> emit,
  ) async {
    _stopTimer();
    _stopLocationTracking();

    final result = await _endTripUseCase(EndTripParams(tripId: event.tripId));

    result.fold(
      (failure) => emit(TripError(message: failure.message)),
      (trip) => emit(TripPendingApproval(trip: trip)),
    );
  }

  Future<void> _onStartFreeTrip(
    StartFreeTrip event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());

    final result = await _startFreeTripUseCase(
      StartFreeTripParams(
        driverId: event.driverId,
        hasCameraPermission: event.hasCameraPermission,
      ),
    );

    result.fold(
      (failure) => emit(TripError(message: failure.message)),
      (trip) {
        emit(FreeTripInProgress(
          trip: trip,
          elapsed: Duration.zero,
          isNewlyStarted: true,
        ));
        _startTimer();
        _startLocationTracking();
      },
    );
  }

  Future<void> _onEndFreeTrip(
    EndFreeTrip event,
    Emitter<TripState> emit,
  ) async {
    _stopTimer();
    _stopLocationTracking();

    final result = await _endFreeTripUseCase(event.tripId);

    result.fold(
      (failure) => emit(TripError(message: failure.message)),
      (trip) => emit(TripEnded(trip: trip)),
    );
  }

  Future<void> _onReportImpediment(
    ReportImpediment event,
    Emitter<TripState> emit,
  ) async {
    _stopTimer();
    _stopLocationTracking();

    final result = await _reportImpedimentUseCase(
      ReportImpedimentParams(
        tripId: event.tripId,
        category: event.category,
        description: event.description,
      ),
    );

    result.fold(
      (failure) => emit(TripError(message: failure.message)),
      (trip) => emit(TripWithImpediment(trip: trip)),
    );
  }

  void _onTick(TripTick event, Emitter<TripState> emit) {
    if (state is TripInProgress) {
      final current = state as TripInProgress;
      emit(current.copyWith(elapsed: current.trip.elapsed));
    } else if (state is FreeTripInProgress) {
      final current = state as FreeTripInProgress;
      emit(current.copyWith(elapsed: current.trip.elapsed));
    }
  }

  void _onLocationUpdated(
    TripLocationUpdated event,
    Emitter<TripState> emit,
  ) {
    if (state is TripInProgress) {
      final current = state as TripInProgress;
      final newRoute = [...current.route, LatLng(event.lat, event.lng)];
      // Guardar punto en Firestore en segundo plano
      _saveRoutePointUseCase(SaveRoutePointParams(
        tripId: current.trip.id,
        lat: event.lat,
        lng: event.lng,
      ));
      emit(current.copyWith(route: newRoute));
    } else if (state is FreeTripInProgress) {
      final current = state as FreeTripInProgress;
      final newRoute = [...current.route, LatLng(event.lat, event.lng)];
      _saveRoutePointUseCase(SaveRoutePointParams(
        tripId: current.trip.id,
        lat: event.lat,
        lng: event.lng,
      ));
      emit(current.copyWith(route: newRoute));
    }
  }

  Future<void> _onLoadDriverTripHistory(
    LoadDriverTripHistory event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripHistoryLoading());

    final result = await _getDriverTripHistoryUseCase(event.driverId);

    result.fold(
      (failure) => emit(TripHistoryError(message: failure.message)),
      (trips) => emit(TripHistoryLoaded(trips: trips)),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _positionSub?.cancel();
    return super.close();
  }
}

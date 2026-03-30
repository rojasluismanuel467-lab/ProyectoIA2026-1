import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../../trips/domain/usecases/end_free_trip_usecase.dart';
import '../../../trips/domain/usecases/end_trip_usecase.dart';
import '../../../trips/domain/usecases/get_active_trip_usecase.dart';
import '../../../trips/domain/usecases/get_driver_scheduled_trips_usecase.dart';
import '../../../trips/domain/usecases/get_driver_trip_history_usecase.dart';
import '../../../trips/domain/usecases/report_impediment_usecase.dart';
import '../../../trips/domain/usecases/save_route_point_usecase.dart';
import '../../../trips/domain/usecases/start_free_trip_usecase.dart';
import '../../../trips/domain/usecases/start_trip_usecase.dart';
import '../../../trips/presentation/bloc/trip_bloc.dart';
import '../../../trips/presentation/bloc/trip_event.dart';
import '../../../trips/presentation/bloc/trip_state.dart';
import '../../../trips/presentation/pages/trip_map_page.dart';
import '../../../trips/presentation/widgets/trip_panel_widget.dart';
import 'driver_companies_page.dart';
import 'driver_invitations_page.dart';
import 'driver_profile_page.dart';
import 'driver_trip_history_page.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({
    super.key,
    required this.driver,
    required this.companies,
  });

  final UserEntity driver;
  final List<CompanyLinkEntity> companies;

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _currentIndex = 0;
  late final TripBloc _tripBloc;

  static const List<_DrawerItemMeta> _drawerItems = [
    _DrawerItemMeta(
      title: 'Mis Viajes',
      icon: Icons.route_outlined,
      activeIcon: Icons.route,
    ),
    _DrawerItemMeta(
      title: 'Empresas',
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
    ),
    _DrawerItemMeta(
      title: 'Invitaciones',
      icon: Icons.mail_outline,
      activeIcon: Icons.mail,
    ),
    _DrawerItemMeta(
      title: 'Mi Perfil',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
    _DrawerItemMeta(
      title: 'Historial',
      icon: Icons.history,
      activeIcon: Icons.history,
    ),
  ];

  String get _currentTitle {
    final mapIndex = _currentIndex > 4 ? _currentIndex - 1 : _currentIndex;
    if (mapIndex >= 0 && mapIndex < _drawerItems.length) {
      return _drawerItems[mapIndex].title;
    }
    return 'Safe Drive AI';
  }

  @override
  void initState() {
    super.initState();
    _tripBloc = TripBloc(
      getDriverScheduledTripsUseCase: sl<GetDriverScheduledTripsUseCase>(),
      getActiveTripUseCase: sl<GetActiveTripUseCase>(),
      startTripUseCase: sl<StartTripUseCase>(),
      endTripUseCase: sl<EndTripUseCase>(),
      startFreeTripUseCase: sl<StartFreeTripUseCase>(),
      endFreeTripUseCase: sl<EndFreeTripUseCase>(),
      reportImpedimentUseCase: sl<ReportImpedimentUseCase>(),
      saveRoutePointUseCase: sl<SaveRoutePointUseCase>(),
      getDriverTripHistoryUseCase: sl<GetDriverTripHistoryUseCase>(),
    )..add(LoadDriverTrips(driverId: widget.driver.id));
  }

  @override
  void dispose() {
    _tripBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showingMap = _currentIndex == 4;

    return BlocProvider<TripBloc>.value(
      value: _tripBloc,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthLoggedOut) {
                context.go('/role-selection');
              }
            },
          ),
          BlocListener<TripBloc, TripState>(
            listener: (context, state) {
              if (state is TripEnded) {
                if (_currentIndex == 4) setState(() => _currentIndex = 0);
                // Conductor ve resumen - muestra solo nombre de la empresa
                context.push('/trip/summary', extra: {
                  'trip': state.trip,
                  'showDriverInfo': false,
                });
              } else if (state is TripInProgress && state.isNewlyStarted) {
                setState(() => _currentIndex = 4);
              } else if (state is FreeTripInProgress && state.isNewlyStarted) {
                setState(() => _currentIndex = 4);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: showingMap
              ? null
              : AppBar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  leading: Builder(
                    builder: (BuildContext scaffoldContext) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      Text(
                        widget.driver.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
          drawer: showingMap ? null : _buildDrawer(),
          body: Column(
            children: [
              if (!showingMap)
                TripPanelWidget(
                  driverId: widget.driver.id,
                  onOpenMap: () => setState(() => _currentIndex = 4),
                ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _TripsTab(
                      driver: widget.driver,
                      tripBloc: _tripBloc,
                    ),
                    DriverCompaniesPage(driver: widget.driver),
                    DriverInvitationsPage(driver: widget.driver),
                    DriverProfilePage(driver: widget.driver),
                    TripMapPage(
                      onClose: () => setState(() => _currentIndex = 0),
                    ),
                    DriverTripHistoryPage(driverId: widget.driver.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shadowColor: AppColors.shadow,
      surfaceTintColor: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    widget.driver.name.isNotEmpty
                        ? widget.driver.name[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 28,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.driver.name,
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.driver.email,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildDrawerItem(_drawerItems[0], index: 0),
          _buildDrawerItem(_drawerItems[1], index: 1),
          _buildDrawerItem(_drawerItems[2], index: 2),
          _buildDrawerItem(_drawerItems[3], index: 3),
          _buildDrawerItem(_drawerItems[4], index: 5),
          const SizedBox(height: 8),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(_DrawerItemMeta item, {required int index}) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(
        isSelected ? item.activeIcon : item.icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? AppColors.primarySurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      minVerticalPadding: AppSpacing.md,
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentIndex = index);
      },
    );
  }
}

// ── Tab de viajes del conductor ───────────────────────────────────────────────

class _TripsTab extends StatelessWidget {
  const _TripsTab({required this.driver, required this.tripBloc});

  final UserEntity driver;
  final TripBloc tripBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        if (state is TripLoading || state is TripInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is TripInProgress || state is FreeTripInProgress) {
          return _buildInProgressView(context, state);
        }

        if (state is TripPendingApproval) {
          return _buildPendingApprovalView(state.trip);
        }

        if (state is TripWithImpediment) {
          return _buildImpedimentView(state.trip);
        }

        if (state is TripListLoaded) {
          return _buildScheduledList(context, state.scheduledTrips);
        }

        if (state is TripError) {
          return _buildError(context, state.message);
        }

        return _buildScheduledList(context, const []);
      },
    );
  }

  Widget _buildInProgressView(BuildContext context, TripState state) {
    final trip = state is TripInProgress ? state.trip : (state as FreeTripInProgress).trip;
    final elapsed = state is TripInProgress ? state.elapsed : (state as FreeTripInProgress).elapsed;

    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final formatted = '$h:$m:$s';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car,
              color: AppColors.primary, size: 64),
          const SizedBox(height: 16),
          Text(
            trip.isFreeTrip ? 'Viaje libre' : 'Viaje de empresa',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            formatted,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (trip.destinationAddress != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trip.destinationAddress!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingApprovalView(TripEntity trip) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_top, color: AppColors.warning, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Viaje finalizado',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esperando aprobación de la empresa',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImpedimentView(TripEntity trip) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.report_problem, color: AppColors.warning, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Impedimento Activo',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (trip.impedimentCategory != null)
            Text(
              trip.impedimentCategory!.label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          const Text(
            'La empresa resolverá tu impedimento. No puedes iniciar otro viaje.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledList(
      BuildContext context, List<TripEntity> trips) {
    if (trips.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.route_outlined,
                    size: 64, color: AppColors.divider),
                const SizedBox(height: 16),
                const Text(
                  'No tienes viajes programados',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Usa "Viaje Libre" en el panel superior para iniciar un monitoreo personal.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<TripBloc>()
            .add(LoadDriverTrips(driverId: driver.id));
        await Future.delayed(const Duration(milliseconds: 800));
      },
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _ScheduledTripCard(
            trip: trip,
            sequenceNumber: index + 1,
            canStart: index == 0,
            onStart: () async {
              bool hasCamera = await Permission.camera.isGranted;
              if (!hasCamera) {
                final r = await Permission.camera.request();
                hasCamera = r.isGranted;
              }
              if (context.mounted) {
                context.read<TripBloc>().add(StartTrip(
                      tripId: trip.id,
                      hasCameraPermission: hasCamera,
                    ));
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context
                    .read<TripBloc>()
                    .add(LoadDriverTrips(driverId: driver.id)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de viaje programado ──────────────────────────────────────────────────

class _ScheduledTripCard extends StatelessWidget {
  const _ScheduledTripCard({
    required this.trip,
    required this.sequenceNumber,
    required this.canStart,
    required this.onStart,
  });

  final TripEntity trip;
  final int sequenceNumber;
  final bool canStart;
  final VoidCallback onStart;

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isRelocation = trip.isRelocation;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRelocation
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.divider,
        ),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    '$sequenceNumber',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                if (isRelocation)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reubicación',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if (trip.companyName != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.companyName!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (trip.originAddress != null)
              _InfoRow(
                icon: Icons.my_location,
                label: 'Origen',
                value: trip.originAddress!,
              ),
            if (trip.destinationAddress != null)
              _InfoRow(
                icon: Icons.location_on,
                label: 'Destino',
                value: trip.destinationAddress!,
              ),
            _InfoRow(
              icon: Icons.schedule,
              label: 'Salida',
              value: _formatDateTime(trip.scheduledDepartureTime),
            ),
            if (trip.estimatedArrivalTime != null)
              _InfoRow(
                icon: Icons.flag,
                label: 'Llegada est.',
                value: _formatDateTime(trip.estimatedArrivalTime),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canStart ? onStart : null,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(
                    canStart ? 'Iniciar Viaje' : 'Esperando turno'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canStart ? AppColors.success : AppColors.divider,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metadata para items del drawer ────────────────────────────────────────────

class _DrawerItemMeta {
  const _DrawerItemMeta({
    required this.title,
    required this.icon,
    required this.activeIcon,
  });

  final String title;
  final IconData icon;
  final IconData activeIcon;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../trips/domain/entities/trip_entity.dart';
import '../../domain/usecases/get_driver_profile_usecase.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';

/// Página con dos pestañas: viajes pendientes de aprobación e impedimentos activos.
class CompanyPendingTripsPage extends StatefulWidget {
  const CompanyPendingTripsPage({
    super.key,
    required this.companyId,
  });

  final String companyId;

  @override
  State<CompanyPendingTripsPage> createState() =>
      _CompanyPendingTripsPageState();
}

class _CompanyPendingTripsPageState extends State<CompanyPendingTripsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPending();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPending() {
    context.read<CompanyBloc>().add(
          CompanyPendingTripsRequested(companyId: widget.companyId),
        );
  }

  void _loadImpediments() {
    context.read<CompanyBloc>().add(
          CompanyImpedimentTripsRequested(companyId: widget.companyId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listenWhen: (_, current) =>
          current is CompanyActionSuccess || current is CompanyError,
      listener: (context, state) {
        if (state is CompanyActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
          // Reload whichever tab is active after action
          if (_tabController.index == 0) {
            _loadPending();
          } else {
            _loadImpediments();
          }
        } else if (state is CompanyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(
                  icon: Icon(Icons.hourglass_top_outlined, size: 18),
                  text: 'Pendientes',
                ),
                Tab(
                  icon: Icon(Icons.report_problem_outlined, size: 18),
                  text: 'Impedimentos',
                ),
              ],
              onTap: (index) {
                if (index == 0) {
                  _loadPending();
                } else {
                  _loadImpediments();
                }
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PendingTripsTab(companyId: widget.companyId),
                _ImpedimentTripsTab(companyId: widget.companyId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pendientes tab ───────────────────────────────────────────────────────────

class _PendingTripsTab extends StatelessWidget {
  const _PendingTripsTab({required this.companyId});
  final String companyId;

  Future<void> _onRefresh(BuildContext context) async {
    context.read<CompanyBloc>().add(
          CompanyPendingTripsRequested(companyId: companyId),
        );
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      buildWhen: (_, current) =>
          current is CompanyLoading ||
          current is CompanyPendingTripsLoaded ||
          current is CompanyError,
      builder: (context, state) {
        if (state is CompanyLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is CompanyError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<CompanyBloc>().add(
                  CompanyPendingTripsRequested(companyId: companyId),
                ),
          );
        }
        final trips =
            state is CompanyPendingTripsLoaded ? state.pendingTrips : <TripEntity>[];
        return RefreshIndicator(
          onRefresh: () => _onRefresh(context),
          color: AppColors.primary,
          child: trips.isEmpty
              ? _EmptyView(
                  icon: Icons.check_circle_outline,
                  message: 'No hay viajes pendientes de aprobación',
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: trips.length,
                  itemBuilder: (context, index) => _PendingTripCard(
                    trip: trips[index],
                    companyId: companyId,
                  ),
                ),
        );
      },
    );
  }
}

// ── Impediments tab ──────────────────────────────────────────────────────────

class _ImpedimentTripsTab extends StatelessWidget {
  const _ImpedimentTripsTab({required this.companyId});
  final String companyId;

  Future<void> _onRefresh(BuildContext context) async {
    context.read<CompanyBloc>().add(
          CompanyImpedimentTripsRequested(companyId: companyId),
        );
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      buildWhen: (_, current) =>
          current is CompanyLoading ||
          current is CompanyImpedimentTripsLoaded ||
          current is CompanyError,
      builder: (context, state) {
        if (state is CompanyLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is CompanyError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<CompanyBloc>().add(
                  CompanyImpedimentTripsRequested(companyId: companyId),
                ),
          );
        }
        final trips = state is CompanyImpedimentTripsLoaded
            ? state.impedimentTrips
            : <TripEntity>[];
        return RefreshIndicator(
          onRefresh: () => _onRefresh(context),
          color: AppColors.warning,
          child: trips.isEmpty
              ? _EmptyView(
                  icon: Icons.report_problem_outlined,
                  message: 'No hay viajes con impedimento activo',
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: trips.length,
                  itemBuilder: (context, index) => _ImpedimentTripCard(
                    trip: trips[index],
                    companyId: companyId,
                  ),
                ),
        );
      },
    );
  }
}

// ── Cards ────────────────────────────────────────────────────────────────────

class _PendingTripCard extends StatefulWidget {
  const _PendingTripCard({required this.trip, required this.companyId});
  final TripEntity trip;
  final String companyId;

  @override
  State<_PendingTripCard> createState() => _PendingTripCardState();
}

class _PendingTripCardState extends State<_PendingTripCard> {
  String _driverName = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    final result = await di.sl<GetDriverProfileUseCase>()(
      GetDriverProfileParams(driverId: widget.trip.driverId),
    );
    if (mounted) {
      setState(() {
        result.fold(
          (_) => _driverName = 'Conductor desconocido',
          (profile) => _driverName = profile.name,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.trip.actualStartTime;
    final end = widget.trip.actualEndTime;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.directions_car_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _tripTypeLabel(widget.trip.tripType),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Pendiente',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 10),
            if (start != null)
              _InfoLine(
                icon: Icons.play_arrow,
                text:
                    'Inicio: ${DateFormat('dd/MM HH:mm').format(start)}',
              ),
            if (end != null)
              _InfoLine(
                icon: Icons.stop,
                text: 'Fin: ${DateFormat('dd/MM HH:mm').format(end)}',
              ),
            if (widget.trip.hasDestination)
              _InfoLine(
                icon: Icons.flag_outlined,
                text:
                    'Destino: ${widget.trip.destinationAddress ?? 'Coordenadas'}',
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/company/trip-approval',
                    extra: {
                      'trip': widget.trip,
                      'companyId': widget.companyId,
                    }),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Ver Detalles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpedimentTripCard extends StatefulWidget {
  const _ImpedimentTripCard({required this.trip, required this.companyId});
  final TripEntity trip;
  final String companyId;

  @override
  State<_ImpedimentTripCard> createState() => _ImpedimentTripCardState();
}

class _ImpedimentTripCardState extends State<_ImpedimentTripCard> {
  String _driverName = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    final result = await di.sl<GetDriverProfileUseCase>()(
      GetDriverProfileParams(driverId: widget.trip.driverId),
    );
    if (mounted) {
      setState(() {
        result.fold(
          (_) => _driverName = 'Conductor desconocido',
          (profile) => _driverName = profile.name,
        );
      });
    }
  }

  void _resolveImpediment(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Resolver impedimento'),
        content: const Text(
          'El viaje volverá al estado programado y el conductor podrá reanudarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolver'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<CompanyBloc>().add(
              CompanyImpedimentResolved(
                tripId: widget.trip.id,
                companyId: widget.companyId,
              ),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.trip.impedimentCategory;
    final reportedAt = widget.trip.impedimentReportedAt;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.warning.withValues(alpha: 0.5), width: 1.5),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.report_problem,
                      color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (cat != null)
                        Text(
                          cat.label,
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (reportedAt != null) ...[
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.access_time_outlined,
                text:
                    'Reportado: ${DateFormat('dd/MM/yyyy HH:mm').format(reportedAt)}',
              ),
            ],
            if (widget.trip.impedimentDescription != null) ...[
              const SizedBox(height: 4),
              _InfoLine(
                icon: Icons.notes_outlined,
                text: widget.trip.impedimentDescription!,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/company/trip-approval',
                        extra: {
                          'trip': widget.trip,
                          'companyId': widget.companyId,
                        }),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveImpediment(context),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Resolver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.divider),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _tripTypeLabel(TripType type) {
  switch (type) {
    case TripType.normal:
      return 'Viaje normal';
    case TripType.relocation:
      return 'Traslado';
    case TripType.free:
      return 'Viaje libre';
  }
}

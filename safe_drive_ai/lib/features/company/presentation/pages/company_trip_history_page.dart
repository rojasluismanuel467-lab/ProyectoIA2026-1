import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../injection_container.dart' as di;
import '../../../trips/domain/entities/trip_entity.dart';
import '../../domain/usecases/get_driver_profile_usecase.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';

/// Pantalla de historial de viajes finalizados de la empresa.
/// Se integra como índice 4 del IndexedStack en CompanyHomePage.
/// Accede al CompanyBloc provisto en el árbol de widgets sin BlocProvider propio.
class CompanyTripHistoryPage extends StatefulWidget {
  const CompanyTripHistoryPage({
    super.key,
    required this.companyId,
  });

  final String companyId;

  @override
  State<CompanyTripHistoryPage> createState() => _CompanyTripHistoryPageState();
}

class _CompanyTripHistoryPageState extends State<CompanyTripHistoryPage> {
  TripStatus? _selectedFilter;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadHistory();
    }
  }

  void _loadHistory() {
    context.read<CompanyBloc>().add(
          LoadCompanyTripHistory(companyId: widget.companyId),
        );
  }

  Future<void> _onRefresh() async {
    _loadHistory();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  List<TripEntity> _applyFilter(List<TripEntity> trips) {
    if (_selectedFilter == null) return trips;
    return trips.where((t) => t.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: BlocBuilder<CompanyBloc, CompanyState>(
        buildWhen: (_, current) =>
            current is CompanyLoading ||
            current is CompanyTripHistoryLoaded ||
            current is CompanyError,
        builder: (context, state) {
          if (state is CompanyLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is CompanyError) {
            return _ErrorView(
              message: state.message,
              onRetry: _loadHistory,
            );
          }

          final allTrips = state is CompanyTripHistoryLoaded
              ? state.trips
              : <TripEntity>[];
          final filtered = _applyFilter(allTrips);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterChipsRow(
                selectedFilter: _selectedFilter,
                onFilterChanged: (status) =>
                    setState(() => _selectedFilter = status),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  '${filtered.length} viaje${filtered.length == 1 ? '' : 's'} encontrado${filtered.length == 1 ? '' : 's'}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.primary,
                  child: filtered.isEmpty
                      ? _EmptyView()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                              left: 0, right: 0, top: 0, bottom: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _HistoryTripCard(trip: filtered[index], onTripTap: () {
                            context.push('/trip/detail', extra: filtered[index]);
                          }),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final TripStatus? selectedFilter;
  final ValueChanged<TripStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <(String, TripStatus?)>[
      ('Todos', null),
      ('Aprobados', TripStatus.approved),
      ('Cancelados', TripStatus.cancelled),
      ('Completados', TripStatus.completed),
    ];

    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: filters.map((entry) {
            final (label, status) = entry;
            final isSelected = selectedFilter == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => onFilterChanged(status),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.divider,
                ),
                backgroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Trip card ─────────────────────────────────────────────────────────────────

class _HistoryTripCard extends StatefulWidget {
  const _HistoryTripCard({required this.trip, this.onTripTap});
  final TripEntity trip;
  final VoidCallback? onTripTap;

  @override
  State<_HistoryTripCard> createState() => _HistoryTripCardState();
}

class _HistoryTripCardState extends State<_HistoryTripCard> {
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
    final trip = widget.trip;
    final start = trip.actualStartTime;
    final end = trip.actualEndTime;

    final durationLabel = _formatDuration(start, end);
    final endLabel = end != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(end)
        : 'Sin fecha fin';

    final originLabel = trip.originAddress ?? 'Origen desconocido';
    final destinationLabel =
        trip.destinationAddress ?? 'Destino desconocido';

    final (statusLabel, statusColor) = _statusMeta(trip.status);
    final typeLabel = _tripTypeLabel(trip.tripType);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shadowColor: AppColors.shadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        onTap: widget.onTripTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (trip.tripCode != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trip.tripCode!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        typeLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.sm),
            // ── Info rows ─────────────────────────────────────────────────
            _InfoLine(
              icon: Icons.access_time_outlined,
              text: endLabel,
            ),
            if (durationLabel != null)
              _InfoLine(
                icon: Icons.timer_outlined,
                text: durationLabel,
              ),
            if (trip.hasOrigin || trip.originAddress != null) ...[
              _InfoLine(
                icon: Icons.trip_origin,
                text: originLabel,
              ),
              _InfoLine(
                icon: Icons.flag_outlined,
                text: destinationLabel,
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  String? _formatDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    final diff = end.difference(start);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  (String, Color) _statusMeta(TripStatus status) {
    switch (status) {
      case TripStatus.approved:
        return ('Aprobado', AppColors.success);
      case TripStatus.cancelled:
        return ('Cancelado', AppColors.error);
      case TripStatus.completed:
        return ('Completado', AppColors.primary);
      default:
        return ('Finalizado', AppColors.textSecondary);
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
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: AppColors.divider),
              SizedBox(height: AppSpacing.lg),
              Text(
                'No hay viajes en el historial',
                style: TextStyle(
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
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

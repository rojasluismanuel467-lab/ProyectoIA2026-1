import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../../trips/presentation/bloc/trip_bloc.dart';
import '../../../trips/presentation/bloc/trip_event.dart';
import '../../../trips/presentation/bloc/trip_state.dart';

class DriverTripHistoryPage extends StatefulWidget {
  const DriverTripHistoryPage({super.key, required this.driverId});

  final String driverId;

  @override
  State<DriverTripHistoryPage> createState() => _DriverTripHistoryPageState();
}

class _DriverTripHistoryPageState extends State<DriverTripHistoryPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<TripBloc>()
        .add(LoadDriverTripHistory(driverId: widget.driverId));
  }

  void _reload() {
    context
        .read<TripBloc>()
        .add(LoadDriverTripHistory(driverId: widget.driverId));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: BlocBuilder<TripBloc, TripState>(
        buildWhen: (previous, current) =>
            current is TripHistoryLoading ||
            current is TripHistoryLoaded ||
            current is TripHistoryError,
        builder: (context, state) {
          if (state is TripHistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is TripHistoryError) {
            return _ErrorView(message: state.message, onRetry: _reload);
          }

          if (state is TripHistoryLoaded) {
            if (state.trips.isEmpty) {
              return _EmptyView(onRefresh: _reload);
            }
            return _HistoryList(trips: state.trips, onRefresh: _reload);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Lista de viajes ───────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.trips, required this.onRefresh});

  final List<TripEntity> trips;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        await Future.delayed(const Duration(milliseconds: 800));
      },
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: trips.length,
        itemBuilder: (context, index) =>
            _TripHistoryCard(trip: trips[index], onTripTap: () {
          context.push('/trip/detail', extra: trips[index]);
        }),
      ),
    );
  }
}

// ── Card de viaje ─────────────────────────────────────────────────────────────

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.trip, this.onTripTap});

  final TripEntity trip;
  final VoidCallback? onTripTap;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}min';
    if (h > 0) return '${h}h';
    if (m > 0) return '${m}min';
    return 'menos de 1 min';
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = trip.actualEndTime ?? trip.scheduledDepartureTime;
    final hasDuration =
        trip.actualStartTime != null && trip.actualEndTime != null;
    final duration = hasDuration ? trip.elapsed : null;

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
        onTap: onTripTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fila superior: fecha + badge de estado ────────────────────
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(displayDate),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(trip: trip),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              
              // ── Código del viaje ──────────────────────────────────────────
              if (trip.tripCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tag_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trip.tripCode!,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: AppSpacing.sm),

              // ── Origen → Destino ──────────────────────────────────────────
              _RouteRow(
                origin: trip.originAddress ?? 'Origen desconocido',
                destination: trip.isFreeTrip
                    ? null
                    : (trip.destinationAddress ?? 'Destino desconocido'),
              ),

              const SizedBox(height: AppSpacing.sm),

              // ── Fila inferior: empresa + tipo + duración ──────────────────
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (trip.isFreeTrip)
                    const _SmallChip(
                      label: 'Viaje libre',
                      color: AppColors.primary,
                    )
                  else ...[
                    _SmallChip(
                      label: trip.companyName ?? 'Empresa',
                      color: AppColors.textSecondary,
                      icon: Icons.business_outlined,
                    ),
                    if (trip.isRelocation)
                      const _SmallChip(
                        label: 'Reubicación',
                        color: AppColors.warning,
                      ),
                  ],
                  if (duration != null)
                    _SmallChip(
                      label: _formatDuration(duration),
                      color: AppColors.textSecondary,
                      icon: Icons.timer_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fila origen → destino ─────────────────────────────────────────────────────

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.origin, required this.destination});

  final String origin;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.my_location, size: 14, color: AppColors.success),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            origin,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (destination != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward,
                size: 14, color: AppColors.textSecondary),
          ),
          const Icon(Icons.location_on, size: 14, color: AppColors.error),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              destination!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Badge de estado ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.trip});

  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(trip);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color) _resolve(TripEntity trip) {
    if (trip.isFreeTrip && trip.status == TripStatus.completed) {
      return ('Completado', AppColors.primary);
    }
    switch (trip.status) {
      case TripStatus.approved:
        return ('Aprobado', AppColors.success);
      case TripStatus.cancelled:
        return ('Cancelado', AppColors.error);
      case TripStatus.completed:
        return ('Completado', const Color(0xFF1565C0));
      case TripStatus.pendingApproval:
        return ('Pendiente', AppColors.warning);
      default:
        return (trip.status.name, AppColors.textSecondary);
    }
  }
}

// ── Chip pequeño ──────────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        await Future.delayed(const Duration(milliseconds: 800));
      },
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 420,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 72, color: AppColors.divider),
                SizedBox(height: 16),
                Text(
                  'Sin historial de viajes',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Los viajes completados, aprobados o cancelados\naparecerán aquí.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado de error ───────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

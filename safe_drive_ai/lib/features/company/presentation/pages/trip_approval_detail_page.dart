import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../injection_container.dart' as di;
import '../../../trips/domain/entities/route_point_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../../trips/domain/usecases/get_trip_route_usecase.dart';
import '../../domain/usecases/get_driver_profile_usecase.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';

class TripApprovalDetailPage extends StatefulWidget {
  const TripApprovalDetailPage({
    super.key,
    required this.trip,
    required this.companyId,
  });

  final TripEntity trip;
  final String companyId;

  @override
  State<TripApprovalDetailPage> createState() => _TripApprovalDetailPageState();
}

class _TripApprovalDetailPageState extends State<TripApprovalDetailPage> {
  String _driverName = 'Cargando...';
  List<RoutePointEntity> _routePoints = [];
  bool _loadingRoute = true;

  @override
  void initState() {
    super.initState();
    _loadDriver();
    _loadRoute();
  }

  Future<void> _loadDriver() async {
    final useCase = di.sl<GetDriverProfileUseCase>();
    final result = await useCase(
        GetDriverProfileParams(driverId: widget.trip.driverId));
    if (mounted) {
      setState(() {
        result.fold(
          (failure) => _driverName = 'Desconocido',
          (profile) => _driverName = profile.name,
        );
      });
    }
  }

  Future<void> _loadRoute() async {
    final useCase = di.sl<GetTripRouteUseCase>();
    final result =
        await useCase(GetTripRouteParams(tripId: widget.trip.id));
    if (mounted) {
      setState(() {
        result.fold(
          (failure) => _loadingRoute = false,
          (points) {
            _routePoints = points;
            _loadingRoute = false;
          },
        );
      });
    }
  }

  String _formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm').format(date);

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) return '${duration.inMinutes} min';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _approveTrip() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Aprobar viaje'),
        content: const Text(
          'El viaje se marcará como aprobado y completado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<CompanyBloc>().add(
              CompanyTripApproved(
                tripId: widget.trip.id,
                companyId: widget.companyId,
              ),
            );
        Navigator.of(context).pop();
      }
    });
  }

  void _cancelTrip() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Cancelar viaje'),
        content: const Text(
          'El viaje quedará cancelado. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar viaje'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<CompanyBloc>().add(
              CompanyTripCancelled(
                tripId: widget.trip.id,
                companyId: widget.companyId,
              ),
            );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.trip.actualStartTime;
    final end = widget.trip.actualEndTime;
    final duration =
        (start != null && end != null) ? end.difference(start) : Duration.zero;

    return BlocListener<CompanyBloc, CompanyState>(
      listener: (context, state) {
        if (state is CompanyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalles del Viaje'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Route map ───────────────────────────────────────────────
              SizedBox(
                height: 250,
                child: _loadingRoute
                    ? const ColoredBox(
                        color: Color(0xFFE8EAF6),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    : _routePoints.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFFE8EAF6),
                            child: Center(
                              child: Text(
                                'Sin datos de ruta',
                                style: TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                _routePoints.first.lat,
                                _routePoints.first.lng,
                              ),
                              initialZoom: 14,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.bombastik.safedrive',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints
                                        .map((p) => LatLng(p.lat, p.lng))
                                        .toList(),
                                    color: AppColors.primary,
                                    strokeWidth: 4,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _routePoints.first.lat,
                                      _routePoints.first.lng,
                                    ),
                                    width: 30,
                                    height: 30,
                                    child: const Icon(
                                      Icons.play_circle_fill,
                                      color: AppColors.success,
                                      size: 30,
                                    ),
                                  ),
                                  Marker(
                                    point: LatLng(
                                      _routePoints.last.lat,
                                      _routePoints.last.lng,
                                    ),
                                    width: 30,
                                    height: 30,
                                    child: const Icon(
                                      Icons.stop_circle,
                                      color: AppColors.error,
                                      size: 30,
                                    ),
                                  ),
                                  if (widget.trip.hasDestination)
                                    Marker(
                                      point: LatLng(
                                        widget.trip.destinationLat!,
                                        widget.trip.destinationLng!,
                                      ),
                                      width: 30,
                                      height: 30,
                                      child: const Icon(
                                        Icons.flag,
                                        color: AppColors.warning,
                                        size: 30,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
              ),

              // ── Trip details ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primarySurface,
                          child:
                              Icon(Icons.person, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ID: ${widget.trip.driverId.substring(0, 8)}...',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _StatusBadge(status: widget.trip.status),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Resumen del Viaje',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.category_outlined,
                      'Tipo',
                      _tripTypeLabel(widget.trip.tripType),
                    ),
                    if (widget.trip.scheduledDepartureTime != null)
                      _buildInfoRow(
                        Icons.departure_board,
                        'Salida programada',
                        _formatDate(widget.trip.scheduledDepartureTime!),
                      ),
                    if (start != null)
                      _buildInfoRow(
                        Icons.play_arrow,
                        'Inicio real',
                        _formatDate(start),
                      ),
                    if (end != null)
                      _buildInfoRow(
                        Icons.stop,
                        'Fin real',
                        _formatDate(end),
                      ),
                    if (duration != Duration.zero)
                      _buildInfoRow(
                        Icons.timer,
                        'Duración real',
                        _formatDuration(duration),
                      ),
                    if (widget.trip.hasOrigin)
                      _buildInfoRow(
                        Icons.trip_origin,
                        'Origen',
                        widget.trip.originAddress ??
                            'Lat ${widget.trip.originLat!.toStringAsFixed(4)}, '
                                'Lng ${widget.trip.originLng!.toStringAsFixed(4)}',
                      ),
                    if (widget.trip.hasDestination)
                      _buildInfoRow(
                        Icons.flag_outlined,
                        'Destino',
                        widget.trip.destinationAddress ??
                            'Lat ${widget.trip.destinationLat!.toStringAsFixed(4)}, '
                                'Lng ${widget.trip.destinationLng!.toStringAsFixed(4)}',
                      ),
                    if (widget.trip.impedimentCategory != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  AppColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.report_problem,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Impedimento: ${widget.trip.impedimentCategory!.label}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (widget.trip.impedimentDescription !=
                                      null)
                                    Text(
                                      widget.trip.impedimentDescription!,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _cancelTrip,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(
                                  color: AppColors.error),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _approveTrip,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Aprobar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tripTypeLabel(TripType type) {
    switch (type) {
      case TripType.normal:
        return 'Normal';
      case TripType.relocation:
        return 'Traslado / Reubicación';
      case TripType.free:
        return 'Viaje libre';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TripStatus.pendingApproval => ('Pendiente', AppColors.warning),
      TripStatus.approved => ('Aprobado', AppColors.success),
      TripStatus.cancelled => ('Cancelado', AppColors.error),
      TripStatus.withImpediment => ('Impedimento', AppColors.warning),
      TripStatus.inProgress => ('En curso', AppColors.primary),
      TripStatus.completed => ('Completado', AppColors.success),
      TripStatus.scheduled => ('Programado', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/usecases/get_trip_route_usecase.dart';
import '../../domain/entities/trip_entity.dart';

/// Página de detalle de viaje.
/// Muestra información completa de un viaje específico cuando el usuario
/// lo selecciona desde el historial.
class TripDetailPage extends StatefulWidget {
  const TripDetailPage({super.key, required this.trip});

  final TripEntity trip;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  List<LatLng> _route = [];
  bool _loadingRoute = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    if (!mounted) return;
    
    // Si es viaje libre o no hay coordenadas, no cargar ruta
    if (!widget.trip.hasOrigin && !widget.trip.hasDestination) {
      setState(() => _loadingRoute = false);
      return;
    }

    final result = await di.sl<GetTripRouteUseCase>()(
      GetTripRouteParams(tripId: widget.trip.id),
    );

    if (!mounted) return;

    result.fold(
      (_) => setState(() => _loadingRoute = false),
      (points) {
        if (points.isNotEmpty) {
          setState(() {
            _route = points.map((p) => LatLng(p.lat, p.lng)).toList();
            _loadingRoute = false;
          });
        } else {
          // Si no hay ruta guardada, usar línea recta entre origen y destino
          _buildFallbackRoute();
        }
      },
    );
  }

  void _buildFallbackRoute() {
    // Crear ruta simple entre origen y destino si no hay puntos guardados
    if (widget.trip.hasOrigin && widget.trip.hasDestination) {
      setState(() {
        _route = [
          LatLng(widget.trip.originLat!, widget.trip.originLng!),
          LatLng(widget.trip.destinationLat!, widget.trip.destinationLng!),
        ];
        _loadingRoute = false;
      });
    } else {
      setState(() => _loadingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del viaje'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textOnPrimary,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareTrip(context),
            tooltip: 'Compartir viaje',
          ),
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con badge de estado y tipo de viaje
                _buildHeader(context),
                const SizedBox(height: 16),

                // Mapa de ruta (si hay coordenadas)
                if (widget.trip.hasOrigin || widget.trip.hasDestination) ...[
                  _buildMapCard(context),
                  const SizedBox(height: 16),
                ],

                // Información de ruta
                _buildRouteInfoCard(context),
                const SizedBox(height: 16),

                // Información de tiempos
                _buildTimeInfoCard(context),
                const SizedBox(height: 16),

                // Información de empresa (si aplica)
                if (widget.trip.isCompanyTrip) ...[
                  _buildCompanyInfoCard(context),
                  const SizedBox(height: 16),
                ],

                // Información de impedimento (si existe)
                if (widget.trip.impedimentCategory != null) ...[
                  _buildImpedimentCard(context),
                  const SizedBox(height: 16),
                ],

                // ID del viaje
                _buildTripIdCard(context),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final (statusLabel, statusColor) = _resolveStatusMeta(widget.trip);
    final typeLabel = _resolveTypeLabel(widget.trip.tripType);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono del tipo de viaje
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _resolveTypeIcon(widget.trip.tripType),
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // Información de estado y tipo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return Card(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ruta del viaje',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_loadingRoute)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 200,
                child: _buildMap(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final center = _mapCenter;

    if (center == null) {
      return const ColoredBox(
        color: Color(0xFFE8EAF6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: AppColors.textSecondary, size: 40),
              SizedBox(height: 8),
              Text(
                'Mapa no disponible',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final markers = <Marker>[];

    // Marcador de origen
    if (widget.trip.hasOrigin) {
      markers.add(
        Marker(
          point: LatLng(widget.trip.originLat!, widget.trip.originLng!),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.my_location,
            color: AppColors.success,
            size: 32,
          ),
        ),
      );
    }

    // Marcador de destino
    if (widget.trip.hasDestination) {
      markers.add(
        Marker(
          point: LatLng(widget.trip.destinationLat!, widget.trip.destinationLng!),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: AppColors.error,
            size: 32,
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: _calculateZoom(),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bombastik.safedrive',
        ),
        MarkerLayer(markers: markers),
        if (_route.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route,
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            ],
          ),
      ],
    );
  }

  double _calculateZoom() {
    if (_route.isNotEmpty) {
      // Zoom más cercano si hay ruta detallada
      return 14.0;
    }
    return 13.0;
  }

  LatLng? get _mapCenter {
    if (_route.isNotEmpty) {
      // Usar el centro de la ruta si está disponible
      final sumLat = _route.map((p) => p.latitude).reduce((a, b) => a + b);
      final sumLng = _route.map((p) => p.longitude).reduce((a, b) => a + b);
      return LatLng(sumLat / _route.length, sumLng / _route.length);
    }
    
    if (widget.trip.hasOrigin && widget.trip.hasDestination) {
      // Centro entre origen y destino
      return LatLng(
        (widget.trip.originLat! + widget.trip.destinationLat!) / 2,
        (widget.trip.originLng! + widget.trip.destinationLng!) / 2,
      );
    } else if (widget.trip.hasOrigin) {
      return LatLng(widget.trip.originLat!, widget.trip.originLng!);
    } else if (widget.trip.hasDestination) {
      return LatLng(widget.trip.destinationLat!, widget.trip.destinationLng!);
    }
    return null;
  }

  Widget _buildRouteInfoCard(BuildContext context) {
    return Card(
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
            const Text(
              'Información de ruta',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Origen
            _RouteInfoRow(
              icon: Icons.my_location,
              iconColor: AppColors.success,
              label: 'Origen',
              value: widget.trip.originAddress ?? 'Dirección no disponible',
            ),
            const SizedBox(height: 12),
            // Destino (solo si no es viaje libre)
            if (!widget.trip.isFreeTrip && widget.trip.hasDestination) ...[
              _RouteInfoRow(
                icon: Icons.location_on,
                iconColor: AppColors.error,
                label: 'Destino',
                value: widget.trip.destinationAddress ?? 'Dirección no disponible',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfoCard(BuildContext context) {
    return Card(
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
            const Text(
              'Tiempos del viaje',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Salida programada
            _TimeInfoRow(
              icon: Icons.schedule,
              label: 'Salida programada',
              value: _formatDateTime(widget.trip.scheduledDepartureTime),
            ),
            const SizedBox(height: 10),
            // Llegada estimada
            _TimeInfoRow(
              icon: Icons.event_available,
              label: 'Llegada estimada',
              value: _formatDateTime(widget.trip.estimatedArrivalTime),
            ),
            const Divider(height: 24),
            // Inicio real
            _TimeInfoRow(
              icon: Icons.play_circle_outline,
              label: 'Inicio real',
              value: _formatDateTime(widget.trip.actualStartTime),
            ),
            const SizedBox(height: 10),
            // Finalización real
            _TimeInfoRow(
              icon: Icons.stop_circle_outlined,
              label: 'Finalización real',
              value: _formatDateTime(widget.trip.actualEndTime),
            ),
            const Divider(height: 24),
            // Duración total
            _TimeInfoRow(
              icon: Icons.timer_outlined,
              label: 'Duración total',
              value: _formatDuration(widget.trip.elapsed),
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard(BuildContext context) {
    return Card(
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
            const Text(
              'Información de empresa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _CompanyInfoRow(
              icon: Icons.business_outlined,
              label: 'Empresa',
              value: widget.trip.companyName ?? 'No especificada',
            ),
            const SizedBox(height: 10),
            _CompanyInfoRow(
              icon: Icons.badge_outlined,
              label: 'ID Empresa',
              value: widget.trip.companyId ?? 'No disponible',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpedimentCard(BuildContext context) {
    final category = widget.trip.impedimentCategory;
    if (category == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      color: AppColors.warningSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Impedimento reportado',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ImpedimentInfoRow(
              label: 'Categoría',
              value: category.label,
            ),
            const SizedBox(height: 8),
            if (widget.trip.impedimentDescription != null &&
                widget.trip.impedimentDescription!.isNotEmpty) ...[
              _ImpedimentInfoRow(
                label: 'Descripción',
                value: widget.trip.impedimentDescription!,
                isMultiline: true,
              ),
              const SizedBox(height: 8),
            ],
            _ImpedimentInfoRow(
              label: 'Fecha del reporte',
              value: _formatDateTime(widget.trip.impedimentReportedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripIdCard(BuildContext context) {
    return Card(
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
            // Código amigable del viaje (tripCode)
            if (widget.trip.tripCode != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Código del viaje',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.trip.tripCode!,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
            ],
            // ID técnico del viaje
            Row(
              children: [
                Icon(
                  Icons.tag_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ID interno',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.trip.id,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareTrip(BuildContext context) {
    // TODO: Implementar funcionalidad de compartir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'No disponible';
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60);
    final s = (d.inSeconds % 60);

    if (h > 0) {
      return '${h}h ${m}min ${s}s';
    } else if (m > 0) {
      return '${m}min ${s}s';
    } else {
      return '${s}s';
    }
  }

  (String, Color) _resolveStatusMeta(TripEntity tripEntity) {
    if (tripEntity.isFreeTrip && tripEntity.status == TripStatus.completed) {
      return ('Completado', AppColors.primary);
    }
    switch (tripEntity.status) {
      case TripStatus.scheduled:
        return ('Programado', AppColors.info);
      case TripStatus.inProgress:
        return ('En progreso', AppColors.primary);
      case TripStatus.pendingApproval:
        return ('Pendiente aprobación', AppColors.warning);
      case TripStatus.approved:
        return ('Aprobado', AppColors.success);
      case TripStatus.cancelled:
        return ('Cancelado', AppColors.error);
      case TripStatus.withImpediment:
        return ('Con impedimento', AppColors.warning);
      case TripStatus.completed:
        return ('Completado', AppColors.success);
    }
  }

  String _resolveTypeLabel(TripType type) {
    switch (type) {
      case TripType.normal:
        return 'Viaje normal';
      case TripType.relocation:
        return 'Viaje de reubicación';
      case TripType.free:
        return 'Viaje libre';
    }
  }

  IconData _resolveTypeIcon(TripType type) {
    switch (type) {
      case TripType.normal:
        return Icons.directions_car_outlined;
      case TripType.relocation:
        return Icons.local_shipping_outlined;
      case TripType.free:
        return Icons.person_outline;
    }
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _RouteInfoRow extends StatelessWidget {
  const _RouteInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeInfoRow extends StatelessWidget {
  const _TimeInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isHighlighted
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isHighlighted
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanyInfoRow extends StatelessWidget {
  const _CompanyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImpedimentInfoRow extends StatelessWidget {
  const _ImpedimentInfoRow({
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  final String label;
  final String value;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';

/// Página de Cronograma de Viajes - Muestra TODOS los viajes programados de la empresa.
class CompanyScheduledTripsPage extends StatefulWidget {
  const CompanyScheduledTripsPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  State<CompanyScheduledTripsPage> createState() =>
      _CompanyScheduledTripsPageState();
}

class _CompanyScheduledTripsPageState extends State<CompanyScheduledTripsPage> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    context.read<CompanyBloc>().add(
          CompanyScheduledTripsRequested(companyId: widget.companyId),
        );
  }

  void _showCreateTripDialog() {
    showDialog(
      context: context,
      builder: (_) => _SelectDriverDialog(
        companyId: widget.companyId,
        companyName: widget.companyName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyBloc, CompanyState>(
      listenWhen: (_, current) =>
          current is CompanyActionSuccess || current is CompanyError,
      listener: (context, state) {
        if (state is CompanyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        } else if (state is CompanyActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          _loadTrips();
        }
      },
      buildWhen: (_, current) =>
          current is CompanyLoading ||
          current is CompanyScheduledTripsLoaded ||
          current is CompanyError,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            title: const Text(
              'Cronograma de Viajes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_location_alt),
                onPressed: _showCreateTripDialog,
                tooltip: 'Programar viaje',
              ),
            ],
          ),
          body: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip('Todos', 'all'),
            const SizedBox(width: 8),
            _FilterChip('Programados', 'scheduled'),
            const SizedBox(width: 8),
            _FilterChip('En Curso', 'inProgress'),
            const SizedBox(width: 8),
            _FilterChip('Aprobados', 'approved'),
            const SizedBox(width: 8),
            _FilterChip('Completados', 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _FilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterStatus = value);
        _loadTrips();
      },
      backgroundColor: AppColors.primaryLight,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.textOnPrimary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
    );
  }

  Widget _buildBody(CompanyState state) {
    if (state is CompanyLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    List<TripEntity> trips = [];
    if (state is CompanyScheduledTripsLoaded) {
      trips = state.scheduledTrips;
    }

    // Aplicar filtros
    final filteredTrips = trips.where((trip) {
      if (_filterStatus != 'all' && trip.status.name != _filterStatus) {
        return false;
      }
      return true;
    }).toList();

    if (filteredTrips.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadTrips();
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTrips.length,
        itemBuilder: (context, index) {
          final trip = filteredTrips[index];
          return _TripCard(
            trip: trip,
            onTap: () => _navigateToTripDetail(trip),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay viajes programados',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterStatus != 'all'
                ? 'Intenta con otro filtro'
                : 'Comienza programando un viaje',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTripDialog,
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Programar Viaje'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTripDetail(TripEntity trip) {
    context.push('/company/trip-approval', extra: {
      'trip': trip,
      'companyId': widget.companyId,
    });
  }
}

// ── Tarjeta de Viaje ───────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
  });

  final TripEntity trip;
  final VoidCallback onTap;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sin programar';
    return DateFormat('dd/MM/yyyy • HH:mm').format(date);
  }

  String _getStatusText() {
    switch (trip.status) {
      case TripStatus.scheduled:
        return 'Programado';
      case TripStatus.inProgress:
        return 'En Curso';
      case TripStatus.approved:
        return 'Aprobado';
      case TripStatus.completed:
        return 'Completado';
      case TripStatus.pendingApproval:
        return 'Pendiente';
      case TripStatus.withImpediment:
        return 'Impedimento';
      case TripStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color _getStatusColor() {
    switch (trip.status) {
      case TripStatus.scheduled:
        return AppColors.primary;
      case TripStatus.inProgress:
        return AppColors.warning;
      case TripStatus.approved:
      case TripStatus.completed:
        return AppColors.success;
      case TripStatus.pendingApproval:
        return AppColors.warning;
      case TripStatus.withImpediment:
        return AppColors.error;
      case TripStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor()),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildTripTypeBadge(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Salida Programada',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(trip.scheduledDepartureTime),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (trip.originAddress != null) ...[
                _buildLocationRow(
                  icon: Icons.my_location,
                  iconColor: AppColors.primary,
                  label: 'Origen',
                  value: trip.originAddress!,
                ),
              ],
              if (trip.destinationAddress != null) ...[
                const SizedBox(height: 8),
                _buildLocationRow(
                  icon: Icons.flag_outlined,
                  iconColor: AppColors.error,
                  label: 'Destino',
                  value: trip.destinationAddress!,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Conductor: ${trip.driverId.substring(0, 8)}...',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trip.companyName != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trip.companyName!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripTypeBadge() {
    String label;
    String emoji;
    if (trip.tripType == TripType.free) {
      label = 'Libre';
      emoji = '🚗';
    } else if (trip.isRelocation) {
      label = 'Relocation';
      emoji = '🔄';
    } else {
      label = 'Normal';
      emoji = '📦';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Diálogo para seleccionar conductor ────────────────────────────────────────

class _SelectDriverDialog extends StatefulWidget {
  const _SelectDriverDialog({
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  State<_SelectDriverDialog> createState() => _SelectDriverDialogState();
}

class _SelectDriverDialogState extends State<_SelectDriverDialog> {
  late Future<List<CompanyLinkEntity>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  void _loadDrivers() {
    context.read<CompanyBloc>().add(
          CompanyDriversRequested(companyId: widget.companyId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seleccionar Conductor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Elige un conductor para programar viaje',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(0),
                    constraints: BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                ],
              ),
            ),
            BlocBuilder<CompanyBloc, CompanyState>(
              buildWhen: (_, current) =>
                  current is CompanyLoading ||
                  current is CompanyDriversLoaded ||
                  current is CompanyError,
              builder: (context, state) {
                if (state is CompanyLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                List<CompanyLinkEntity> drivers = [];
                if (state is CompanyDriversLoaded) {
                  drivers = state.drivers;
                }

                if (drivers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay conductores vinculados',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Primero debes vincular conductores a tu empresa',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.pop();
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Vincular Conductor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return _DriverCard(
                        driver: driver,
                        companyId: widget.companyId,
                        companyName: widget.companyName,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToCreateTrip(driver);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateTrip(CompanyLinkEntity driver) {
    context.push('/company/create-trip', extra: {
      'companyId': widget.companyId,
      'driverId': driver.driverId,
      'driverName': driver.cargo.isNotEmpty ? driver.cargo : 'Conductor',
    });
  }
}

// ── Tarjeta de Conductor en el diálogo ───────────────────────────────────────

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.companyId,
    required this.companyName,
    required this.onTap,
  });

  final CompanyLinkEntity driver;
  final String companyId;
  final String companyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySurface,
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.cargo.isNotEmpty ? driver.cargo : 'Conductor',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver.phone.isNotEmpty ? driver.phone : 'Sin teléfono',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../injection_container.dart' as di;
import '../../../trips/domain/entities/trip_entity.dart';
import '../../../trips/domain/usecases/generate_trip_code_usecase.dart';
import '../../domain/entities/saved_location_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';
import '../bloc/company_state.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({
    super.key,
    required this.companyId,
    required this.driverId,
    required this.driverName,
  });

  final String companyId;
  final String driverId;
  final String driverName;

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Step 0: trip type
  TripType _tripType = TripType.normal;

  final _geocodingService = GeocodingService();

  // Step 1: origin
  final MapController _originMapController = MapController();
  LatLng? _originLocation;
  String _originAddress = '';

  // Step 2: destination
  final MapController _destinationMapController = MapController();
  LatLng? _destinationLocation;
  String _destinationAddress = '';

  // Step 3: schedule
  DateTime? _scheduledDepartureTime;
  DateTime? _estimatedArrivalTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _originMapController.dispose();
    _destinationMapController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final current = LatLng(position.latitude, position.longitude);
      _originMapController.move(current, 15);
      _destinationMapController.move(current, 15);
    } catch (_) {}
  }

  Future<void> _pickDeparture() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledDepartureTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickArrival() async {
    final base = _scheduledDepartureTime ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: base,
      lastDate: base.add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    setState(() {
      _estimatedArrivalTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  bool get _canSubmit =>
      _originLocation != null &&
      _destinationLocation != null &&
      _scheduledDepartureTime != null &&
      _estimatedArrivalTime != null &&
      _estimatedArrivalTime!.isAfter(_scheduledDepartureTime!);

  bool _isFallbackAddress(String address) =>
      address.startsWith('Punto en el mapa (');

  Future<void> _submit() async {
    if (!_canSubmit) return;

    String originAddr = _originAddress;
    String destinationAddr = _destinationAddress;
    String? tripCode;

    // Reintentar geocoding silenciosamente si la dirección es un fallback
    if (_isFallbackAddress(originAddr) && _originLocation != null) {
      final resolved = await _geocodingService.getAddressFromCoords(
        _originLocation!.latitude,
        _originLocation!.longitude,
      );
      if (resolved != null) originAddr = resolved;
    }

    if (_isFallbackAddress(destinationAddr) && _destinationLocation != null) {
      final resolved = await _geocodingService.getAddressFromCoords(
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );
      if (resolved != null) destinationAddr = resolved;
    }

    // Generar tripCode (ID amigable para el usuario)
    final tripCodeResult = await di.sl<GenerateTripCodeUseCase>()(
      GenerateTripCodeParams(
        driverId: widget.driverId,
        driverName: widget.driverName,
      ),
    );

    tripCodeResult.fold(
      (failure) {
        // Si falla la generación del tripCode, continuar sin él
        debugPrint('Error generando tripCode: $failure');
      },
      (code) => tripCode = code,
    );

    if (!mounted) return;
    context.read<CompanyBloc>().add(
          CompanyTripCreateRequested(
            companyId: widget.companyId,
            driverId: widget.driverId,
            tripType: _tripType,
            originLat: _originLocation!.latitude,
            originLng: _originLocation!.longitude,
            originAddress: originAddr,
            destinationLat: _destinationLocation!.latitude,
            destinationLng: _destinationLocation!.longitude,
            destinationAddress: destinationAddr,
            scheduledDepartureTime: _scheduledDepartureTime!,
            estimatedArrivalTime: _estimatedArrivalTime!,
            tripCode: tripCode,
          ),
        );
  }

  String _formatDt(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listener: (context, state) {
        if (state is CompanyActionSuccess) {
          // Solo responder al éxito de creación de viaje (no de ubicaciones
          // guardadas que se manejan dentro del sheet)
          if (state.message == 'Viaje creado correctamente.') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
            context.pop();
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
      child: Scaffold(
        appBar: AppBar(
          title: Text('Crear Viaje — ${widget.driverName}'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Tipo'),
              Tab(text: 'Origen'),
              Tab(text: 'Destino'),
              Tab(text: 'Horario'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _TripTypeStep(
              selected: _tripType,
              onChanged: (t) => setState(() => _tripType = t),
              onNext: () => _tabController.animateTo(1),
            ),
            _MapPickerStep(
              mapController: _originMapController,
              selectedLocation: _originLocation,
              selectedAddress: _originAddress,
              label: 'origen',
              markerColor: AppColors.success,
              companyId: widget.companyId,
              onLocationSelected: (location, address) {
                setState(() {
                  _originLocation = location;
                  _originAddress = address;
                });
              },
              onNext: () => _tabController.animateTo(2),
            ),
            _MapPickerStep(
              mapController: _destinationMapController,
              selectedLocation: _destinationLocation,
              selectedAddress: _destinationAddress,
              label: 'destino',
              markerColor: AppColors.error,
              companyId: widget.companyId,
              onLocationSelected: (location, address) {
                setState(() {
                  _destinationLocation = location;
                  _destinationAddress = address;
                });
              },
              onNext: () => _tabController.animateTo(3),
            ),
            _ScheduleStep(
              departureTime: _scheduledDepartureTime,
              arrivalTime: _estimatedArrivalTime,
              onPickDeparture: _pickDeparture,
              onPickArrival: _pickArrival,
              canSubmit: _canSubmit,
              onSubmit: _submit,
              formatDt: _formatDt,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 0: Trip type ────────────────────────────────────────────────────────

class _TripTypeStep extends StatelessWidget {
  const _TripTypeStep({
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  final TripType selected;
  final ValueChanged<TripType> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tipo de viaje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _TypeCard(
            type: TripType.normal,
            selected: selected,
            icon: Icons.directions_car,
            title: 'Viaje normal',
            subtitle: 'Traslado estándar de un punto a otro.',
            onTap: () => onChanged(TripType.normal),
          ),
          const SizedBox(height: 12),
          _TypeCard(
            type: TripType.relocation,
            selected: selected,
            icon: Icons.swap_horiz,
            title: 'Traslado / Reubicación',
            subtitle: 'Reposicionamiento del vehículo o conductor.',
            onTap: () => onChanged(TripType.relocation),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Siguiente: Origen',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final TripType type;
  final TripType selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Step 1 & 2: Map picker con búsqueda ──────────────────────────────────────

class _MapPickerStep extends StatefulWidget {
  const _MapPickerStep({
    required this.mapController,
    required this.selectedLocation,
    required this.selectedAddress,
    required this.label,
    required this.markerColor,
    required this.companyId,
    required this.onLocationSelected,
    required this.onNext,
  });

  final MapController mapController;
  final LatLng? selectedLocation;
  final String selectedAddress;
  final String label;
  final Color markerColor;
  final String companyId;
  final void Function(LatLng, String) onLocationSelected;
  final VoidCallback onNext;

  @override
  State<_MapPickerStep> createState() => _MapPickerStepState();
}

class _MapPickerStepState extends State<_MapPickerStep> {
  final _geocodingService = GeocodingService();
  final _searchController = TextEditingController();
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activa el GPS para usar la búsqueda cercana'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        if (widget.selectedLocation == null) {
          widget.mapController.move(_currentLocation!, 15);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo obtener la ubicación: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final searchLocation = _currentLocation ?? const LatLng(4.7110, -74.0721);
    final results =
        await _geocodingService.search(query, nearLocation: searchLocation);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _showResults = results.isNotEmpty;
      });
    }
  }

  void _selectResult(GeocodingResult result) {
    widget.mapController.move(result.latLng, 16);
    widget.onLocationSelected(result.latLng, result.displayName);
    setState(() {
      _searchController.text = result.displayName;
      _showResults = false;
      _searchResults = [];
    });
  }

  void _selectSavedLocation(SavedLocationEntity location) {
    final latLng = LatLng(location.lat, location.lng);
    widget.mapController.move(latLng, 16);
    widget.onLocationSelected(latLng, location.address);
    setState(() {
      _searchController.text = location.address;
      _showResults = false;
      _searchResults = [];
    });
  }

  Future<void> _centerOnMyLocation() async {
    if (_currentLocation != null) {
      widget.mapController.move(_currentLocation!, 15);
      final address = await _geocodingService.getAddressFromCoords(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      if (address != null && mounted) {
        widget.onLocationSelected(_currentLocation!, address);
        setState(() => _searchController.text = address);
      }
      return;
    }

    setState(() => _isSearching = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activa el GPS y los permisos de ubicación'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        final location = LatLng(position.latitude, position.longitude);
        widget.mapController.move(location, 15);

        final address = await _geocodingService.getAddressFromCoords(
          location.latitude,
          location.longitude,
        );

        if (address != null) {
          widget.onLocationSelected(location, address);
          setState(() {
            _currentLocation = location;
            _searchController.text = address;
          });
        } else {
          setState(() => _currentLocation = location);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No se pudo obtener tu ubicación. Verifica el GPS.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _openSavedLocationsSheet() {
    context
        .read<CompanyBloc>()
        .add(LoadSavedLocations(companyId: widget.companyId));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<CompanyBloc>(),
        child: _SavedLocationsSheet(
          companyId: widget.companyId,
          onLocationSelected: _selectSavedLocation,
          sheetContext: sheetContext,
        ),
      ),
    );
  }

  Future<void> _showSaveLocationDialog() async {
    if (widget.selectedLocation == null) return;

    final nameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Guardar ubicación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.selectedAddress.length > 60
                  ? '${widget.selectedAddress.substring(0, 60)}...'
                  : widget.selectedAddress,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: 'Nombre de la ubicación',
                hintText: 'Ej: Bodega central',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final name = nameController.text.trim();
      if (name.isEmpty) return;

      context.read<CompanyBloc>().add(
            SaveLocationRequested(
              companyId: widget.companyId,
              name: name,
              address: widget.selectedAddress,
              lat: widget.selectedLocation!.latitude,
              lng: widget.selectedLocation!.longitude,
            ),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación guardada correctamente.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: widget.mapController,
                options: MapOptions(
                  initialCenter: const LatLng(4.7110, -74.0721),
                  initialZoom: 13,
                  onTap: (_, point) {
                    setState(() => _showResults = false);
                    _getAddressFromCoords(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bombastik.safedrive',
                  ),
                  if (widget.selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.selectedLocation!,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on,
                              color: widget.markerColor, size: 40),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildSearchBar(),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Toca en el mapa o busca una dirección para seleccionar el ${widget.label}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              if (widget.selectedAddress.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          color: widget.markerColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.selectedAddress.length > 50
                              ? '${widget.selectedAddress.substring(0, 50)}...'
                              : widget.selectedAddress,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      // Botón guardar ubicación
                      IconButton(
                        icon: const Icon(Icons.bookmark_add_outlined,
                            color: AppColors.primary, size: 22),
                        onPressed: _showSaveLocationDialog,
                        tooltip: 'Guardar esta ubicación',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:
                    widget.selectedLocation == null ? null : widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  widget.label == 'destino'
                      ? 'Siguiente: Horario'
                      : 'Siguiente: Destino',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar dirección...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchAddress('');
                                },
                              )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: _searchAddress,
                  onTap: () => setState(() => _showResults = true),
                ),
              ),
              // Botón "Mis ubicaciones"
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.bookmark_border,
                      color: AppColors.primary, size: 22),
                  onPressed: _openSavedLocationsSheet,
                  tooltip: 'Mis ubicaciones guardadas',
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 4),
              // Botón "Mi ubicación"
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color:
                      _isSearching ? AppColors.textSecondary : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location,
                          color: Colors.white, size: 22),
                  onPressed: _isSearching ? null : _centerOnMyLocation,
                  tooltip: 'Usar mi ubicación actual',
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          if (_showResults && _searchResults.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                    title: Text(
                      result.displayName.length > 60
                          ? '${result.displayName.substring(0, 60)}...'
                          : result.displayName,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: result.country != null
                        ? Text(
                            result.country!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          )
                        : null,
                    onTap: () => _selectResult(result),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _getAddressFromCoords(LatLng point) async {
    final address = await _geocodingService.getAddressFromCoords(
        point.latitude, point.longitude);
    if (address != null && mounted) {
      widget.onLocationSelected(point, address);
      setState(() => _searchController.text = address);
    } else {
      widget.onLocationSelected(
        point,
        'Punto en el mapa (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})',
      );
    }
  }
}

// ── Bottom Sheet: Ubicaciones guardadas ──────────────────────────────────────

class _SavedLocationsSheet extends StatelessWidget {
  const _SavedLocationsSheet({
    required this.companyId,
    required this.onLocationSelected,
    required this.sheetContext,
  });

  final String companyId;
  final void Function(SavedLocationEntity) onLocationSelected;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyBloc, CompanyState>(
      listenWhen: (previous, current) =>
          current is CompanyActionSuccess &&
          current.message == 'Ubicación guardada correctamente.',
      listener: (context, state) {
        // Recargar la lista después de guardar una ubicación
        context
            .read<CompanyBloc>()
            .add(LoadSavedLocations(companyId: companyId));
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Mis ubicaciones guardadas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: BlocBuilder<CompanyBloc, CompanyState>(
                    builder: (context, state) {
                      if (state is CompanyLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        );
                      }

                      if (state is SavedLocationsLoaded) {
                        if (state.locations.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bookmark_border,
                                    size: 56,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No tienes ubicaciones guardadas aún',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Selecciona una ubicación en el mapa\ny usa el botón de guardar.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.locations.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (context, index) {
                            final location = state.locations[index];
                            return _SavedLocationTile(
                              location: location,
                              companyId: companyId,
                              onTap: () {
                                onLocationSelected(location);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SavedLocationTile extends StatelessWidget {
  const _SavedLocationTile({
    required this.location,
    required this.companyId,
    required this.onTap,
  });

  final SavedLocationEntity location;
  final String companyId;
  final VoidCallback onTap;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Eliminar ubicación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Deseas eliminar "${location.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CompanyBloc>().add(
            DeleteSavedLocationRequested(
              companyId: companyId,
              locationId: location.id,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bookmark,
            color: AppColors.primary, size: 20),
      ),
      title: Text(
        location.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        location.address,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
        onPressed: () => _confirmDelete(context),
        tooltip: 'Eliminar ubicación',
      ),
      onTap: onTap,
    );
  }
}

// ── Step 3: Schedule ─────────────────────────────────────────────────────────

class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({
    required this.departureTime,
    required this.arrivalTime,
    required this.onPickDeparture,
    required this.onPickArrival,
    required this.canSubmit,
    required this.onSubmit,
    required this.formatDt,
  });

  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final VoidCallback onPickDeparture;
  final VoidCallback onPickArrival;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final String Function(DateTime) formatDt;

  bool get _arrivalBeforeDeparture =>
      departureTime != null &&
      arrivalTime != null &&
      !arrivalTime!.isAfter(departureTime!);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Horario del viaje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _DateTile(
            icon: Icons.departure_board,
            label: 'Hora de salida programada',
            value: departureTime != null ? formatDt(departureTime!) : null,
            placeholder: 'Seleccionar fecha y hora',
            onTap: onPickDeparture,
          ),
          const SizedBox(height: 16),
          _DateTile(
            icon: Icons.flag_outlined,
            label: 'Hora estimada de llegada',
            value: arrivalTime != null ? formatDt(arrivalTime!) : null,
            placeholder: 'Seleccionar fecha y hora',
            onTap: onPickArrival,
          ),
          if (_arrivalBeforeDeparture) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La hora de llegada debe ser posterior a la de salida.',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          BlocBuilder<CompanyBloc, CompanyState>(
            builder: (context, state) {
              final isLoading = state is CompanyLoading;
              return ElevatedButton(
                onPressed: (!canSubmit || isLoading) ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear Viaje',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

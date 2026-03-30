import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/trip_entity.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';
import 'impediment_dialog.dart';

/// Panel persistente de viaje mostrado en la parte superior del home del conductor.
class TripPanelWidget extends StatelessWidget {
  const TripPanelWidget({
    super.key,
    required this.driverId,
    required this.onOpenMap,
  });

  final String driverId;
  final VoidCallback onOpenMap;

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _requestPermissionsAndStart(
    BuildContext context, {
    required VoidCallback onStart,
  }) async {
    bool hasLocation = await Permission.locationWhenInUse.isGranted;
    if (!hasLocation) {
      final result = await Permission.locationWhenInUse.request();
      hasLocation = result.isGranted;
    }
    if (!hasLocation) {
      if (!context.mounted) return;
      final cont = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _NoLocationDialog(),
      );
      if (cont != true) return;
    }

    bool hasCamera = await Permission.camera.isGranted;
    if (!hasCamera) {
      final result = await Permission.camera.request();
      hasCamera = result.isGranted;
    }
    if (!hasCamera) {
      if (!context.mounted) return;
      final cont = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _NoCameraDialog(),
      );
      if (cont != true) return;
    }

    if (!context.mounted) return;
    onStart();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        if (state is TripLoading || state is TripInitial) {
          return const _PanelShell(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textOnPrimary,
              ),
            ),
          );
        }

        if (state is TripInProgress) {
          return _ActiveTripPanel(
            formatted: _formatElapsed(state.elapsed),
            tripType: state.trip.tripType,
            onEnd: () async {
              final tripBloc = context.read<TripBloc>();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: tripBloc,
                  child: _ConfirmEndDialog(
                    message:
                        'El viaje quedará en espera de aprobación por la empresa.',
                  ),
                ),
              );
              if (confirmed == true) {
                tripBloc.add(EndTrip(tripId: state.trip.id));
              }
            },
            onOpenMap: onOpenMap,
            onImpediment: () {
              final tripBloc = context.read<TripBloc>();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => BlocProvider.value(
                  value: tripBloc,
                  child: ImpedimentDialog(tripId: state.trip.id),
                ),
              );
            },
          );
        }

        if (state is FreeTripInProgress) {
          return _ActiveTripPanel(
            formatted: _formatElapsed(state.elapsed),
            tripType: TripType.free,
            onEnd: () async {
              final tripBloc = context.read<TripBloc>();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: tripBloc,
                  child: _ConfirmEndDialog(
                    message: '¿Deseas finalizar el viaje libre?',
                  ),
                ),
              );
              if (confirmed == true) {
                tripBloc.add(EndFreeTrip(tripId: state.trip.id));
              }
            },
            onOpenMap: onOpenMap,
          );
        }

        if (state is TripPendingApproval) {
          return _PendingApprovalPanel(trip: state.trip);
        }

        if (state is TripWithImpediment) {
          return _ImpedimentPanel(trip: state.trip);
        }

        if (state is TripListLoaded) {
          return _IdlePanel(
            onStartFree: () => _requestPermissionsAndStart(
              context,
              onStart: () {
                final hasCamera =
                    context.read<TripBloc>().state is TripLoading;
                context.read<TripBloc>().add(
                      StartFreeTrip(
                        driverId: driverId,
                        hasCameraPermission: hasCamera,
                      ),
                    );
              },
            ),
          );
        }

        return _IdlePanel(
          error: state is TripError ? state.message : null,
          onStartFree: () => _requestPermissionsAndStart(
            context,
            onStart: () {
              context.read<TripBloc>().add(
                    StartFreeTrip(
                      driverId: driverId,
                      hasCameraPermission: false,
                    ),
                  );
            },
          ),
        );
      },
    );
  }
}

// ── Shells ────────────────────────────────────────────────────────────────────

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: child,
    );
  }
}

// ── Panels ────────────────────────────────────────────────────────────────────

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({required this.onStartFree, this.error});
  final VoidCallback onStartFree;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.directions_car,
                  color: AppColors.textOnPrimary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sin viaje en curso',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onStartFree,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Viaje Libre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Container(
            width: double.infinity,
            color: AppColors.error.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _ActiveTripPanel extends StatelessWidget {
  const _ActiveTripPanel({
    required this.formatted,
    required this.tripType,
    required this.onEnd,
    required this.onOpenMap,
    this.onImpediment,
  });

  final String formatted;
  final TripType tripType;
  final VoidCallback onEnd;
  final VoidCallback onOpenMap;
  final VoidCallback? onImpediment;

  @override
  Widget build(BuildContext context) {
    final isFree = tripType == TripType.free;
    final bgColor =
        isFree ? const Color(0xFF1B5E20) : const Color(0xFF0D47A1);
    final label =
        isFree ? 'Viaje libre en curso' : 'Viaje empresa en curso';

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onOpenMap,
            icon: const Icon(Icons.map_outlined, color: Colors.white70, size: 18),
            label: const Text(
              'Mapa',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          if (onImpediment != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onImpediment,
              icon: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 22),
              tooltip: 'Reportar impedimento',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: onEnd,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('Finalizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalPanel extends StatelessWidget {
  const _PendingApprovalPanel({required this.trip});
  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE65100),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Icon(Icons.hourglass_top, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Esperando aprobación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'La empresa revisará tu viaje pronto',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpedimentPanel extends StatelessWidget {
  const _ImpedimentPanel({required this.trip});
  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    final cat = trip.impedimentCategory;
    final reportedAt = trip.impedimentReportedAt;
    final timeStr = reportedAt != null
        ? DateFormat('HH:mm').format(reportedAt)
        : '';

    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.report_problem, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cat != null ? cat.label : 'Impedimento reportado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeStr.isNotEmpty
                      ? 'Reportado a las $timeStr — Esperando resolución'
                      : 'Esperando resolución de la empresa',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Permission dialogs ────────────────────────────────────────────────────────

class _ConfirmEndDialog extends StatelessWidget {
  const _ConfirmEndDialog({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Finalizar Viaje'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Finalizar'),
        ),
      ],
    );
  }
}

class _NoLocationDialog extends StatelessWidget {
  const _NoLocationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.location_off, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Sin permiso de GPS'),
        ],
      ),
      content: const Text(
        'Sin acceso a la ubicación no podremos registrar tu recorrido en el mapa.\n\n'
        '¿Deseas continuar sin GPS?',
        style: TextStyle(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continuar sin GPS'),
        ),
      ],
    );
  }
}

class _NoCameraDialog extends StatelessWidget {
  const _NoCameraDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.videocam_off_outlined, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Sin permiso de cámara'),
        ],
      ),
      content: const Text(
        'Sin el permiso de cámara frontal, la detección de somnolencia y la '
        'verificación del cinturón no estarán disponibles.\n\n'
        '¿Deseas continuar sin estas funciones?',
        style: TextStyle(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continuar sin cámara'),
        ),
      ],
    );
  }
}

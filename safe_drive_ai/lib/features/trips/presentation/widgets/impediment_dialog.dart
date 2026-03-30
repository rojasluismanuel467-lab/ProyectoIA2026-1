import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/trip_entity.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';

/// Diálogo para que el conductor reporte un impedimento en el viaje activo.
class ImpedimentDialog extends StatefulWidget {
  const ImpedimentDialog({super.key, required this.tripId});

  final String tripId;

  @override
  State<ImpedimentDialog> createState() => _ImpedimentDialogState();
}

class _ImpedimentDialogState extends State<ImpedimentDialog> {
  ImpedimentCategory? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedCategory == null) return;
    context.read<TripBloc>().add(
          ReportImpediment(
            tripId: widget.tripId,
            category: _selectedCategory!,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripWithImpediment || state is TripError) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is TripLoading;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Reportar Impedimento'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el tipo de impedimento:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...ImpedimentCategory.values.map(
                  (cat) => RadioListTile<ImpedimentCategory>(
                    value: cat,
                    groupValue: _selectedCategory,
                    onChanged: isLoading
                        ? null
                        : (val) => setState(() => _selectedCategory = val),
                    title: Text(
                      cat.label,
                      style: const TextStyle(fontSize: 14),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  enabled: !isLoading,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Descripción adicional (opcional)',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!isLoading)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            if (isLoading)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.warning,
                ),
              )
            else
              ElevatedButton(
                onPressed: _selectedCategory == null ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Reportar'),
              ),
          ],
        );
      },
    );
  }
}

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class ReportImpedimentUseCase
    implements UseCase<TripEntity, ReportImpedimentParams> {
  const ReportImpedimentUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, TripEntity>> call(ReportImpedimentParams params) =>
      _repository.reportImpediment(
        tripId: params.tripId,
        category: params.category,
        description: params.description,
      );
}

class ReportImpedimentParams extends Equatable {
  const ReportImpedimentParams({
    required this.tripId,
    required this.category,
    this.description,
  });

  final String tripId;
  final ImpedimentCategory category;
  final String? description;

  @override
  List<Object?> get props => [tripId, category, description];
}

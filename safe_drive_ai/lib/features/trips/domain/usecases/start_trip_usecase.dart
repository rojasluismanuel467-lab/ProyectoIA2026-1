import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class StartTripUseCase implements UseCase<TripEntity, StartTripParams> {
  const StartTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, TripEntity>> call(StartTripParams params) =>
      _repository.startTrip(
        tripId: params.tripId,
        hasCameraPermission: params.hasCameraPermission,
      );
}

class StartTripParams extends Equatable {
  const StartTripParams({
    required this.tripId,
    required this.hasCameraPermission,
  });

  final String tripId;
  final bool hasCameraPermission;

  @override
  List<Object?> get props => [tripId, hasCameraPermission];
}

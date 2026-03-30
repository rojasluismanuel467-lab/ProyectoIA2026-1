import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class StartFreeTripUseCase implements UseCase<TripEntity, StartFreeTripParams> {
  const StartFreeTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, TripEntity>> call(StartFreeTripParams params) =>
      _repository.startFreeTrip(
        driverId: params.driverId,
        hasCameraPermission: params.hasCameraPermission,
      );
}

class StartFreeTripParams extends Equatable {
  const StartFreeTripParams({
    required this.driverId,
    required this.hasCameraPermission,
  });

  final String driverId;
  final bool hasCameraPermission;

  @override
  List<Object?> get props => [driverId, hasCameraPermission];
}

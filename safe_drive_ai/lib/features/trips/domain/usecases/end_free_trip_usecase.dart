import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class EndFreeTripUseCase implements UseCase<TripEntity, String> {
  const EndFreeTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, TripEntity>> call(String tripId) =>
      _repository.endFreeTrip(tripId);
}

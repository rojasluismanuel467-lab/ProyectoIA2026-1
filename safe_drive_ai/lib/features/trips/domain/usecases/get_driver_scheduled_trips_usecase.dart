import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class GetDriverScheduledTripsUseCase
    implements UseCase<List<TripEntity>, String> {
  const GetDriverScheduledTripsUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, List<TripEntity>>> call(String driverId) {
    return _repository.getDriverScheduledTrips(driverId);
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class GetDriverTripHistoryUseCase
    implements UseCase<List<TripEntity>, String> {
  const GetDriverTripHistoryUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, List<TripEntity>>> call(String driverId) {
    return _repository.getDriverTripHistory(driverId);
  }
}

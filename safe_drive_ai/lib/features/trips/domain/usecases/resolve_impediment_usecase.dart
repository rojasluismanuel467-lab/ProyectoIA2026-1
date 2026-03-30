import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/trip_repository.dart';

/// Empresa resuelve un impedimento activo — el viaje vuelve a `scheduled`.
class ResolveImpedimentUseCase implements UseCase<void, String> {
  const ResolveImpedimentUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, void>> call(String tripId) =>
      _repository.resolveImpediment(tripId);
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

/// Empresa cancela un viaje — pasa a `cancelled`.
class CancelTripUseCase implements UseCase<void, String> {
  const CancelTripUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(String tripId) =>
      _repository.cancelTrip(tripId);
}

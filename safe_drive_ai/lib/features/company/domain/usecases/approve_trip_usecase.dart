import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

/// Empresa aprueba un viaje en estado `pendingApproval` — pasa a `approved`.
class ApproveTripUseCase implements UseCase<void, String> {
  const ApproveTripUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(String tripId) =>
      _repository.approveTrip(tripId);
}

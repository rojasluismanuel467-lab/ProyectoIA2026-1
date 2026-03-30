import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

/// Empresa resuelve un impedimento activo — el viaje vuelve a `scheduled`.
class ResolveImpedimentCompanyUseCase implements UseCase<void, String> {
  const ResolveImpedimentCompanyUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(String tripId) =>
      _repository.resolveImpediment(tripId);
}

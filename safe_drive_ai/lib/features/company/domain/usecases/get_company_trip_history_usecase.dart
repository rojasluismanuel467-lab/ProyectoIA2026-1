import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../repositories/company_repository.dart';

/// Obtiene el historial de viajes finalizados (approved, cancelled, completed)
/// de todos los conductores de la empresa, ordenados por fecha descendente.
class GetCompanyTripHistoryUseCase {
  const GetCompanyTripHistoryUseCase(this._repository);

  final CompanyRepository _repository;

  Future<Either<Failure, List<TripEntity>>> call(String companyId) {
    return _repository.getCompanyTripHistory(companyId);
  }
}

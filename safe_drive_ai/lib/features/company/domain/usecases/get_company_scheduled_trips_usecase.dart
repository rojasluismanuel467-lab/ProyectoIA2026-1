import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../repositories/company_repository.dart';

/// Obtiene todos los viajes programados (scheduled) de una empresa.
class GetCompanyScheduledTripsUseCase
    implements UseCase<List<TripEntity>, String> {
  const GetCompanyScheduledTripsUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, List<TripEntity>>> call(String companyId) =>
      _repository.getCompanyScheduledTrips(companyId);
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/saved_location_entity.dart';
import '../repositories/company_repository.dart';

class GetSavedLocationsUseCase {
  const GetSavedLocationsUseCase(this._repository);

  final CompanyRepository _repository;

  Future<Either<Failure, List<SavedLocationEntity>>> call(
    String companyId,
  ) =>
      _repository.getSavedLocations(companyId);
}

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/company_repository.dart';

class DeleteSavedLocationUseCase {
  const DeleteSavedLocationUseCase(this._repository);

  final CompanyRepository _repository;

  Future<Either<Failure, void>> call({
    required String companyId,
    required String locationId,
  }) =>
      _repository.deleteSavedLocation(companyId, locationId);
}

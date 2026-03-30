import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/saved_location_entity.dart';
import '../repositories/company_repository.dart';

class SaveLocationParams {
  const SaveLocationParams({
    required this.companyId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String companyId;
  final String name;
  final String address;
  final double lat;
  final double lng;
}

class SaveLocationUseCase {
  const SaveLocationUseCase(this._repository);

  final CompanyRepository _repository;

  Future<Either<Failure, void>> call(SaveLocationParams params) =>
      _repository.saveLocation(
        params.companyId,
        SavedLocationEntity(
          id: '',
          name: params.name,
          address: params.address,
          lat: params.lat,
          lng: params.lng,
          createdAt: DateTime.now(),
        ),
      );
}

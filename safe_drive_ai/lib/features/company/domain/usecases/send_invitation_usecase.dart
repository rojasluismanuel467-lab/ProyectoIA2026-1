import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

/// Envía una invitación a un conductor buscado por su email.
class SendInvitationUseCase extends UseCase<void, SendInvitationParams> {
  const SendInvitationUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(SendInvitationParams params) {
    return _repository.sendInvitation(
      companyId: params.companyId,
      companyName: params.companyName,
      driverEmail: params.driverEmail,
    );
  }
}

class SendInvitationParams extends Equatable {
  const SendInvitationParams({
    required this.companyId,
    required this.companyName,
    required this.driverEmail,
  });

  final String companyId;
  final String companyName;
  final String driverEmail;

  @override
  List<Object?> get props => [
        companyId,
        companyName,
        driverEmail,
      ];
}

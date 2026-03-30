import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../repositories/company_repository.dart';

class CreateCompanyTripUseCase
    implements UseCase<TripEntity, CreateCompanyTripParams> {
  const CreateCompanyTripUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, TripEntity>> call(CreateCompanyTripParams params) =>
      _repository.createCompanyTrip(
        companyId: params.companyId,
        driverId: params.driverId,
        tripType: params.tripType,
        originLat: params.originLat,
        originLng: params.originLng,
        originAddress: params.originAddress,
        destinationLat: params.destinationLat,
        destinationLng: params.destinationLng,
        destinationAddress: params.destinationAddress,
        scheduledDepartureTime: params.scheduledDepartureTime,
        estimatedArrivalTime: params.estimatedArrivalTime,
        tripCode: params.tripCode,
      );
}

class CreateCompanyTripParams extends Equatable {
  const CreateCompanyTripParams({
    required this.companyId,
    required this.driverId,
    required this.tripType,
    required this.originLat,
    required this.originLng,
    required this.originAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationAddress,
    required this.scheduledDepartureTime,
    required this.estimatedArrivalTime,
    this.tripCode,
  });

  final String companyId;
  final String driverId;
  final TripType tripType;
  final double originLat;
  final double originLng;
  final String originAddress;
  final double destinationLat;
  final double destinationLng;
  final String destinationAddress;
  final DateTime scheduledDepartureTime;
  final DateTime estimatedArrivalTime;
  final String? tripCode;

  @override
  List<Object?> get props => [
        companyId,
        driverId,
        tripType,
        originLat,
        originLng,
        originAddress,
        destinationLat,
        destinationLng,
        destinationAddress,
        scheduledDepartureTime,
        estimatedArrivalTime,
        tripCode,
      ];
}

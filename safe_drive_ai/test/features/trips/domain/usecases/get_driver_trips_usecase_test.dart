import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_drive_ai/core/errors/failures.dart';
import 'package:safe_drive_ai/features/trips/domain/entities/trip_entity.dart';
import 'package:safe_drive_ai/features/trips/domain/repositories/trip_repository.dart';
import 'package:safe_drive_ai/features/trips/domain/usecases/get_driver_trips_usecase.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late GetDriverTripsUseCase usecase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    usecase = GetDriverTripsUseCase(mockRepository);
  });

  const tDriverId = 'test-driver-id';
  final tTrips = [
    TripEntity(
      id: 'trip1',
      driverId: tDriverId,
      tripType: TripType.normal,
      status: TripStatus.completed,
      hasCameraPermission: true,
    ),
    TripEntity(
      id: 'trip2',
      driverId: tDriverId,
      tripType: TripType.free,
      status: TripStatus.inProgress,
      hasCameraPermission: false,
    ),
  ];

  test(
    'should get list of trips for the driver from the repository',
    () async {
      when(() => mockRepository.getDriverTrips(any()))
          .thenAnswer((_) async => Right(tTrips));
      final result =
          await usecase(const GetDriverTripsParams(driverId: tDriverId));
      expect(result, Right(tTrips));
      verify(() => mockRepository.getDriverTrips(tDriverId));
      verifyNoMoreInteractions(mockRepository);
    },
  );

  test('should return a failure when repository fails', () async {
    const tFailure = ServerFailure(message: 'Server error');
    when(() => mockRepository.getDriverTrips(any()))
        .thenAnswer((_) async => const Left(tFailure));
    final result =
        await usecase(const GetDriverTripsParams(driverId: tDriverId));
    expect(result, const Left(tFailure));
    verify(() => mockRepository.getDriverTrips(tDriverId));
    verifyNoMoreInteractions(mockRepository);
  });
}

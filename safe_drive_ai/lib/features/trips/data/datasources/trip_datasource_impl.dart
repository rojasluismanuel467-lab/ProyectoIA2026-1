import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/trip_entity.dart';
import '../models/route_point_model.dart';
import '../models/trip_model.dart';
import 'trip_datasource.dart';

class TripDatasourceImpl implements TripDatasource {
  const TripDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  // ── Conductor: viajes programados ──────────────────────────────────────────

  @override
  Future<List<TripModel>> getDriverScheduledTrips(String driverId) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'scheduled')
        .orderBy('scheduledDepartureTime')
        .get();

    return snapshot.docs
        .map((doc) => TripModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<TripModel?> getActiveTrip(String driverId) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'inProgress')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return TripModel.fromMap(doc.id, doc.data());
  }

  @override
  Future<TripModel> startTrip({
    required String tripId,
    required bool hasCameraPermission,
  }) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException('No se encontró el viaje $tripId.');
    }

    final data = doc.data()!;
    final status = data['status'] as String?;
    if (status != 'scheduled') {
      throw ServerException(
          'Solo se puede iniciar un viaje en estado scheduled. Estado actual: $status');
    }

    // Verificar que no haya un viaje con impedimento activo
    final impedimentQuery = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: data['driverId'] as String)
        .where('status', isEqualTo: 'withImpediment')
        .limit(1)
        .get();

    if (impedimentQuery.docs.isNotEmpty) {
      throw ServerException(
          'Hay un viaje con impedimento activo. Resuélvelo antes de iniciar otro.');
    }

    // Verificar que no haya otro viaje en progreso
    final inProgressQuery = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: data['driverId'] as String)
        .where('status', isEqualTo: 'inProgress')
        .limit(1)
        .get();

    if (inProgressQuery.docs.isNotEmpty) {
      throw const TripAlreadyActiveException();
    }

    final now = DateTime.now();
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'inProgress',
      'actualStartTime': Timestamp.fromDate(now),
      'hasCameraPermission': hasCameraPermission,
    });

    return TripModel.fromMap(tripId, {
      ...data,
      'status': 'inProgress',
      'actualStartTime': Timestamp.fromDate(now),
      'hasCameraPermission': hasCameraPermission,
    });
  }

  @override
  Future<TripModel> endCompanyTrip(String tripId) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException('No se encontró el viaje $tripId.');
    }

    final now = DateTime.now();
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'pendingApproval',
      'actualEndTime': Timestamp.fromDate(now),
    });

    final data = doc.data()!;
    return TripModel.fromMap(tripId, {
      ...data,
      'status': 'pendingApproval',
      'actualEndTime': Timestamp.fromDate(now),
    });
  }

  // ── Conductor: viaje libre ──────────────────────────────────────────────────

  @override
  Future<TripModel> startFreeTrip({
    required String driverId,
    required bool hasCameraPermission,
  }) async {
    // Verificar que no haya un viaje en progreso
    final inProgressQuery = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'inProgress')
        .limit(1)
        .get();

    if (inProgressQuery.docs.isNotEmpty) {
      throw const TripAlreadyActiveException();
    }

    final now = DateTime.now();
    final docRef = await _firestore.collection('trips').add({
      'driverId': driverId,
      'tripType': 'free',
      'status': 'inProgress',
      'hasCameraPermission': hasCameraPermission,
      'actualStartTime': Timestamp.fromDate(now),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return TripModel(
      id: docRef.id,
      driverId: driverId,
      tripType: TripType.free,
      status: TripStatus.inProgress,
      hasCameraPermission: hasCameraPermission,
      actualStartTime: now,
    );
  }

  @override
  Future<TripModel> endFreeTrip(String tripId) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException('No se encontró el viaje $tripId.');
    }

    final now = DateTime.now();
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'completed',
      'actualEndTime': Timestamp.fromDate(now),
    });

    final data = doc.data()!;
    return TripModel.fromMap(tripId, {
      ...data,
      'status': 'completed',
      'actualEndTime': Timestamp.fromDate(now),
    });
  }

  // ── Conductor: impedimento ──────────────────────────────────────────────────

  @override
  Future<TripModel> reportImpediment({
    required String tripId,
    required ImpedimentCategory category,
    String? description,
  }) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException('No se encontró el viaje $tripId.');
    }

    final now = DateTime.now();
    final updateData = <String, dynamic>{
      'status': 'withImpediment',
      'impedimentCategory': _impedimentCategoryToString(category),
      'impedimentReportedAt': Timestamp.fromDate(now),
    };
    if (description != null && description.isNotEmpty) {
      updateData['impedimentDescription'] = description;
    }

    await _firestore.collection('trips').doc(tripId).update(updateData);

    final data = doc.data()!;
    return TripModel.fromMap(tripId, {
      ...data,
      ...updateData,
    });
  }

  // ── Empresa ─────────────────────────────────────────────────────────────────

  @override
  Future<void> approveTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'approved',
    });
  }

  @override
  Future<void> cancelTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'cancelled',
    });
  }

  @override
  Future<void> resolveImpediment(String tripId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'scheduled',
      'impedimentCategory': FieldValue.delete(),
      'impedimentDescription': FieldValue.delete(),
      'impedimentReportedAt': FieldValue.delete(),
    });
  }

  @override
  Future<TripModel> createCompanyTrip({
    required String companyId,
    required String driverId,
    required TripType tripType,
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    required DateTime scheduledDepartureTime,
    required DateTime estimatedArrivalTime,
    String? companyName,
  }) async {
    final tripData = <String, dynamic>{
      'driverId': driverId,
      'companyId': companyId,
      if (companyName != null) 'companyName': companyName,
      'tripType': _tripTypeToString(tripType),
      'status': 'scheduled',
      'hasCameraPermission': false,
      'originLat': originLat,
      'originLng': originLng,
      'originAddress': originAddress,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'destinationAddress': destinationAddress,
      'scheduledDepartureTime': Timestamp.fromDate(scheduledDepartureTime),
      'estimatedArrivalTime': Timestamp.fromDate(estimatedArrivalTime),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('trips').add(tripData);

    return TripModel(
      id: docRef.id,
      driverId: driverId,
      companyId: companyId,
      companyName: companyName,
      tripType: tripType,
      status: TripStatus.scheduled,
      hasCameraPermission: false,
      originLat: originLat,
      originLng: originLng,
      originAddress: originAddress,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      destinationAddress: destinationAddress,
      scheduledDepartureTime: scheduledDepartureTime,
      estimatedArrivalTime: estimatedArrivalTime,
    );
  }

  @override
  Future<List<TripModel>> getCompanyPendingApprovalTrips(
      String companyId) async {
    final driversQuery = await _firestore
        .collection('company_drivers')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .get();

    if (driversQuery.docs.isEmpty) return [];

    final driverIds =
        driversQuery.docs.map((d) => d['driverId'] as String).toList();

    final List<TripModel> result = [];

    for (var i = 0; i < driverIds.length; i += 10) {
      final chunk = driverIds.sublist(
          i, (i + 10) > driverIds.length ? driverIds.length : i + 10);

      final tripsQuery = await _firestore
          .collection('trips')
          .where('driverId', whereIn: chunk)
          .where('status', isEqualTo: 'pendingApproval')
          .get();

      for (final doc in tripsQuery.docs) {
        result.add(TripModel.fromMap(doc.id, doc.data()));
      }
    }

    result.sort((a, b) {
      final aTime = a.actualEndTime;
      final bTime = b.actualEndTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return result;
  }

  @override
  Future<List<TripModel>> getCompanyImpedimentTrips(String companyId) async {
    final driversQuery = await _firestore
        .collection('company_drivers')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .get();

    if (driversQuery.docs.isEmpty) return [];

    final driverIds =
        driversQuery.docs.map((d) => d['driverId'] as String).toList();

    final List<TripModel> result = [];

    for (var i = 0; i < driverIds.length; i += 10) {
      final chunk = driverIds.sublist(
          i, (i + 10) > driverIds.length ? driverIds.length : i + 10);

      final tripsQuery = await _firestore
          .collection('trips')
          .where('driverId', whereIn: chunk)
          .where('status', isEqualTo: 'withImpediment')
          .get();

      for (final doc in tripsQuery.docs) {
        result.add(TripModel.fromMap(doc.id, doc.data()));
      }
    }

    return result;
  }

  // ── Ruta GPS ─────────────────────────────────────────────────────────────────

  @override
  Future<void> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('route_points')
        .add({
      'lat': lat,
      'lng': lng,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<RoutePointModel>> getTripRoute(String tripId) async {
    final snapshot = await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('route_points')
        .orderBy('recordedAt')
        .get();
    return snapshot.docs
        .map((doc) => RoutePointModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<List<TripModel>> getDriverTrips(String driverId) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .orderBy('scheduledDepartureTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TripModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<List<TripModel>> getDriverTripHistory(String driverId) async {
    // Optimización: Hacer una sola consulta en lugar de 3 separadas
    // Usamos 'whereIn' para obtener todos los estados de una vez
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['approved', 'cancelled', 'completed'])
        .orderBy('actualEndTime', descending: true)
        .limit(50)
        .get();

    final trips = snapshot.docs
        .map((doc) => TripModel.fromMap(doc.id, doc.data()))
        .toList();

    // Ordenamiento adicional para asegurar consistencia
    trips.sort((a, b) {
      final aTime = a.actualEndTime;
      final bTime = b.actualEndTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return trips.take(50).toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _tripTypeToString(TripType type) {
    switch (type) {
      case TripType.relocation:
        return 'relocation';
      case TripType.free:
        return 'free';
      case TripType.normal:
        return 'normal';
    }
  }

  static String _impedimentCategoryToString(ImpedimentCategory cat) {
    switch (cat) {
      case ImpedimentCategory.flatTire:
        return 'flatTire';
      case ImpedimentCategory.weather:
        return 'weather';
      case ImpedimentCategory.accident:
        return 'accident';
      case ImpedimentCategory.mechanical:
        return 'mechanical';
      case ImpedimentCategory.other:
        return 'other';
    }
  }
}

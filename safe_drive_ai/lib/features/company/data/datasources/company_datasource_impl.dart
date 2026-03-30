import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/company_link_model.dart';
import '../../../auth/data/models/company_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../models/invitation_model.dart';
import '../models/saved_location_model.dart';
import 'company_datasource.dart';

class CompanyDatasourceImpl implements CompanyDatasource {
  const CompanyDatasourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  // ── Conductores ─────────────────────────────────────────────────────────────

  @override
  Future<List<CompanyLinkModel>> getCompanyDrivers(String companyId) async {
    final snapshot = await _firestore
        .collection('company_drivers')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .get();

    final companyDoc =
        await _firestore.collection('companies').doc(companyId).get();
    final companyName =
        companyDoc.exists ? (companyDoc.data()!['name'] as String? ?? '') : '';

    return snapshot.docs
        .map(
          (doc) => CompanyLinkModel.fromMap(doc.id, doc.data(), companyName),
        )
        .toList();
  }

  @override
  Future<UserModel> getDriverProfile(String driverId) async {
    final doc = await _firestore.collection('users').doc(driverId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException(
        'No se encontró el perfil del conductor $driverId.',
      );
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<void> unlinkDriver(String linkId) async {
    await _firestore.collection('company_drivers').doc(linkId).update({
      'status': 'inactive',
      'unlinkedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Registro de conductor nuevo ──────────────────────────────────────────────

  @override
  Future<void> registerDriverByCompany({
    required String companyId,
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String cargo,
  }) async {
    final cedulaQuery = await _firestore
        .collection('users')
        .where('cedula', isEqualTo: cedula)
        .limit(1)
        .get();

    if (cedulaQuery.docs.isNotEmpty) {
      throw const CedulaAlreadyRegisteredException();
    }

    final tempPassword = 'SD${DateTime.now().millisecondsSinceEpoch}!Ab';

    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );
      final driverUid = credential.user!.uid;

      await _firestore.collection('users').doc(driverUid).set({
        'name': name,
        'cedula': cedula,
        'email': email,
        'role': 'driver',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('company_drivers').add({
        'companyId': companyId,
        'driverId': driverUid,
        'cargo': cargo,
        'phone': phone,
        'status': 'active',
        'linkedAt': FieldValue.serverTimestamp(),
        'unlinkedAt': null,
      });

      await secondaryAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const EmailAlreadyRegisteredException();
      }
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }

  // ── Invitaciones ────────────────────────────────────────────────────────────

  @override
  Future<void> sendInvitation({
    required String companyId,
    required String companyName,
    required String driverEmail,
  }) async {
    final usersQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: driverEmail)
        .limit(1)
        .get();

    if (usersQuery.docs.isEmpty) {
      throw const DriverNotFoundException();
    }

    final driverDoc = usersQuery.docs.first;
    final driverId = driverDoc.id;
    final driverData = driverDoc.data();
    final driverName = driverData['name'] as String? ?? '';

    // Verificar si ya existe una invitación pendiente
    final existingInvitation = await _firestore
        .collection('invitations')
        .where('companyId', isEqualTo: companyId)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingInvitation.docs.isNotEmpty) {
      throw const InvitationAlreadyExistsException();
    }

    // Verificar si ya está vinculado activamente
    final existingLink = await _firestore
        .collection('company_drivers')
        .where('companyId', isEqualTo: companyId)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existingLink.docs.isNotEmpty) {
      throw const DriverAlreadyLinkedException();
    }

    await _firestore.collection('invitations').add({
      'companyId': companyId,
      'companyName': companyName,
      'driverId': driverId,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'cargo': '',
      'phone': '',
      'status': 'pending',
      'sentAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
  }

  @override
  Future<List<InvitationModel>> getCompanyInvitations(
    String companyId,
  ) async {
    final snapshot = await _firestore
        .collection('invitations')
        .where('companyId', isEqualTo: companyId)
        .orderBy('sentAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'cancelled',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Perfil empresa ───────────────────────────────────────────────────────────

  @override
  Future<CompanyEntity> updateCompanyProfile({
    required String companyId,
    required String name,
    required String representativeName,
  }) async {
    await _firestore.collection('companies').doc(companyId).update({
      'name': name,
      'representativeName': representativeName,
    });

    final doc = await _firestore.collection('companies').doc(companyId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException(
        'No se encontró el perfil de la empresa $companyId.',
      );
    }
    return CompanyModel.fromMap(doc.id, doc.data()!);
  }

  // ── Viajes ───────────────────────────────────────────────────────────────────

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
    String? tripCode,
    String? companyName,
  }) async {
    // Si no se pasa companyName, lo obtenemos de Firestore
    String resolvedCompanyName = companyName ?? '';
    if (resolvedCompanyName.isEmpty) {
      final companyDoc =
          await _firestore.collection('companies').doc(companyId).get();
      if (companyDoc.exists) {
        resolvedCompanyName =
            companyDoc.data()!['name'] as String? ?? '';
      }
    }

    final tripData = <String, dynamic>{
      'driverId': driverId,
      'companyId': companyId,
      'companyName': resolvedCompanyName,
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
      if (tripCode != null) 'tripCode': tripCode,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('trips').add(tripData);

    return TripModel(
      id: docRef.id,
      driverId: driverId,
      companyId: companyId,
      companyName: resolvedCompanyName,
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
      tripCode: tripCode,
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

    result.sort((a, b) {
      final aTime = a.impedimentReportedAt;
      final bTime = b.impedimentReportedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return result;
  }

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
  Future<List<TripModel>> getCompanyTripHistory(String companyId) async {
    const historyStatuses = ['approved', 'cancelled', 'completed'];
    final List<TripModel> result = [];

    for (final status in historyStatuses) {
      final snapshot = await _firestore
          .collection('trips')
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: status)
          .limit(100)
          .get();

      for (final doc in snapshot.docs) {
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
  Future<List<TripModel>> getCompanyScheduledTrips(String companyId) async {
    // Obtener todos los conductores activos de la empresa
    final driversQuery = await _firestore
        .collection('company_drivers')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .get();

    if (driversQuery.docs.isEmpty) return [];

    final driverIds =
        driversQuery.docs.map((d) => d['driverId'] as String).toList();

    final List<TripModel> result = [];

    // Obtener viajes scheduled en chunks de 10
    for (var i = 0; i < driverIds.length; i += 10) {
      final chunk = driverIds.sublist(
          i, (i + 10) > driverIds.length ? driverIds.length : i + 10);

      final tripsQuery = await _firestore
          .collection('trips')
          .where('driverId', whereIn: chunk)
          .where('status', isEqualTo: 'scheduled')
          .orderBy('scheduledDepartureTime', descending: true)
          .get();

      for (final doc in tripsQuery.docs) {
        result.add(TripModel.fromMap(doc.id, doc.data()));
      }
    }

    return result;
  }

  // ── Ubicaciones guardadas ────────────────────────────────────────────────────

  @override
  Future<List<SavedLocationModel>> getSavedLocations(String companyId) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('saved_locations')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SavedLocationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> saveLocation(
    String companyId,
    SavedLocationModel location,
  ) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('saved_locations')
        .add(location.toMap());
  }

  @override
  Future<void> deleteSavedLocation(
    String companyId,
    String locationId,
  ) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('saved_locations')
        .doc(locationId)
        .delete();
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
}

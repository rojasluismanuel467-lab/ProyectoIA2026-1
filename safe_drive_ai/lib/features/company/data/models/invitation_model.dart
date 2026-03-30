import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/invitation_entity.dart';

class InvitationModel extends InvitationEntity {
  const InvitationModel({
    required super.id,
    required super.companyId,
    required super.companyName,
    required super.driverId,
    required super.driverName,
    required super.driverEmail,
    required super.status,
    required super.sentAt,
    super.resolvedAt,
  });

  factory InvitationModel.fromMap(String id, Map<String, dynamic> map) {
    return InvitationModel(
      id: id,
      companyId: map['companyId'] as String,
      companyName: map['companyName'] as String,
      driverId: map['driverId'] as String,
      driverName: (map['driverName'] as String?) ?? '',
      driverEmail: (map['driverEmail'] as String?) ?? '',
      status: _parseStatus(map['status'] as String),
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'driverId': driverId,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'status': _statusToString(status),
      'sentAt': FieldValue.serverTimestamp(),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  static InvitationStatus _parseStatus(String raw) {
    switch (raw) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      case 'cancelled':
        return InvitationStatus.cancelled;
      default:
        return InvitationStatus.pending;
    }
  }

  static String _statusToString(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return 'accepted';
      case InvitationStatus.rejected:
        return 'rejected';
      case InvitationStatus.cancelled:
        return 'cancelled';
      case InvitationStatus.pending:
        return 'pending';
    }
  }
}

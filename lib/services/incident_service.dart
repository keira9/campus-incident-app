import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/incident.dart';
import '../utils/constants.dart';

class IncidentService {
  final _col = FirebaseFirestore.instance.collection('incidents');

  String newId() => _col.doc().id;

  Stream<List<Incident>> watchIncidents() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Incident.fromDoc).toList());

  Future<void> create({
    required String id,
    required String title,
    required String description,
    required String category,
    required String location,
    required String reporterId,
    required String reporterName,
    String? photoUrl,
  }) {
    return _col.doc(id).set({
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'photoUrl': photoUrl,
      'status': IncidentStatus.submitted,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': [
        {
          'status': IncidentStatus.submitted,
          'by': reporterName,
          'at': Timestamp.now(),
        },
      ],
    });
  }

  Future<void> updateStatus({
    required String incidentId,
    required String status,
    required String by,
  }) {
    return _col.doc(incidentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {'status': status, 'by': by, 'at': Timestamp.now()},
      ]),
    });
  }
}

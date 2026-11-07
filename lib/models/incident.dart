import 'package:cloud_firestore/cloud_firestore.dart';

class StatusEntry {
  final String status;
  final String by;
  final DateTime at;

  const StatusEntry({required this.status, required this.by, required this.at});

  factory StatusEntry.fromMap(Map<String, dynamic> m) => StatusEntry(
        status: m['status'] ?? '',
        by: m['by'] ?? '',
        at: m['at'] is Timestamp ? (m['at'] as Timestamp).toDate() : DateTime.now(),
      );
}

class Incident {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String status;
  final String reporterId;
  final String reporterName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusEntry> history;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
    this.photoUrl,
  });

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime ts(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
    return Incident(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? 'Other',
      location: d['location'] ?? '',
      status: d['status'] ?? 'Submitted',
      reporterId: d['reporterId'] ?? '',
      reporterName: d['reporterName'] ?? '',
      photoUrl: d['photoUrl'],
      createdAt: ts(d['createdAt']),
      updatedAt: ts(d['updatedAt']),
      history: ((d['statusHistory'] as List?) ?? [])
          .map((e) => StatusEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
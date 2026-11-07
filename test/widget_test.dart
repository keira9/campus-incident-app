import 'package:flutter_test/flutter_test.dart';

import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/utils/incident_filters.dart';

void main() {
  final reports = [
    _incident(
      id: '1',
      title: 'Broken classroom door',
      description: 'The door does not close properly.',
      category: 'Broken facilities',
      location: 'Block A',
      status: 'Submitted',
    ),
    _incident(
      id: '2',
      title: 'Water leak',
      description: 'Water is leaking near the sink.',
      category: 'Water shortage',
      location: 'Block B',
      status: 'In Progress',
    ),
    _incident(
      id: '3',
      title: 'Broken desk',
      description: 'A desk is damaged in the classroom.',
      category: 'Broken facilities',
      location: 'Block B',
      status: 'Resolved',
    ),
  ];

  test('search matches report text without case sensitivity', () {
    final result = filterIncidents(
      reports,
      query: 'BLOCK B',
      category: null,
      status: null,
    );

    expect(result.map((report) => report.id), ['2', '3']);
  });

  test('category and status filters are combined', () {
    final result = filterIncidents(
      reports,
      query: '',
      category: 'Broken facilities',
      status: 'Resolved',
    );

    expect(result.map((report) => report.id), ['3']);
  });

  test('trimmed search can match report descriptions', () {
    final result = filterIncidents(
      reports,
      query: '  does not close  ',
      category: null,
      status: null,
    );

    expect(result.map((report) => report.id), ['1']);
  });
}

Incident _incident({
  required String id,
  required String title,
  required String description,
  required String category,
  required String location,
  required String status,
}) {
  final now = DateTime(2026, 11, 7);
  return Incident(
    id: id,
    title: title,
    description: description,
    category: category,
    location: location,
    status: status,
    reporterId: 'reporter',
    reporterName: 'Campus user',
    createdAt: now,
    updatedAt: now,
    history: const [],
  );
}

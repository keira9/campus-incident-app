import '../models/incident.dart';

List<Incident> filterIncidents(
  List<Incident> incidents, {
  required String query,
  required String? category,
  required String? status,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return incidents.where((incident) {
    final matchesQuery =
        normalizedQuery.isEmpty ||
        incident.title.toLowerCase().contains(normalizedQuery) ||
        incident.description.toLowerCase().contains(normalizedQuery) ||
        incident.location.toLowerCase().contains(normalizedQuery);
    final matchesCategory = category == null || incident.category == category;
    final matchesStatus = status == null || incident.status == status;
    return matchesQuery && matchesCategory && matchesStatus;
  }).toList();
}

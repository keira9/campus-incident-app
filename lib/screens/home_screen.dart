import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import 'incident_details_screen.dart';
import 'student/report_incident_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  IncidentProvider? _incidentProvider;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _incidentProvider = context.read<IncidentProvider>()..start();
      _started = true;
    }
  }

  @override
  void dispose() {
    _incidentProvider?.stop();
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters(IncidentProvider incidents) {
    _searchController.clear();
    incidents.clearFilters();
  }

  void _clearSearch(IncidentProvider incidents) {
    _searchController.clear();
    incidents.setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final incidents = context.watch<IncidentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Welcome ${auth.profile?.name ?? ''}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: incidents.setQuery,
              decoration: InputDecoration(
                hintText: 'Search reports',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: incidents.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () => _clearSearch(incidents),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _FilterDropdown<String?>(
                    label: 'Category',
                    value: incidents.category,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...IncidentCategories.all.map(
                        (category) => DropdownMenuItem<String?>(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: incidents.setCategory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterDropdown<String?>(
                    label: 'Status',
                    value: incidents.status,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All statuses'),
                      ),
                      ...IncidentStatus.all.map(
                        (status) => DropdownMenuItem<String?>(
                          value: status,
                          child: Text(status, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: incidents.setStatus,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildIncidentList(incidents)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ReportIncidentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Report incident'),
      ),
    );
  }

  Widget _buildIncidentList(IncidentProvider incidents) {
    if (incidents.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (incidents.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(incidents.error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (incidents.all.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No reports yet. Submit an incident to get started.'),
        ),
      );
    }
    if (incidents.filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No reports match your search or filters.'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _clearFilters(incidents),
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      );
    }

    final reports = incidents.filtered;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final incident = reports[index];
        return _IncidentCard(incident: incident);
      },
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final date = incident.createdAt.toLocal();
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IncidentDetailsScreen(incident: incident),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(incident.status),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${incident.category} · ${incident.location}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$dateLabel · ${incident.reporterName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View details  ›',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

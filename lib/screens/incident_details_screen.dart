import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';

class IncidentDetailsScreen extends StatefulWidget {
  const IncidentDetailsScreen({super.key, required this.incident});

  final Incident incident;

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  String? _selectedStatus;

  Future<void> _updateStatus(Incident incident) async {
    final user = context.read<AuthProvider>().profile;
    if (user == null || _selectedStatus == null) return;

    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.updateStatus(
      user: user,
      incident: incident,
      status: _selectedStatus!,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Report status updated.'
              : provider.statusError ?? 'Could not update report status.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<IncidentProvider>();
    final currentReports = provider.all
        .where((report) => report.id == widget.incident.id)
        .toList();
    final incident = currentReports.isEmpty
        ? widget.incident
        : currentReports.first;
    final isUpdating = provider.updatingIncidentId == incident.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            incident.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(incident.status)),
              Chip(label: Text(incident.category)),
            ],
          ),
          const SizedBox(height: 8),
          _DetailLine(icon: Icons.place_outlined, label: incident.location),
          _DetailLine(
            icon: Icons.person_outline,
            label: 'Reported by ${incident.reporterName}',
          ),
          _DetailLine(
            icon: Icons.calendar_today_outlined,
            label: _formatDateTime(context, incident.createdAt),
          ),
          const SizedBox(height: 16),
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(incident.description),
          if (incident.photoUrl != null) ...[
            const SizedBox(height: 20),
            Text('Photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                incident.photoUrl!,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('Photo could not be loaded.')),
                ),
              ),
            ),
          ],
          if (auth.isStaff) ...[
            const SizedBox(height: 24),
            Text(
              'Staff actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _StatusDropdown(
              value: IncidentStatus.all.contains(_selectedStatus)
                  ? _selectedStatus!
                  : incident.status,
              onChanged: isUpdating
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
            ),
            if (provider.statusError != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.statusError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    isUpdating ||
                        (_selectedStatus ?? incident.status) == incident.status
                    ? null
                    : () => _updateStatus(incident),
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isUpdating ? 'Updating…' : 'Update status'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Status history', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (incident.history.isEmpty)
            const Text('No status history is available.')
          else
            ...incident.history.reversed.map(
              (entry) => _HistoryItem(entry: entry),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final local = dateTime.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date at $time';
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Report status',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: IncidentStatus.all
              .map(
                (status) => DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.entry});

  final StatusEntry entry;

  @override
  Widget build(BuildContext context) {
    final local = entry.at.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.circle, size: 12),
      title: Text(entry.status),
      subtitle: Text('Updated by ${entry.by} · $date at $time'),
    );
  }
}

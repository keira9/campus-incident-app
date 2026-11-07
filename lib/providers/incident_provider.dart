import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import '../services/storage_service.dart';
import '../utils/incident_filters.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentService _service;
  final StorageService _storage;
  StreamSubscription<List<Incident>>? _sub;

  List<Incident> _all = [];
  bool loading = true;
  bool submitting = false;
  String? updatingIncidentId;
  String? error;
  String? notice;
  String? statusError;

  String _query = '';
  String? _category;
  String? _status;

  IncidentProvider(this._service, this._storage);

  String get query => _query;
  String? get category => _category;
  String? get status => _status;
  List<Incident> get all => _all;

  List<Incident> get filtered => filterIncidents(
    _all,
    query: _query,
    category: _category,
    status: _status,
  );

  /// Called once a verified user reaches the home screen.
  void start() {
    if (_sub != null) return;
    loading = true;
    _sub = _service.watchIncidents().listen(
      (list) {
        _all = list;
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (_) {
        loading = false;
        error = 'Could not load reports.';
        notifyListeners();
      },
    );
  }

  /// Called when the home screen is removed (logout). Does not notify.
  void stop() {
    _sub?.cancel();
    _sub = null;
    _all = [];
    loading = true;
  }

  void setQuery(String v) {
    _query = v;
    notifyListeners();
  }

  void setCategory(String? v) {
    _category = v;
    notifyListeners();
  }

  void setStatus(String? v) {
    _status = v;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _category = null;
    _status = null;
    notifyListeners();
  }

  Future<bool> submit({
    required AppUser user,
    required String title,
    required String description,
    required String category,
    required String location,
    XFile? photo,
  }) async {
    submitting = true;
    error = null;
    notice = null;
    notifyListeners();
    try {
      final id = _service.newId();
      String? url;
      if (photo != null) {
        try {
          url = await _storage.uploadIncidentPhoto(id, photo);
        } catch (_) {
          notice = 'Report saved, but the photo could not be uploaded.';
        }
      }
      await _service.create(
        id: id,
        title: title,
        description: description,
        category: category,
        location: location,
        reporterId: user.uid,
        reporterName: user.name,
        photoUrl: url,
      );
      return true;
    } catch (_) {
      error = 'Could not submit the report. Check your connection.';
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus({
    required AppUser user,
    required Incident incident,
    required String status,
  }) async {
    if (!user.isStaff) {
      statusError = 'Only authorized staff can update report statuses.';
      notifyListeners();
      return false;
    }

    updatingIncidentId = incident.id;
    statusError = null;
    notifyListeners();
    try {
      await _service.updateStatus(
        incidentId: incident.id,
        status: status,
        by: user.name,
      );
      return true;
    } catch (_) {
      statusError =
          'Could not update the report status. Check your connection.';
      return false;
    } finally {
      updatingIncidentId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

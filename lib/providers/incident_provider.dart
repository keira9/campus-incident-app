import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import '../services/storage_service.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentService _service;
  final StorageService _storage;
  StreamSubscription<List<Incident>>? _sub;

  List<Incident> _all = [];
  bool loading = true;
  bool submitting = false;
  String? error;
  String? notice;

  String _query = '';
  String? _category;
  String? _status;

  IncidentProvider(this._service, this._storage);

  String get query => _query;
  String? get category => _category;
  String? get status => _status;
  List<Incident> get all => _all;

  List<Incident> get filtered => _all.where((i) {
        final q = _query.toLowerCase();
        final matchesQuery = q.isEmpty ||
            i.title.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q) ||
            i.location.toLowerCase().contains(q);
        final matchesCat = _category == null || i.category == _category;
        final matchesStatus = _status == null || i.status == _status;
        return matchesQuery && matchesCat && matchesStatus;
      }).toList();

  /// Called once a verified user reaches the home screen.
  void start() {
    if (_sub != null) return;
    loading = true;
    _sub = _service.watchIncidents().listen((list) {
      _all = list;
      loading = false;
      error = null;
      notifyListeners();
    }, onError: (_) {
      loading = false;
      error = 'Could not load reports.';
      notifyListeners();
    });
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
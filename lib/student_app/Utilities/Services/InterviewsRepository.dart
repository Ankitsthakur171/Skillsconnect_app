import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/InterviewScreen_Model.dart';
import '../InterviewScreen_Api.dart';


class InterviewsRepository {
  static final InterviewsRepository _instance = InterviewsRepository._internal();
  factory InterviewsRepository() => _instance;
  InterviewsRepository._internal();

  static const _prefsKey = 'cached_interviews_json';
  static const _prefsTsKey = 'cached_interviews_ts';
  static const _prefsEtagKey = 'cached_interviews_etag'; // optional if server supports ETag

  List<InterviewModel>? _inMemoryCache;
  ValueNotifier<List<InterviewModel>?> notifier = ValueNotifier(null);
  String? _etag; // optional ETag value

  /// Get interviews.
  /// If [forceRefresh] is true, network will be requested.
  /// Otherwise: return in-memory -> disk -> network (in that order).
  Future<List<InterviewModel>> getInterviews({bool forceRefresh = false}) async {
    // 1) In-memory: fastest
    if (!forceRefresh && _inMemoryCache != null) {
      return _inMemoryCache!;
    }

    // 2) Disk (SharedPreferences)
    if (!forceRefresh && _inMemoryCache == null) {
      final fromDisk = await _loadFromPrefs();
      if (fromDisk != null) {
        _inMemoryCache = fromDisk;
        notifier.value = _inMemoryCache;
        return _inMemoryCache!;
      }
    }

    // 3) Network
    final fetched = await _fetchFromNetworkAndCache();
    return fetched;
  }

  Future<List<InterviewModel>?> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      _etag = prefs.getString(_prefsEtagKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final decoded = json.decode(jsonStr);
      if (decoded is List) {
        final models = decoded
            .map<InterviewModel>((m) => InterviewModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        return models;
      }
      return null;
    } catch (e) {
      // If cache corrupted, return null to trigger network fetch
      return null;
    }
  }

  Future<void> _saveToPrefs(String rawJson, {String? etag}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, rawJson);
      await prefs.setInt(_prefsTsKey, DateTime.now().millisecondsSinceEpoch);
      if (etag != null && etag.isNotEmpty) {
        await prefs.setString(_prefsEtagKey, etag);
        _etag = etag;
      }
    } catch (_) {}
  }

  Future<List<InterviewModel>> _fetchFromNetworkAndCache() async {
    try {
      final result = await InterviewApi.fetchInterviewsRawAndParsed(ifNoneMatch: _etag);

      // If server responded 304 Not Modified and we have in-memory cache, return it.
      if (result.notModified && _inMemoryCache != null) {
        return _inMemoryCache!;
      }

      // If server returned a body, save it
      if (result.rawBody != null) {
        await _saveToPrefs(result.rawBody!, etag: result.etag);
      }

      final parsed = result.parsed ?? <InterviewModel>[];
      _inMemoryCache = parsed;
      notifier.value = _inMemoryCache;
      return parsed;
    } catch (e) {
      // fallback to in-memory or disk, else empty list
      if (_inMemoryCache != null) return _inMemoryCache!;
      final disk = await _loadFromPrefs();
      if (disk != null) {
        _inMemoryCache = disk;
        notifier.value = _inMemoryCache;
        return _inMemoryCache!;
      }
      return <InterviewModel>[];
    }
  }

  /// Force clear cache (call after add/edit/delete)
  void invalidateCache() {
    _inMemoryCache = null;
    notifier.value = null;
  }

  /// Background check — fetches network and updates cache if changed.
  Future<void> backgroundCheckAndUpdate() async {
    await _fetchFromNetworkAndCache();
  }
}

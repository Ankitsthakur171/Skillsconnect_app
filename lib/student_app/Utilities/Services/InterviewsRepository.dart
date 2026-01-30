import 'package:flutter/foundation.dart';
import '../../Model/InterviewScreen_Model.dart';
import '../InterviewScreen_Api.dart';


class InterviewsRepository {
  static final InterviewsRepository _instance = InterviewsRepository._internal();
  factory InterviewsRepository() => _instance;
  InterviewsRepository._internal();

  List<InterviewModel>? _inMemoryCache;
  ValueNotifier<List<InterviewModel>?> notifier = ValueNotifier(null);

  /// Get interviews.
  /// If [forceRefresh] is true, network will be requested.
  /// Otherwise: return in-memory cache if available.
  Future<List<InterviewModel>> getInterviews({bool forceRefresh = false}) async {
    // In-memory cache
    if (!forceRefresh && _inMemoryCache != null) {
      return _inMemoryCache!;
    }

    // Fetch from network
    final fetched = await _fetchFromNetwork();
    return fetched;
  }

  Future<List<InterviewModel>> _fetchFromNetwork() async {
    try {
      final result = await InterviewApi.fetchInterviewsRawAndParsed();

      final parsed = result.parsed ?? <InterviewModel>[];
      _inMemoryCache = parsed;
      notifier.value = _inMemoryCache;
      return parsed;
    } catch (e) {
      // fallback to in-memory cache if available, else empty list
      if (_inMemoryCache != null) return _inMemoryCache!;
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
    await _fetchFromNetwork();
  }
}

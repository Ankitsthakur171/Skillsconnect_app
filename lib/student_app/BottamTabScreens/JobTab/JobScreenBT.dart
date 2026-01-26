import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../Pages/bottombar.dart';
import '../../Pages/noInternetPage_jobs.dart';
import '../../Utilities/JobList_Api.dart';
import '../../Utilities/JobFilterApi.dart';
import '../../Model/Job_Model.dart';
import '../../blocpage/bloc_logic.dart';
import '../../blocpage/bloc_state.dart';
import 'AppBarJobScreen.dart';
import 'JobCardBT.dart';
import 'JobdetailPage/JobdetailpageBT.dart';

class Jobscreenbt extends StatefulWidget {
  const Jobscreenbt({super.key});

  @override
  State<Jobscreenbt> createState() => _JobScreenbtState();
}

class _JobScreenbtState extends State<Jobscreenbt> {
  List<JobModelsd> jobs = [];

  List<JobModelsd> _searchResults = [];

  List<JobModelsd> _filteredJobs = [];
  Map<String, dynamic>? _activeFilters;

  bool get _hasActiveFilters {
    final f = _activeFilters;
    if (f == null) return false;
    return (f['jobTitle']?.toString().trim().isNotEmpty == true ||
        f['job_title']?.toString().trim().isNotEmpty == true ||
        f['jobTypeId'] != null ||
        f['courseId'] != null ||
        f['locationId'] != null);
  }

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  final int pageLimit = 10;
  bool isLoadingMoreSearch = false;
  bool hasMoreSearch = true;
  int currentSearchPage = 1;
  String? errorMessage;
  int _selectedIndex = 0;
  bool _snackBarShown = false;
  bool _showShimmer = true;

  final ScrollController _scrollController = ScrollController();

  String _query = '';

  bool get _isSearching => _query.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    debugPrint("JobScreen → initState");
    _fetchJobs(initial: true);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        if (_isSearching) {
          if (!isLoadingMoreSearch && !isLoading && hasMoreSearch) {
            _fetchJobsSearch();
          }
        } else if (_hasActiveFilters) {
          if (!isLoadingMore && !isLoading && hasMore) {
            _fetchJobsFiltered();
          }
        } else {
          if (!isLoadingMore && !isLoading && hasMore) {
            _fetchJobs();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void applyFilters(Map<String, dynamic> filters) {
    debugPrint("JobScreen → applyFilters called with: $filters");
    setState(() {
      _activeFilters = filters;
      _filteredJobs.clear();
      currentPage = 1;
      hasMore = true;
    });
    _fetchJobsFiltered(initial: true);
  }

  void clearFilters() {
    debugPrint("JobScreen → clearFilters called");
    setState(() {
      _activeFilters = null;
      _filteredJobs.clear();
      currentPage = 1;
      hasMore = true;
    });
    _fetchJobs(initial: true);
  }

  Future<void> _fetchJobs({bool initial = false}) async {
    if (initial) {
      currentPage = 1;
      hasMore = true;
    } else if (!hasMore) {
      debugPrint("JobScreen → _fetchJobs: no more pages to load");
      return;
    }

    if (initial) {
      debugPrint("JobScreen → _fetchJobs INITIAL page=$currentPage");
      setState(() {
        isLoading = true;
        errorMessage = null;
        _showShimmer = true;
      });
    } else {
      debugPrint("JobScreen → _fetchJobs LOAD MORE page=$currentPage");
      setState(() => isLoadingMore = true);
    }

    try {
      final fetchedRaw =
          await JobApi.fetchJobs(page: currentPage, limit: pageLimit);

      if (!mounted) return;

      final mapped = <JobModelsd>[];
      for (final rawItem in fetchedRaw) {
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(rawItem as Map);

        map['id'] = map['id'] ?? 0;
        map['job_id'] = map['job_id'] ?? (map['jobId'] ?? 0);
        map['job_invitation_token'] = map['job_invitation_token'] ??
            map['jobToken'] ??
            map['job_token'] ??
            '';
        map['title'] = map['title'] ?? map['jobTitle'] ?? 'Untitled';
        map['company_name'] =
            map['company_name'] ?? map['company'] ?? 'Unknown Company';
        map['three_cities_name'] = map['three_cities_name'] ?? map['location'];
        map['cost_to_company'] =
            (map['cost_to_company'] ?? map['salary'])?.toString() ?? 'N/A';
        map['created_on'] = map['created_on'] ?? map['postTime'] ?? 'N/A';
        map['company_logo'] = map['company_logo'] ?? map['logoUrl'];

        if ((map['three_cities_name'] == null ||
            (map['three_cities_name'] as String?)?.isEmpty == true)) {
          final locDetail = map['job_location_detail'];
          if (locDetail is List && locDetail.isNotEmpty) {
            map['three_cities_name'] = locDetail
                .map((loc) => (loc['city_name'] as String?) ?? 'Unknown')
                .join(' • ');
          } else {
            map['three_cities_name'] = 'N/A';
          }
        }
        map['skills'] = map['skills'] ?? (map['tags'] ?? []);
        try {
          mapped.add(JobModelsd.fromJson(map));
        } catch (e) {
          debugPrint(
              "JobScreen → Error mapping normal job item: $e\nData: $map"
          );
        }
      }

      setState(() {
        if (initial) {
          jobs = mapped;
        } else {
          jobs.addAll(mapped);
        }
        hasMore = mapped.length >= pageLimit;
        currentPage += 1;
        isLoading = false;
        isLoadingMore = false;
      });

      debugPrint(
          "JobScreen → _fetchJobs success. Fetched ${mapped.length} items. hasMore=$hasMore, currentPage=$currentPage");
    } catch (e) {
      if (!mounted) return;
      debugPrint("JobScreen → _fetchJobs ERROR: $e");
      setState(() {
        errorMessage = 'Failed to load jobs: $e';
        isLoading = false;
        isLoadingMore = false;
      });
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _showShimmer = false);
      });
    }
  }

  Future<void> _fetchJobsFiltered({bool initial = false}) async {
    if (!_hasActiveFilters) {
      return;
    }

    if (initial) {
      currentPage = 1;
      hasMore = true;
    } else if (!hasMore) {
      return;
    }

    final filters = _activeFilters ?? {};
    final String? jobTitle =
        (filters['jobTitle'] ?? filters['job_title'])?.toString();
    final int? jobTypeId = filters['jobTypeId'] as int?;
    final int? courseId = filters['courseId'] as int?;
    final int? locationId = filters['locationId'] as int?;

    if (initial) {
      debugPrint(
          "JobScreen → _fetchJobsFiltered INITIAL page=$currentPage with filters: $filters");
      setState(() {
        isLoading = true;
        errorMessage = null;
        _showShimmer = true;
      });
    } else {
      debugPrint(
          "JobScreen → _fetchJobsFiltered LOAD MORE page=$currentPage with filters: $filters");
      setState(() => isLoadingMore = true);
    }

    String normalizeSalary(dynamic raw) {
      if (raw == null) return 'Unpaid';
      final s = raw.toString().trim();
      if (s.isEmpty) return 'Unpaid';
      final low = s.toLowerCase();
      if (low == '0' || low == 'na' || low == 'n/a' || low == 'null') {
        return 'Unpaid';
      }
      if (s.contains('₹') ||
          s.toLowerCase().contains('lpa') ||
          s.contains('per annum')) {
        return s;
      }
      final numVal = double.tryParse(s);
      if (numVal != null) {
        final trimmed = numVal.toString().replaceAll(RegExp(r'\.0+$'), '');
        return '₹$trimmed LPA';
      }
      return s;
    }

    DateTime? parseDateFlexible(String? s) {
      if (s == null || s.trim().isEmpty) return null;
      final raw = s.trim();
      DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
      parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
      if (parsed != null) return parsed;
      final digitsMatch = RegExp(r'\d{9,}').firstMatch(raw);
      if (digitsMatch != null) {
        final numVal = int.tryParse(digitsMatch.group(0)!);
        if (numVal != null) {
          if (numVal > 1000000000000) {
            return DateTime.fromMillisecondsSinceEpoch(numVal);
          } else if (numVal > 1000000000) {
            return DateTime.fromMillisecondsSinceEpoch(numVal * 1000);
          }
        }
      }
      return null;
    }

    try {
      final fetchedRaw = await JobFilterApi.fetchJobs(
        page: currentPage,
        limit: pageLimit,
        searchQuery: jobTitle,
        jobTypeId: jobTypeId,
        courseId: courseId,
        locationId: locationId,
      );

      if (!mounted) return;

      final mapped = <JobModelsd>[];
      for (final rawItem in fetchedRaw) {
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(rawItem as Map);

        map['id'] = map['id'] ?? 0;
        map['job_id'] = map['job_id'] ?? (map['jobId'] ?? 0);
        map['job_invitation_token'] = map['job_invitation_token'] ??
            map['jobToken'] ??
            map['job_token'] ??
            '';
        map['title'] = map['title'] ?? map['jobTitle'] ?? 'Untitled';
        map['company_name'] =
            map['company_name'] ?? map['company'] ?? 'Unknown Company';
        map['three_cities_name'] = map['three_cities_name'] ?? map['location'];
        map['company_logo'] = map['company_logo'] ?? map['logoUrl'];

        map['skills'] = map['skills'] ?? (map['tags'] ?? []);

        final rawCtc = map['cost_to_company'] ??
            map['salary'] ??
            map['ctc'] ??
            map['ctc_value'];
        final salaryNormalized = normalizeSalary(rawCtc);
        map['cost_to_company'] = salaryNormalized;
        map['salary'] = salaryNormalized;

        if ((map['three_cities_name'] == null ||
            (map['three_cities_name'] as String?)?.isEmpty == true)) {
          final locDetail = map['job_location_detail'];
          if (locDetail is List && locDetail.isNotEmpty) {
            map['three_cities_name'] = locDetail
                .map((loc) => (loc['city_name'] as String?) ?? 'Unknown')
                .join(' • ');
          } else {
            map['three_cities_name'] = 'N/A';
          }
        }

        final createdOnString =
            (map['created_on'] ?? map['postTime'] ?? map['createdAt'] ?? '')
                .toString();
        final parsedDate = parseDateFlexible(createdOnString);

        String postTime;
        if (parsedDate != null) {
          final diff = DateTime.now().difference(parsedDate);
          if (diff.inMinutes < 60) {
            postTime = '${diff.inMinutes} mins ago';
          } else if (diff.inHours < 24) {
            postTime = '${diff.inHours} hr ago';
          } else {
            postTime = '${diff.inDays} days ago';
          }
        } else {
          final humanPattern = RegExp(
              r'\b(ago|min|mins|minute|minutes|hr|hrs|day|days)\b',
              caseSensitive: false);
          if (humanPattern.hasMatch(createdOnString)) {
            postTime = createdOnString;
          } else {
            postTime = 'N/A';
          }
        }

        map['postTime'] = postTime;
        map['created_on'] = postTime;

        try {
          mapped.add(JobModelsd.fromJson(map));
        } catch (e) {
          debugPrint(
              "JobScreen → Error mapping FILTERED job item: $e\nData: $map");
        }
      }

      setState(() {
        if (initial) {
          _filteredJobs = mapped;
        } else {
          _filteredJobs.addAll(mapped);
        }
        hasMore = mapped.length >= pageLimit;
        currentPage += 1;
        isLoading = false;
        isLoadingMore = false;
      });

      debugPrint(
          "JobScreen → _fetchJobsFiltered success. Fetched ${mapped.length} items. hasMore=$hasMore");
    } catch (e) {
      if (!mounted) return;
      debugPrint("JobScreen → _fetchJobsFiltered ERROR: $e");
      setState(() {
        errorMessage = 'Failed to load filtered jobs: $e';
        isLoading = false;
        isLoadingMore = false;
      });
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _showShimmer = false);
      });
    }
  }

  Future<void> _fetchJobsSearch({bool initial = false}) async {
    if (initial) {
      currentSearchPage = 1;
      hasMoreSearch = true;
    } else if (!hasMoreSearch) {
      debugPrint("JobScreen → _fetchJobsSearch: no more pages to load");
      return;
    }

    if (initial) {
      debugPrint(
          "JobScreen → _fetchJobsSearch INITIAL page=$currentSearchPage query='$_query'");
      setState(() {
        isLoading = true;
        errorMessage = null;
        _showShimmer = true;
      });
    } else {
      debugPrint(
          "JobScreen → _fetchJobsSearch LOAD MORE page=$currentSearchPage query='$_query'");
      setState(() => isLoadingMoreSearch = true);
    }

    try {
      final fetchedRaw = await JobApi.fetchJobs(
        page: currentSearchPage,
        limit: pageLimit,
        query: _query,
      );

      if (!mounted) return;

      final mapped = <JobModelsd>[];
      for (final rawItem in fetchedRaw) {
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(rawItem as Map);
        map['id'] = map['id'] ?? 0;
        map['job_id'] = map['job_id'] ?? (map['jobId'] ?? 0);
        map['job_invitation_token'] = map['job_invitation_token'] ??
            map['jobToken'] ??
            map['job_token'] ??
            '';
        map['title'] = map['title'] ?? map['jobTitle'] ?? 'Untitled';
        map['company_name'] =
            map['company_name'] ?? map['company'] ?? 'Unknown Company';
        map['three_cities_name'] = map['three_cities_name'] ?? map['location'];
        map['cost_to_company'] =
            (map['cost_to_company'] ?? map['salary'])?.toString() ?? 'N/A';
        map['created_on'] = map['created_on'] ?? map['postTime'] ?? 'N/A';
        map['company_logo'] = map['company_logo'] ?? map['logoUrl'];

        if ((map['three_cities_name'] == null ||
            (map['three_cities_name'] as String?)?.isEmpty == true)) {
          final locDetail = map['job_location_detail'];
          if (locDetail is List && locDetail.isNotEmpty) {
            map['three_cities_name'] = locDetail
                .map((loc) => (loc['city_name'] as String?) ?? 'Unknown')
                .join(' • ');
          } else {
            map['three_cities_name'] = 'N/A';
          }
        }
        map['skills'] = map['skills'] ?? (map['tags'] ?? []);
        try {
          mapped.add(JobModelsd.fromJson(map));
        } catch (e) {
          debugPrint(
              "JobScreen → Error mapping SEARCH job item: $e\nData: $map");
        }
      }

      setState(() {
        if (initial) {
          _searchResults = mapped;
        } else {
          _searchResults.addAll(mapped);
        }
        hasMoreSearch = mapped.length >= pageLimit;
        currentSearchPage += 1;
        isLoading = false;
        isLoadingMoreSearch = false;
      });

      debugPrint(
          "JobScreen → _fetchJobsSearch success. Fetched ${mapped.length} items. hasMoreSearch=$hasMoreSearch, currentSearchPage=$currentSearchPage");
    } catch (e) {
      if (!mounted) return;
      debugPrint("JobScreen → _fetchJobsSearch ERROR: $e");
      setState(() {
        errorMessage = 'Failed to load search results: $e';
        isLoading = false;
        isLoadingMoreSearch = false;
      });
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _showShimmer = false);
      });
    }
  }

  Future<void> _onRefresh() async {
    debugPrint("JobScreen → _onRefresh called. "
        "_isSearching=$_isSearching, _hasActiveFilters=$_hasActiveFilters");

    if (_isSearching) {
      await _fetchJobsSearch(initial: true);
    } else if (_hasActiveFilters) {
      await _fetchJobsFiltered(initial: true);
    } else {
      await _fetchJobs(initial: true);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showSnackBarOnce(BuildContext context, String message,
      {int cooldownSeconds = 3}) {
    if (_snackBarShown) return;
    _snackBarShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 12.4.sp)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: cooldownSeconds),
      ),
    );
    Future.delayed(Duration(seconds: cooldownSeconds), () {
      _snackBarShown = false;
    });
  }

  Future<void> _navigateIfOnline({
    required String jobToken,
    required int jobId,
    String? slug,
    bool isAlreadyApplied = false,
  }) async {
    bool online = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }

    if (!online) {
      _showNoInternetSnackBar();
      return;
    }

    try {
      final routeResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailPage2(
            jobToken: jobToken,
            moduleId: jobId,
            slug: slug,
            isAlreadyApplied: isAlreadyApplied,
          ),
        ),
      );
      if (routeResult == true) {}
    } catch (_) {
      _showSnackBarOnce(context, 'Unable to open job detail');
    }
  }

  void _showNoInternetSnackBar() {
    _showSnackBarOnce(context, 'No internet Connection found');
  }

  void _onQueryChanged(String value) {
    _query = value;
    debugPrint("JobScreen → _onQueryChanged: '$_query'");
    if (_query.trim().isEmpty) {
      _searchResults.clear();
      hasMoreSearch = true;
      currentSearchPage = 1;
      setState(() {});
    } else {
      _fetchJobsSearch(initial: true);
    }

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _onClearSearch() {
    debugPrint("JobScreen → _onClearSearch called");
    _query = '';
    _searchResults.clear();
    hasMoreSearch = true;
    currentSearchPage = 1;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) {
        if (state is NavigateTOJobDetailBT) {
          _navigateIfOnline(
            jobToken: state.jobToken,
            jobId: state.jobId,
            isAlreadyApplied: false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: Appbarjobscreen(
          onQueryChanged: _onQueryChanged,
          onClear: _onClearSearch,
          currentFilters: _activeFilters ?? {},
          onFiltersApplied: (filters) {
            debugPrint(
                "JobScreen → onFiltersApplied received from AppBar: $filters");
            applyFilters(filters);
          },
          hasActiveFilters: _hasActiveFilters,
          onClearFilters: clearFilters,
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  Expanded(
                    child: isLoading
                        ? _buildShimmerList()
                        : errorMessage != null
                            ? (_showShimmer
                                ? _buildShimmerList()
                                : NoInternetPage(
                                    onRetry: () async {
                                      setState(() => isLoading = true);
                                      await Future.delayed(
                                          const Duration(seconds: 1));
                                      if (_isSearching) {
                                        await _fetchJobsSearch(initial: true);
                                      } else if (_hasActiveFilters) {
                                        await _fetchJobsFiltered(initial: true);
                                      } else {
                                        await _fetchJobs(initial: true);
                                      }
                                      setState(() => isLoading = false);
                                    },
                                  ))
                            : (_isSearching
                                ? _buildSearchList()
                                : _hasActiveFilters
                                    ? _buildFilteredList()
                                    : _buildNormalList()),
                  )
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildSearchList() {
    if (_showShimmer) return _buildShimmerList();
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No matching jobs'));
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _searchResults.length + (isLoadingMoreSearch ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _searchResults.length) {
          final jm = _searchResults[index];
          return InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => _navigateIfOnline(
              jobToken: jm.jobToken,
              jobId: jm.jobId,
              isAlreadyApplied: false,
            ),
            child: JobCardBT(
              jobId: jm.jobId,
              recordId: jm.recordId,
              jobToken: jm.jobToken,
              jobTitle: jm.jobTitle,
              company: jm.company,
              location: jm.location,
              salary: jm.salary,
              postTime: jm.postTime,
              expiry: jm.expiry,
              tags: jm.tags,
              logoUrl: jm.logoUrl,
              jobType: jm.jobType,
              onTap: ({
                required int jobId,
                required int recordId,
                required String jobToken,
              }) {
                _navigateIfOnline(
                  jobToken: jobToken,
                  jobId: jobId,
                  isAlreadyApplied: false,
                );
              },
            ),
          );
        } else {
          return _loadingMoreSpinner();
        }
      },
    );
  }

  Widget _buildFilteredList() {
    if (_showShimmer) return _buildShimmerList();
    if (_filteredJobs.isEmpty) {
      return const Center(child: Text('No jobs found for selected filters'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredJobs.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _filteredJobs.length) {
          final jm = _filteredJobs[index];
          return InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => _navigateIfOnline(
              jobToken: jm.jobToken,
              jobId: jm.jobId,
              isAlreadyApplied: false,
            ),
            child: JobCardBT(
              jobId: jm.jobId,
              recordId: jm.recordId,
              jobToken: jm.jobToken,
              jobTitle: jm.jobTitle,
              company: jm.company,
              location: jm.location,
              salary: jm.salary,
              postTime: jm.postTime,
              expiry: jm.expiry,
              tags: jm.tags,
              logoUrl: jm.logoUrl,
              jobType: jm.jobType,
              onTap: ({
                required int jobId,
                required int recordId,
                required String jobToken,
              }) {
                _navigateIfOnline(
                  jobToken: jobToken,
                  jobId: jobId,
                  isAlreadyApplied: false,
                );
              },
            ),
          );
        } else {
          return _loadingMoreSpinner();
        }
      },
    );
  }

  Widget _buildNormalList() {

    if (jobs.isEmpty) {
      return _showShimmer
          ? _buildShimmerList()
          : const Center(child: Text('No jobs found'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: jobs.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < jobs.length) {
          final jm = jobs[index];
          return InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => _navigateIfOnline(
              jobToken: jm.jobToken,
              jobId: jm.jobId,
              isAlreadyApplied: false,
            ),
            child: JobCardBT(
              jobId: jm.jobId,
              recordId: jm.recordId,
              jobToken: jm.jobToken,
              jobTitle: jm.jobTitle,
              company: jm.company,
              location: jm.location,
              salary: jm.salary,
              postTime: jm.postTime,
              expiry: jm.expiry,
              tags: jm.tags,
              logoUrl: jm.logoUrl,
              jobType: jm.jobType,
              onTap: ({
                required int jobId,
                required int recordId,
                required String jobToken,
              }) {
                _navigateIfOnline(
                  jobToken: jobToken,
                  jobId: jobId,
                  isAlreadyApplied: false,
                );
              },
            ),
          );
        } else {
          return _loadingMoreSpinner();
        }
      },
    );
  }

  Widget _loadingMoreSpinner() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: SizedBox(
          width: 24.w,
          height: 24.w,
          child: const CircularProgressIndicator(strokeWidth: 2.0),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 16.h,
                                width: 100.w,
                                color: Colors.white),
                            SizedBox(height: 5.h),
                            Container(
                                height: 12.h,
                                width: 160.w,
                                color: Colors.white),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(height: 14.h, width: 44.w, color: Colors.white),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: List.generate(3, (index) {
                      return Container(
                        height: 18.h,
                        width: 52.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 12.h, width: 70.w, color: Colors.white),
                  Container(height: 12.h, width: 54.w, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

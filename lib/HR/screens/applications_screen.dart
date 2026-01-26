import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skillsconnect/HR/model/applicant_model.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../Error_Handler/subscription_expired_screen.dart';
import '../bloc/Applicant_details/applicant_deatils_bloc.dart';
import '../bloc/Applicant_details/applicant_deatils_event.dart';
import '../bloc/Applicants_Data/applicant_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../bloc/Applicants_Data/applicant_event.dart';
import '../bloc/Applicants_Data/applicant_state.dart';
import '../bloc/InterView_Data/interviewtab_bloc.dart';
import '../bloc/InterView_Data/interviewtab_event.dart';
import '../model/job_model.dart';
import 'EnterOtpScreen.dart';
import 'ForceUpdate/Forcelogout.dart';
import 'Interview_tab_innerView.dart';
import 'applicant_details_screen.dart';
import 'applicant_filters.dart';
import 'card_invitation_screen.dart';
import 'interview_bottom_nav.dart';
import 'interview_tab.dart';
import 'notification_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  final JobModel job;
  const ApplicationsScreen({super.key, required this.job});

  @override
  _ApplicationsScreenState createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final ScrollController _scrollController = ScrollController();
  Map<int, String> _selectedStatuses = {};
  bool isFilterTapped = false;
  bool isFilterActive = false;
  final GlobalKey _popupKey = GlobalKey();
  String? nameController;
  final _searchController =
      TextEditingController(); // 👈 initState ke bahar 1 hi instance
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  Map<int, bool> _menuOpenStates = {}; // 👈 har applicant ka menu state rakhega
  // 👇 add these two lines
  DateTime _lastScrollFire = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _fireGap = Duration(milliseconds: 900);
  Map<String, dynamic> savedFilterObjects =
      {}; // stores actual selected filters

  // 👇 State maintain karo (appliedFilters wali jagah)
  int filterCount = 0;

  // 👇 ye function banao
  void updateFilterCount() {
    filterCount = appliedFilters.entries.where((e) {
      final v = e.value;
      if (v == null) return false;
      if (v is String && v.isEmpty) return false;
      return true; // non-empty
    }).length;

    isFilterActive = filterCount > 0;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial applicants
    Future.microtask(() {
      context.read<ApplicantBloc>().add(LoadDataApplicants(widget.job));
    });
    // 👇 search box empty hone par – filters ko respect karo
    _searchController.addListener(() {
      final q = _searchController.text.trim();

      if (q.isEmpty) {
        _debounce?.cancel(); // ❗ Double API call रोकता है
        _reloadAfterSearchClear(); // ❗ Direct full data load
      }
    });
  }

  void _reloadAfterSearchClear() {
    final bloc = context.read<ApplicantBloc>();

    if (appliedFilters.isNotEmpty) {
      final Map<String, String> again = Map<String, String>.from(
        appliedFilters,
      );

      print("[FILTER] re-applying after search clear: $again");

      bloc.add(
        ApplyApplicantFilter(jobId: widget.job.jobId, filters: again, page: 1),
      );
    } else {
      print("🔥 UI TRIGGERED: LoadDataApplicants()");
      bloc.add(LoadDataApplicants(widget.job));
    }
  }

  void _onSearchChanged(String value) {
    // debounce – baar-baar type pe API spam na ho
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // ❗ SUPER IMPORTANT FIX
      // agar search clear hai → debounce ke andar se kuch bhi fire mat karo
      if (_searchController.text.trim().isEmpty) {
        _reloadAfterSearchClear();
        return;
      }

      final query = value.trim();
      final job = widget.job;

      if (query.isEmpty) {
        // 🔄 search clear → filters ke hisaab se reload
        _reloadAfterSearchClear();
      } else {
        // ✅ NEW LOGIC:
        // agar filters lage hue hain → unhi filters ke saath search karo
        if (appliedFilters.isNotEmpty) {
          // appliedFilters ko copy karo, original ko mat chhedo
          final merged = Map<String, String>.from(appliedFilters);
          // "name" key me search text bhejo (ya jo bhi tum backend me use kar rahe ho)
          merged["name"] = query;

          print("🔍 Filter+Search -> $merged");

          context.read<ApplicantBloc>().add(
            ApplyApplicantFilter(jobId: job.jobId, filters: merged, page: 1),
          );
        } else {
          // ❌ koi filter nahi → normal search
          context.read<ApplicantBloc>().add(
            SearchApplicantEvent(job: job, query: query, page: 1),
          );
        }
      }
    });
  }

  // void _onSearchChanged(String value) {
  //   // debounce – baar-baar type pe API spam na ho
  //   _debounce?.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 300), () {
  //     final query = value.trim();
  //     final job = widget.job;
  //
  //     if (query.isEmpty) {
  //       // 🔄 search clear → filters ke hisaab se reload
  //       _reloadAfterSearchClear(); // ✅ YAHAN CHANGE
  //     } else {
  //       // 🔍 live search (current filters ApplicantBloc me jo bhi hain, unke saath)
  //       context.read<ApplicantBloc>().add(
  //         SearchApplicantEvent(job: job, query: query, page: 1),
  //       );
  //     }
  //   });
  // }

  void _onScroll() {
    // bottom ke 100px ke andar aaye to
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final now = DateTime.now();
      if (now.difference(_lastScrollFire) < _fireGap) return; // 👈 throttle
      _lastScrollFire = now;

      final state = context.read<ApplicantBloc>().state;
      if (state is ApplicantLoaded &&
          !state.hasReachedMax &&
          !state.isLoadingMore) {
        context.read<ApplicantBloc>().add(
          LoadMoreApplicants(job: widget.job, query: state.searchQuery ?? ''),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    appliedFilters.clear();

    super.dispose();
  }

  void _onSearchSubmit(String query) {
    final job = widget.job;
    final currentQuery = _searchController.text.trim(); // ✅ latest text

    if (currentQuery.isEmpty) {
      // 🔄 search clear → filters ko respect karo
      print('🔄 Search cleared — reload with filters (if any).');
      _reloadAfterSearchClear();
    } else {
      // ✅ NEW LOGIC:
      if (appliedFilters.isNotEmpty) {
        final merged = Map<String, String>.from(appliedFilters);
        merged["name"] = currentQuery;

        print("🔍 [Submit] Filter+Search -> $merged");

        context.read<ApplicantBloc>().add(
          ApplyApplicantFilter(jobId: job.jobId, filters: merged, page: 1),
        );
      } else {
        print('🔍 Searching for: $currentQuery');
        context.read<ApplicantBloc>().add(
          SearchApplicantEvent(job: job, query: currentQuery, page: 1),
        );
      }
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 8, 4),
      child: Row(
        children: [
          Expanded(
            // child:IgnorePointer(
            // ignoring: controlsDisabled, // taps block honge sirf jab base-empty & no search/filter
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                key: const PageStorageKey(
                  'applicants_search_tf',
                ), //  focus persist
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,

                // chaaho to enter dabane pe bhi same hi logic chale:
                onSubmitted: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _debounce?.cancel(); // ✅ yeh missing hai

                            _searchController.clear();
                            _focusNode.unfocus();
                            // 👉 Filters respect करो
                            // _reloadAfterSearchClear();
                          },
                        )
                      : null,

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: Colors.green.shade50),
                  ),
                ),
              ),
            ),
            // )
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isFilterTapped ? Color(0xFF1A4514) : Color(0x20005E6A),
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                showFilterBottomSheet(
                  context,
                  widget.job.jobId,
                  context.read<ApplicantBloc>(),
                  onFiltersUpdated: (count) {
                    setState(() {
                      filterCount = count;
                    });
                  },
                );
              },
              borderRadius: BorderRadius.circular(100),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isFilterActive
                        ? const Color(0xff003840)
                        : Colors.white,
                    child: Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: isFilterActive
                          ? Colors.white
                          : const Color(0xff003840),
                    ),
                  ),

                  //  Badge counter
                  if (filterCount > 0)
                    Positioned(
                      right: -2,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xff003840),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Center(
                          child: Text(
                            filterCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job; // shortcut reference
    // inside build(), near you already have: final job = widget.job;
    int cvCountFromState = 0;
    final st = context.watch<ApplicantBloc>().state;
    if (st is ApplicantLoaded) {
      cvCountFromState = st.totalCvCount;
    }

    // Fallback to job.applicants if state not ready
    final cvCount = cvCountFromState != 0
        ? cvCountFromState
        : (job.applicants ?? 0);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Color(0xFFEBF6F7),
            elevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Back, Title, Notification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.black,
                            ),
                          ),

                          // Title and Sub-title in center
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _wrapTitle(
                                      job.title ?? 'Embedded Systems Developer',
                                    ),
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                              ),
                            ),
                          ),

                          // Notification Icon
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationsScreen(),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                backgroundColor: Colors.green.shade50,
                                radius: 20,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/notification.png',
                                    height: 40,
                                    width: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 4,
                      ), // Gap between top row and job details
                      // Job Details Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${job.applicants} CVs Received',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff003840),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  '|',
                                  style: TextStyle(color: Color(0xffCCDFE1)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${job.salary} Lakh Salary',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff003840),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatLocation(job.location),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff003840),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            TabBar(
              indicatorColor: Color(0xff00D584),
              labelColor: Color(0xff003840),
              unselectedLabelColor: Colors.grey,
              isScrollable: false,
              labelPadding: const EdgeInsets.fromLTRB(20,0,0,0),


              tabs: [
                // Using fitted box this is small the text then no. is long
                // Tab(
                //   child: FittedBox(
                //     child: Builder(
                //       builder: (context) {
                //         final baseStyle = DefaultTextStyle.of(context).style;
                //
                //         // 👉 yahan se count lo (apne hisaab se change kar sakti ho)
                //         final int rawCount = cvCount; // ya cvCount
                //
                //         String formatCount(int n) {
                //           if (n > 999) {
                //             final double k = n / 1000;
                //             // 1000 -> 1k, 1500 -> 1.5k
                //             final bool isInt = k == k.truncateToDouble();
                //             final String s = k.toStringAsFixed(isInt ? 0 : 1);
                //             return '${s}k';
                //           }
                //           return n.toString();
                //         }
                //
                //         final String countText = formatCount(rawCount);
                //
                //         return RichText(
                //           text: TextSpan(
                //             style: baseStyle.copyWith(fontSize: 14),
                //             children: [
                //               TextSpan(
                //                 text: 'Application',
                //                 style: baseStyle.copyWith(
                //                   fontSize: 14,
                //                   fontWeight: FontWeight.w500,
                //                   // color nahi rakhenge → TabBar khud dega
                //                 ),
                //               ),
                //               const WidgetSpan(child: SizedBox(width: 4)),
                //               TextSpan(
                //                 text: '($countText)', // 👈 yahan formatted count
                //                 style: baseStyle.copyWith(
                //                   fontSize: 14,
                //                   color: const Color(0xff00D584), // hamesha green
                //                 ),
                //               ),
                //             ],
                //           ),
                //         );
                //       },
                //     ),
                //   ),
                // ),



                Tab(
                  child: Builder(
                    builder: (context) {
                      final baseStyle = DefaultTextStyle.of(context).style;

                      // yahan apna actual count use karo (job.applicants ya jo bhi)
                      final int rawCount = cvCount;

                      String formatCount(int n) {
                        if (n > 999) {
                          final double k = n / 1000;
                          final bool isInt = k == k.truncateToDouble();
                          final String s = k.toStringAsFixed(isInt ? 0 : 1); // 1k / 1.2k
                          return '${s}k';
                        }
                        return n.toString();
                      }

                      final String countText = formatCount(rawCount);

                      return Row(
                        mainAxisSize: MainAxisSize.min, // 👈 jitni jarurat utni width
                        children: [
                          Text(
                            'Application',
                            style: baseStyle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              // color yahan NA do, TabBar labelColor handle karega
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '($countText)',
                            style: baseStyle.copyWith(
                              fontSize: 12,
                              color: const Color(0xff00D584), // count hamesha green
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),




                Tab(
                  child: FittedBox(
                    child: Text('College', style: TextStyle(fontSize: 14)),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    child: Text('Interviews', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),

            Expanded(
              // child: MultiBlocProvider(
              //   providers: [
              //     // BlocProvider(
              //     //   create: (_) => ApplicantBloc()..add(LoadDataApplicants(job: job.jobId)),
              //     // ),
              //     BlocProvider(
              //       create: (_) => DiscussionBloc()..add(LoadDiscussions(jobId:'255')),
              //       // create: (_) => DiscussionBloc()..add(LoadDiscussions(jobId: job.jobId.toString())),
              //     ),
              //   ],
              // 🟢 TAB 1: Applicant List
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      // 🔹 yeh row TabBar ke bilkul neeche aayegi
                      _buildSearchBar(),
                      Expanded(
                        child: BlocConsumer<ApplicantBloc, ApplicantState>(
                          listener: (context, state) {
                            if (state is ApplicantLoaded) {
                              setState(() {
                                for (final a in state.applicants) {
                                  _selectedStatuses[a.application_id] = a.application_status;
                                }
                              });
                            }
                          },

                          builder: (context, state) {
                            print(
                              '[ UI BUILD] Applicants: ${state is ApplicantLoaded ? state.applicants.length : 0}',
                            );

                            // if (state is ApplicantLoading &&
                            //     state.applicants.isEmpty) {
                            //   return const Center(child: CircularProgressIndicator());
                            // }
                            if ((state is ApplicantLoading &&
                                    state.applicants.isEmpty) ||
                                state is ApplicantInitial) {
                              // 🔹 First time load / initial: show skeleton list
                              return const _ApplicantSkeletonList();
                            }

                            if (state is ApplicantError &&
                                state.applicants.isEmpty) {
                              print("❌ ApplicationError: ${state.message}");

                              // ---- NEW: central force-logout checks ----
                              final code = state.statusCode;
                              final txt = (state.message ?? '').toLowerCase();

                              // 401 → force logout with message "You are currently logged"
                              final is401 =
                                  code == 401 ||
                                  txt.contains('you are currently logged');
                              if (is401) {
                                ForceLogout.run(
                                  context,
                                  message:
                                      'You are currently logged in on another device. Logging in here will log you out from the other device.',
                                );
                                // UI ko abhi kuch render na karao, logout nav handle karega
                                return const SizedBox.shrink();
                              }

                              // 403 → force logout with message "session expired."
                              final is403 =
                                  code == 403 ||
                                  txt.contains('session expired');
                              if (is403) {
                                ForceLogout.run(
                                  context,
                                  message: "session expired.",
                                );
                                return const SizedBox.shrink();
                              }

                              // Agar repository ne 403 + message diya ho:
                              final isExpired403 =
                                  state.statusCode == 406 &&
                                  (state.message ?? '').toLowerCase().contains(
                                    'expired',
                                  );

                              if (isExpired403) {
                                // pretty subscription page
                                return const SubscriptionExpiredScreen(); // arguments bhejne ho to bhej do
                              }
                              final failure = ApiHttpFailure(
                                statusCode: null,
                                body: state.message,
                              );
                              return OopsPage(failure: failure);
                            }

                            // ✅ List khaali?
                            final bool isEmptyList =
                                (state is ApplicantLoaded) &&
                                (state as ApplicantLoaded).applicants.isEmpty;

                            return Column(
                              children: [
                                Expanded(
                                  child: isEmptyList
                                      ? Center(
                                          child: Text(
                                            'No Applications', // ✅ bilkul data hi nahi (initial)
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xff003840),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemCount:
                                              state.applicants.length +
                                              ((state is ApplicantLoaded &&
                                                      !state.hasReachedMax)
                                                  ? 1
                                                  : 0),
                                          // Ensure it's always scrollable
                                          itemBuilder: (context, index) {
                                            if (index >=
                                                state.applicants.length) {
                                              return const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }

                                            final applicant =
                                                state.applicants[index];
                                            final selectedStatus =
                                                _selectedStatuses[applicant
                                                    .application_id] ??
                                                applicant.application_status;

                                            return GestureDetector(
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 4,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xffe5ebeb,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 8.0,
                                                              ), // Adjust the value as needed
                                                          child: Text(
                                                            trimToFirstNChars(toTitleCase
                                                             ( applicant.name,),
                                                              20,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                    0xff003840,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        InkWell(
                                                          onTap: () {
                                                            final applicantBloc = context.read<ApplicantBloc>(); // ✅ grab parent bloc once

                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => MultiBlocProvider(
                                                                  providers: [
                                                                    // ✅ keep your detail bloc as-is
                                                                    BlocProvider(
                                                                      create: (_) => ApplicanDetailBloc()
                                                                        ..add(
                                                                          LoadApplicant(
                                                                            applicationId: applicant.application_id,
                                                                            jobId: applicant.job_id,
                                                                            applicationStatus: applicant.application_status,
                                                                            userId: applicant.user_id,
                                                                          ),
                                                                        ),
                                                                    ),

                                                                    // ✅ IMPORTANT: pass existing ApplicantBloc to child screen
                                                                    BlocProvider.value(value: applicantBloc),
                                                                  ],
                                                                  child: ApplicantCVScreen(
                                                                    applicationId: applicant.application_id,
                                                                    jobId: applicant.job_id,
                                                                    applicationStatus: applicant.application_status,
                                                                    userId: applicant.user_id,
                                                                    job: job,
                                                                    applicantModel: applicant,
                                                                  ),
                                                                ),
                                                              ),
                                                            );

                                                            // NOTE:
                                                            // - Agar aap CV screen me pop nahi kar rahe, then(...) fire nahi hoga.
                                                            // - Parent update ke liye CV screen ke success pe:
                                                            //   context.read<ApplicantBloc>().add(UpdateApplicantStatus(...)) OR LoadDataApplicants(job)
                                                          },

                                                          // onTap: () {
                                                          //   Navigator.push(
                                                          //     context,
                                                          //     MaterialPageRoute(
                                                          //       builder: (context) => BlocProvider(
                                                          //         create: (_) => ApplicanDetailBloc()
                                                          //           ..add(
                                                          //             LoadApplicant(
                                                          //               applicationId:
                                                          //                   applicant.application_id,
                                                          //               jobId: applicant
                                                          //                   .job_id,
                                                          //               applicationStatus:
                                                          //                   applicant.application_status,
                                                          //               userId:
                                                          //                   applicant.user_id,
                                                          //             ),
                                                          //           ),
                                                          //         child: ApplicantCVScreen(
                                                          //           applicationId:
                                                          //               applicant
                                                          //                   .application_id,
                                                          //           jobId: applicant
                                                          //               .job_id,
                                                          //           applicationStatus:
                                                          //               applicant
                                                          //                   .application_status,
                                                          //           userId: applicant
                                                          //               .user_id,
                                                          //           job: job,
                                                          //           applicantModel:
                                                          //               applicant,
                                                          //         ),
                                                          //       ),
                                                          //     ),
                                                          //   ).then((result) {
                                                          //     // result ek Map ayega: { applicationId: ..., status: ... }
                                                          //     if (result
                                                          //         is Map) {
                                                          //       final int?
                                                          //       appId =
                                                          //           result['applicationId']
                                                          //               as int?;
                                                          //       final String?
                                                          //       status =
                                                          //           result['status']
                                                          //               as String?;
                                                          //
                                                          //       if (appId !=
                                                          //               null &&
                                                          //           status !=
                                                          //               null) {
                                                          //         setState(() {
                                                          //           _selectedStatuses[appId] =
                                                          //               status; // 👉 sirf UI override
                                                          //         });
                                                          //       }
                                                          //     }
                                                          //   });
                                                          //   // ).then((didUpdate) {
                                                          //   //   if (didUpdate ==
                                                          //   //       true) {
                                                          //   //     if (isFilterActive &&
                                                          //   //         filterCount >
                                                          //   //             0) {
                                                          //   //       _applyFilters(); // reload filtered data
                                                          //   //     } else {
                                                          //   //       context
                                                          //   //           .read<
                                                          //   //             ApplicantBloc
                                                          //   //           >()
                                                          //   //           .add(
                                                          //   //             LoadDataApplicants(
                                                          //   //               widget
                                                          //   //                   .job,
                                                          //   //             ),
                                                          //   //           ); // reload all
                                                          //   //     }
                                                          //   //   }
                                                          //   // });
                                                          // },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            decoration:
                                                                const BoxDecoration(
                                                                  color: Color(
                                                                    0xff005E6A,
                                                                  ),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            child: const Icon(
                                                              Icons
                                                                  .arrow_forward_ios,
                                                              size: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 2),
                                                    Card(
                                                      color: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.fromLTRB(
                                                              6,
                                                              6,
                                                              6,
                                                              6,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,

                                                          // ⬇️ REPLACE your Column(children: [...]) body with this:
                                                          children: [
                                                            // ---- precompute safe strings ----
                                                            Builder(
                                                              builder: (_) {
                                                                final uni =
                                                                    (applicant.university ??
                                                                            '')
                                                                        .trim();
                                                                final course =
                                                                    (applicant.current_course_name ??
                                                                            '')
                                                                        .trim();
                                                                final grade =
                                                                    (applicant.grade ??
                                                                            '')
                                                                        .trim();
                                                                final gType =
                                                                    (applicant.grade_type ??
                                                                            '')
                                                                        .trim();
                                                                final year =
                                                                    (applicant.year?.toString() ??
                                                                            '')
                                                                        .trim();

                                                                // "grade grade_type | year" ko smartly build karo (only when present)
                                                                final left =
                                                                    [
                                                                          grade,
                                                                          gType,
                                                                        ]
                                                                        .where(
                                                                          (
                                                                            s,
                                                                          ) => s
                                                                              .isNotEmpty,
                                                                        )
                                                                        .join(
                                                                          ' ',
                                                                        );
                                                                final right =
                                                                    year;
                                                                String detail;
                                                                if (left.isEmpty &&
                                                                    right
                                                                        .isEmpty) {
                                                                  detail = '';
                                                                } else if (left
                                                                    .isEmpty) {
                                                                  detail =
                                                                      right;
                                                                } else if (right
                                                                    .isEmpty) {
                                                                  detail = left;
                                                                } else {
                                                                  detail =
                                                                      '$left | $right';
                                                                }

                                                                final hasUni = uni
                                                                    .isNotEmpty;
                                                                final hasCourse =
                                                                    course
                                                                        .isNotEmpty;
                                                                final hasDetail =
                                                                    detail
                                                                        .isNotEmpty;

                                                                return Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    // University
                                                                    if (hasUni) ...[
                                                                      Text(
                                                                        uni,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: const TextStyle(
                                                                          color: Color(
                                                                            0xFF003840,
                                                                          ),
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            4,
                                                                      ),
                                                                    ],

                                                                    // Current course
                                                                    if (hasCourse) ...[
                                                                      Text(
                                                                        course,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: const TextStyle(
                                                                          color: Color(
                                                                            0xFF003840,
                                                                          ),
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                      // course ke baad gap sirf tab jab aage detail bhi aane wala ho
                                                                      if (hasDetail)
                                                                        const SizedBox(
                                                                          height:
                                                                              6,
                                                                        ),
                                                                    ],

                                                                    // Grade / Year detail
                                                                    if (hasDetail) ...[
                                                                      Text(
                                                                        detail,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: const TextStyle(
                                                                          color: Color(
                                                                            0xFF003840,
                                                                          ),
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            4,
                                                                      ),
                                                                    ],

                                                                    // ---- Shortlist row (always visible) ----
                                                                    Row(
                                                                      children: [
                                                                        const Text(
                                                                          'Shortlist:',
                                                                          style: TextStyle(
                                                                            fontFamily:
                                                                                "Inter",
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color: Color(
                                                                              0xFF003840,
                                                                            ),
                                                                            fontSize:
                                                                                14,
                                                                          ),
                                                                        ),
                                                                        const Spacer(),

                                                                        PopupMenuButton<
                                                                          String
                                                                        >(
                                                                          onOpened: () {
                                                                            setState(() {
                                                                              _menuOpenStates[applicant.application_id] = true;
                                                                            });
                                                                          },
                                                                          onCanceled: () {
                                                                            setState(() {
                                                                              _menuOpenStates[applicant.application_id] = false;
                                                                            });
                                                                          },
                                                                          onSelected:
                                                                              (
                                                                                value,
                                                                              ) async {
                                                                                setState(
                                                                                  () {
                                                                                    _menuOpenStates[applicant.application_id] = false;
                                                                                  },
                                                                                );

                                                                                final confirm = await _showConfirmDialog(
                                                                                  context,
                                                                                  "Are you sure you want to change status?",
                                                                                );
                                                                                if (!confirm) return;

                                                                                setState(
                                                                                  () {
                                                                                    _selectedStatuses[applicant.application_id] = value;
                                                                                  },
                                                                                );

                                                                                try {
                                                                                  await context
                                                                                      .read<
                                                                                        ApplicantBloc
                                                                                      >()
                                                                                      .updateApplicationStatus(
                                                                                        jobId: applicant.job_id,
                                                                                        applicationId: applicant.application_id,
                                                                                        action: value,
                                                                                      );
                                                                                  // ScaffoldMessenger.of(
                                                                                  //   context,
                                                                                  // ).showSnackBar(
                                                                                  //   SnackBar(
                                                                                  //     content: const Text(
                                                                                  //       "Applications updated successfully",
                                                                                  //       style: TextStyle(
                                                                                  //         color: Colors.white,
                                                                                  //       ),
                                                                                  //     ),
                                                                                  //     backgroundColor: Colors.green,
                                                                                  //     duration: const Duration(
                                                                                  //       seconds: 2,
                                                                                  //     ),
                                                                                  //     behavior: SnackBarBehavior.floating,
                                                                                  //     margin: const EdgeInsets.symmetric(
                                                                                  //       horizontal: 20,
                                                                                  //       vertical: 10,
                                                                                  //     ),
                                                                                  //     shape: RoundedRectangleBorder(
                                                                                  //       borderRadius: BorderRadius.circular(
                                                                                  //         10,
                                                                                  //       ),
                                                                                  //     ),
                                                                                  //   ),
                                                                                  // );
                                                                                  showSuccessSnackBar(context,"Applications updated successfully");

                                                                                } catch (
                                                                                  e
                                                                                ) {
                                                                                  ScaffoldMessenger.of(
                                                                                    context,
                                                                                  ).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text(
                                                                                        "Failed: ${e.toString()}",
                                                                                      ),
                                                                                      backgroundColor: Colors.red,
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              },
                                                                          itemBuilder:
                                                                              (
                                                                                context,
                                                                              ) {
                                                                                final stageList =
                                                                                    (state
                                                                                            as ApplicantLoaded)
                                                                                        .applicationStages;
                                                                                return stageList
                                                                                    .where(
                                                                                      (
                                                                                        stage,
                                                                                      ) =>
                                                                                          stage.name !=
                                                                                          'Applied',
                                                                                    )
                                                                                    .where(
                                                                                      (
                                                                                        stage,
                                                                                      ) =>
                                                                                          stage.name !=
                                                                                          'Candidate Declined',
                                                                                    )
                                                                                    .where(
                                                                                      (
                                                                                        stage,
                                                                                      ) =>
                                                                                          stage.name !=
                                                                                          'Round Shortlisted',
                                                                                    )
                                                                                    .where(
                                                                                      (
                                                                                        stage,
                                                                                      ) =>
                                                                                          stage.name !=
                                                                                          'Hold/Follow up',
                                                                                    )
                                                                                    .where(
                                                                                      (
                                                                                        stage,
                                                                                      ) =>
                                                                                          stage.name !=
                                                                                          'Hired',
                                                                                    )
                                                                                    .map(
                                                                                      (
                                                                                        stage,
                                                                                      ) {
                                                                                        Color bgColor;
                                                                                        Color textColor = Colors.black;
                                                                                        switch (stage.name) {
                                                                                          case 'Applied':
                                                                                            bgColor = const Color(
                                                                                              0xffE4D7F5,
                                                                                            );
                                                                                            textColor = Colors.deepPurple;
                                                                                            break;
                                                                                          case 'Cv Shortlist':
                                                                                            bgColor = const Color(
                                                                                              0xffFCE7C1,
                                                                                            );
                                                                                            textColor = Colors.brown;
                                                                                            break;
                                                                                          case 'HR Reject':
                                                                                            bgColor = const Color(
                                                                                              0xffFAD5D1,
                                                                                            );
                                                                                            textColor = Colors.redAccent;
                                                                                            break;
                                                                                          case 'Candidate Declined':
                                                                                            bgColor = const Color(
                                                                                              0xffF7CFC5,
                                                                                            );
                                                                                            textColor = Colors.brown;
                                                                                            break;
                                                                                          case 'Round Shortlisted':
                                                                                            bgColor = const Color(
                                                                                              0xffFFD980,
                                                                                            );
                                                                                            textColor = Colors.deepOrange;
                                                                                            break;
                                                                                          case 'Hold/Follow up':
                                                                                            bgColor = const Color(
                                                                                              0xffFFF3A3,
                                                                                            );
                                                                                            textColor = Colors.orange;
                                                                                            break;
                                                                                          case 'Final Selected':
                                                                                            bgColor = const Color(
                                                                                              0xff199C3E,
                                                                                            );
                                                                                            textColor = Colors.white;
                                                                                            break;
                                                                                          case 'Hired':
                                                                                            bgColor = const Color(
                                                                                              0xffD8F4B3,
                                                                                            );
                                                                                            textColor = const Color(
                                                                                              0xff005E38,
                                                                                            );
                                                                                            break;
                                                                                          default:
                                                                                            bgColor = Colors.grey.shade300;
                                                                                            textColor = Colors.black;
                                                                                        }
                                                                                        return PopupMenuItem<
                                                                                          String
                                                                                        >(
                                                                                          value: stage.name,
                                                                                          padding: const EdgeInsets.symmetric(
                                                                                            vertical: 3,
                                                                                            horizontal: 0,
                                                                                          ),
                                                                                          height: 20,
                                                                                          child: Center(
                                                                                            child: Container(
                                                                                              width: 120,
                                                                                              height: 25,
                                                                                              decoration: BoxDecoration(
                                                                                                color: bgColor,
                                                                                                borderRadius: BorderRadius.circular(
                                                                                                  30,
                                                                                                ),
                                                                                              ),
                                                                                              child: Center(
                                                                                                child: Text(
                                                                                                  stage.name,
                                                                                                  style: TextStyle(
                                                                                                    fontSize: 10,
                                                                                                    fontWeight: FontWeight.w600,
                                                                                                    color: textColor,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      },
                                                                                    )
                                                                                    .toList();
                                                                              },
                                                                          color:
                                                                              Colors.white,
                                                                          offset: const Offset(
                                                                            0,
                                                                            30,
                                                                          ),
                                                                          shape: RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                          ),
                                                                          constraints: const BoxConstraints(
                                                                            maxWidth:
                                                                                150,
                                                                            maxHeight:
                                                                                220,
                                                                          ),
                                                                          child: Container(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal: 6,
                                                                              vertical: 4,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: const Color(
                                                                                0xff005E6A,
                                                                              ),
                                                                              borderRadius: BorderRadius.circular(
                                                                                40,
                                                                              ),
                                                                            ),
                                                                            child: Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                Container(
                                                                                  padding: const EdgeInsets.symmetric(
                                                                                    horizontal: 12,
                                                                                    vertical: 4,
                                                                                  ),
                                                                                  decoration: BoxDecoration(
                                                                                    color: getStatusBackgroundColor(
                                                                                      selectedStatus,
                                                                                    ),
                                                                                    borderRadius: BorderRadius.circular(
                                                                                      40,
                                                                                    ),
                                                                                  ),
                                                                                  child: Text(
                                                                                    selectedStatus,
                                                                                    style: TextStyle(
                                                                                      fontSize: 12,
                                                                                      fontFamily: "Inter",
                                                                                      fontWeight: FontWeight.bold,
                                                                                      color: getStatusTextColor(
                                                                                        selectedStatus,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 8,
                                                                                ),
                                                                                Image.asset(
                                                                                  (_menuOpenStates[applicant.application_id] ??
                                                                                          false)
                                                                                      ? 'assets/uparrow.png'
                                                                                      : 'assets/downarrow.png',
                                                                                  width: 14,
                                                                                  height: 14,
                                                                                  color: Colors.white,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                          ],

                                                          // children: [
                                                          //   Text(
                                                          //     applicant.university,
                                                          //     maxLines: 1,
                                                          //     overflow: TextOverflow
                                                          //         .ellipsis,
                                                          //     style: const TextStyle(
                                                          //       color: Color(
                                                          //         0xFF003840,
                                                          //       ),
                                                          //       fontSize: 12,
                                                          //     ),
                                                          //   ),
                                                          //   const SizedBox(height: 4),
                                                          //   Text(
                                                          //     applicant
                                                          //         .current_course_name,
                                                          //     style: const TextStyle(
                                                          //       color: Color(
                                                          //         0xFF003840,
                                                          //       ),
                                                          //       fontSize: 12,
                                                          //     ),
                                                          //   ),
                                                          //   const SizedBox(height: 6),
                                                          //   Text(
                                                          //     '${applicant.grade} ${applicant.grade_type} | ${applicant.year}',
                                                          //     style: const TextStyle(
                                                          //       color: Color(
                                                          //         0xFF003840,
                                                          //       ),
                                                          //       fontSize: 12,
                                                          //     ),
                                                          //   ),
                                                          //   const SizedBox(height: 4),
                                                          //   Row(
                                                          //     children: [
                                                          //       const Text(
                                                          //         'Shortlist:',
                                                          //         style: TextStyle(
                                                          //           fontFamily:
                                                          //               "Inter",
                                                          //           fontWeight:
                                                          //               FontWeight
                                                          //                   .w600,
                                                          //           color: Color(
                                                          //             0xFF003840,
                                                          //           ), // Teal black
                                                          //           fontSize:
                                                          //               14, // Bigger size based on screenshot
                                                          //         ),
                                                          //       ),
                                                          //       // const SizedBox(width: 10),
                                                          //       const Spacer(),
                                                          //       // space between label and capsule
                                                          //       PopupMenuButton<
                                                          //         String
                                                          //       >(
                                                          //         onOpened: () {
                                                          //           setState(() {
                                                          //             _menuOpenStates[applicant
                                                          //                     .application_id] =
                                                          //                 true; // sirf us row ka open
                                                          //           });
                                                          //         },
                                                          //         onCanceled: () {
                                                          //           setState(() {
                                                          //             _menuOpenStates[applicant
                                                          //                     .application_id] =
                                                          //                 false; // sirf us row ka close
                                                          //           });
                                                          //         },
                                                          //         onSelected: (value) async {
                                                          //           setState(() {
                                                          //             _menuOpenStates[applicant
                                                          //                     .application_id] =
                                                          //                 false; // select hone par band
                                                          //           });
                                                          //
                                                          //           final confirm =
                                                          //               await _showConfirmDialog(
                                                          //                 context,
                                                          //                 "Are you sure you want to change status?",
                                                          //               );
                                                          //
                                                          //           if (!confirm)
                                                          //             return;
                                                          //
                                                          //           setState(() {
                                                          //             _selectedStatuses[applicant
                                                          //                     .application_id] =
                                                          //                 value;
                                                          //           });
                                                          //
                                                          //           try {
                                                          //             await context
                                                          //                 .read<
                                                          //                   ApplicantBloc
                                                          //                 >()
                                                          //                 .updateApplicationStatus(
                                                          //                   jobId: applicant
                                                          //                       .job_id,
                                                          //                   applicationId:
                                                          //                       applicant
                                                          //                           .application_id,
                                                          //                   action:
                                                          //                       value,
                                                          //                 );
                                                          //
                                                          //             ScaffoldMessenger.of(
                                                          //               context,
                                                          //             ).showSnackBar(
                                                          //               SnackBar(
                                                          //                 content: Text(
                                                          //                   "Applications updated successfully",
                                                          //                   style: TextStyle(
                                                          //                     color: Colors
                                                          //                         .white,
                                                          //                   ),
                                                          //                 ),
                                                          //                 backgroundColor:
                                                          //                     Colors
                                                          //                         .green,
                                                          //                 duration:
                                                          //                     Duration(
                                                          //                       seconds:
                                                          //                           2,
                                                          //                     ),
                                                          //                 behavior:
                                                          //                     SnackBarBehavior
                                                          //                         .floating,
                                                          //                 margin: EdgeInsets.symmetric(
                                                          //                   horizontal:
                                                          //                       20,
                                                          //                   vertical:
                                                          //                       10,
                                                          //                 ),
                                                          //                 shape: RoundedRectangleBorder(
                                                          //                   borderRadius:
                                                          //                       BorderRadius.circular(
                                                          //                         10,
                                                          //                       ),
                                                          //                 ),
                                                          //               ),
                                                          //             );
                                                          //           } catch (e) {
                                                          //             ScaffoldMessenger.of(
                                                          //               context,
                                                          //             ).showSnackBar(
                                                          //               SnackBar(
                                                          //                 content: Text(
                                                          //                   "Failed: ${e.toString()}",
                                                          //                 ),
                                                          //                 backgroundColor:
                                                          //                     Colors
                                                          //                         .red,
                                                          //               ),
                                                          //             );
                                                          //           }
                                                          //         },
                                                          //         itemBuilder:
                                                          //             (
                                                          //               BuildContext
                                                          //               context,
                                                          //             ) {
                                                          //               final stageList =
                                                          //                   (state
                                                          //                           as ApplicantLoaded)
                                                          //                       .applicationStages;
                                                          //
                                                          //               return stageList
                                                          //                   .where(
                                                          //                     (
                                                          //                       stage,
                                                          //                     ) =>
                                                          //                         stage.name !=
                                                          //                         'Applied',
                                                          //                   )
                                                          //                   .where(
                                                          //                     (
                                                          //                       stage,
                                                          //                     ) =>
                                                          //                         stage.name !=
                                                          //                         'Candidate Declined',
                                                          //                   )
                                                          //                   .where(
                                                          //                     (
                                                          //                       stage,
                                                          //                     ) =>
                                                          //                         stage.name !=
                                                          //                         'Round Shortlisted',
                                                          //                   )
                                                          //                   .where(
                                                          //                     (
                                                          //                       stage,
                                                          //                     ) =>
                                                          //                         stage.name !=
                                                          //                         'Hold/Follow up',
                                                          //                   )
                                                          //                   .where(
                                                          //                     (
                                                          //                       stage,
                                                          //                     ) =>
                                                          //                         stage.name !=
                                                          //                         'Hired',
                                                          //                   )
                                                          //                   .map((
                                                          //                     stage,
                                                          //                   ) {
                                                          //                     Color
                                                          //                     bgColor;
                                                          //                     Color
                                                          //                     textColor =
                                                          //                         Colors.black;
                                                          //
                                                          //                     switch (stage
                                                          //                         .name) {
                                                          //                       case 'Applied':
                                                          //                         bgColor = Color(
                                                          //                           0xffE4D7F5,
                                                          //                         );
                                                          //                         textColor =
                                                          //                             Colors.deepPurple;
                                                          //                         break;
                                                          //                       case 'Cv Shortlist':
                                                          //                         bgColor = Color(
                                                          //                           0xffFCE7C1,
                                                          //                         );
                                                          //                         textColor =
                                                          //                             Colors.brown;
                                                          //                         break;
                                                          //                       case 'HR Reject':
                                                          //                         bgColor = Color(
                                                          //                           0xffFAD5D1,
                                                          //                         );
                                                          //                         textColor =
                                                          //                             Colors.redAccent;
                                                          //                         break;
                                                          //                       case 'Candidate Declined':
                                                          //                         bgColor = Color(
                                                          //                           0xffF7CFC5,
                                                          //                         );
                                                          //                         textColor =
                                                          //                             Colors.brown.shade700;
                                                          //                         break;
                                                          //                       case 'Round Shortlisted':
                                                          //                         bgColor = Color(
                                                          //                           0xffFFD980,
                                                          //                         );
                                                          //                         textColor =
                                                          //                             Colors.deepOrange;
                                                          //                         break;
                                                          //                       case 'Hold/Follow up':
                                                          //                         bgColor = Color(
                                                          //                           0xffFFF3A3,
                                                          //                         );
                                                          //                         textColor =
                                                          //                             Colors.orange;
                                                          //                         break;
                                                          //                       case 'Final Selected':
                                                          //                         bgColor = Color(
                                                          //                           0xff199C3E,
                                                          //                         );
                                                          //                         textColor =
                                                          //                             Colors.white;
                                                          //                         break;
                                                          //                       case 'Hired':
                                                          //                         bgColor = Color(
                                                          //                           0xffD8F4B3,
                                                          //                         );
                                                          //                         textColor = Color(
                                                          //                           0xff005E38,
                                                          //                         );
                                                          //                         break;
                                                          //                       default:
                                                          //                         bgColor =
                                                          //                             Colors.grey.shade300;
                                                          //                         textColor =
                                                          //                             Colors.black;
                                                          //                     }
                                                          //
                                                          //                     return PopupMenuItem<
                                                          //                       String
                                                          //                     >(
                                                          //                       value:
                                                          //                           stage.name,
                                                          //                       padding: EdgeInsets.symmetric(
                                                          //                         vertical:
                                                          //                             3,
                                                          //                         horizontal:
                                                          //                             0,
                                                          //                       ),
                                                          //                       height:
                                                          //                           20,
                                                          //                       child: Center(
                                                          //                         child: Container(
                                                          //                           width: 120,
                                                          //                           height: 25,
                                                          //                           decoration: BoxDecoration(
                                                          //                             color: bgColor,
                                                          //                             borderRadius: BorderRadius.circular(
                                                          //                               30,
                                                          //                             ),
                                                          //                           ),
                                                          //                           child: Center(
                                                          //                             child: Text(
                                                          //                               stage.name,
                                                          //                               style: TextStyle(
                                                          //                                 fontSize: 10,
                                                          //                                 fontWeight: FontWeight.w600,
                                                          //                                 color: textColor,
                                                          //                               ),
                                                          //                             ),
                                                          //                           ),
                                                          //                         ),
                                                          //                       ),
                                                          //                     );
                                                          //                   })
                                                          //                   .toList();
                                                          //             },
                                                          //         color: Colors.white,
                                                          //         offset: Offset(
                                                          //           0,
                                                          //           30,
                                                          //         ),
                                                          //         shape: RoundedRectangleBorder(
                                                          //           borderRadius:
                                                          //               BorderRadius.circular(
                                                          //                 12,
                                                          //               ),
                                                          //         ),
                                                          //         constraints:
                                                          //             BoxConstraints(
                                                          //               maxWidth: 150,
                                                          //               maxHeight:
                                                          //                   220,
                                                          //             ),
                                                          //
                                                          //         // 👇 yaha pura capsule rakho
                                                          //         child: Container(
                                                          //           padding:
                                                          //               const EdgeInsets.symmetric(
                                                          //                 horizontal:
                                                          //                     6,
                                                          //                 vertical: 4,
                                                          //               ),
                                                          //           decoration: BoxDecoration(
                                                          //             color:
                                                          //                 const Color(
                                                          //                   0xff005E6A,
                                                          //                 ),
                                                          //             borderRadius:
                                                          //                 BorderRadius.circular(
                                                          //                   40,
                                                          //                 ),
                                                          //           ),
                                                          //           child: Row(
                                                          //             mainAxisSize:
                                                          //                 MainAxisSize
                                                          //                     .min,
                                                          //             children: [
                                                          //               Container(
                                                          //                 padding: const EdgeInsets.symmetric(
                                                          //                   horizontal:
                                                          //                       12,
                                                          //                   vertical:
                                                          //                       4,
                                                          //                 ),
                                                          //                 decoration: BoxDecoration(
                                                          //                   color: getStatusBackgroundColor(
                                                          //                     selectedStatus,
                                                          //                   ),
                                                          //                   borderRadius:
                                                          //                       BorderRadius.circular(
                                                          //                         40,
                                                          //                       ),
                                                          //                 ),
                                                          //                 child: Text(
                                                          //                   selectedStatus,
                                                          //                   style: TextStyle(
                                                          //                     fontSize:
                                                          //                         12,
                                                          //                     fontFamily:
                                                          //                         "Inter",
                                                          //                     fontWeight:
                                                          //                         FontWeight.bold,
                                                          //                     color: getStatusTextColor(
                                                          //                       selectedStatus,
                                                          //                     ),
                                                          //                   ),
                                                          //                 ),
                                                          //               ),
                                                          //               const SizedBox(
                                                          //                 width: 8,
                                                          //               ),
                                                          //               Image.asset(
                                                          //                 (_menuOpenStates[applicant.application_id] ??
                                                          //                         false)
                                                          //                     ? 'assets/uparrow.png'
                                                          //                     : 'assets/downarrow.png',
                                                          //                 width: 14,
                                                          //                 height: 14,
                                                          //                 color: Colors
                                                          //                     .white,
                                                          //               ),
                                                          //             ],
                                                          //           ),
                                                          //         ),
                                                          //       ),
                                                          //     ],
                                                          //   ),
                                                          // ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // TAB 2: Colleges
                  CollegeListScreen(job: job),

                  //  TAB 3: Interviews
                  // InterviewBottomNav(
                  //   meetings: [],
                  //   showAppBar: false, // 👈 ab AppBar nahi aayega
                  // ),
                  // Example: showing just the first one
                  InterViewTab(
                    meetings: [],
                    showAppBar: false,
                    jobs: job, // 👈 ab AppBar nahi aayega
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getStatusBackgroundColor(String status) {
    switch (status) {
      case 'Applied':
        return Color(0xffE4D7F5);
      case 'Cv Shortlist':
        return Color(0xffFCE7C1);
      case 'HR Reject':
        return Color(0xffFAD5D1);
      case 'Candidate Declined':
        return Color(0xffF7CFC5);
      case 'Round Shortlisted':
        return Color(0xffFFD980);
      case 'Hold/Follow up':
        return Color(0xffFFF3A3);
      case 'Final Selected':
        return Color(0xff199C3E);
      case 'Hired':
        return Color(0xffD8F4B3);
      default:
        return Colors.grey.shade300;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status) {
      case 'Applied':
        return Colors.deepPurple;
      case 'Cv Shortlist':
        return Colors.brown;
      case 'HR Reject':
        return Colors.redAccent;
      case 'Candidate Declined':
        return Colors.brown;
      case 'Round Shortlisted':
        return Colors.deepOrange;
      case 'Hold/Follow up':
        return Colors.orange;
      case 'Final Selected':
        return Colors.white;
      case 'Hired':
        return Color(0xff005E38);
      default:
        return Colors.black;
    }
  }

  String trimToFirstNChars(String text, [int n = 10]) {
    text = text.trim();
    if (text.length <= n)
      return text; // agar text chhota hai to pura return karo
    return text.substring(0, n) + '...'; // first n characters + ...
  }

  String toTitleCase(String text) {
    if (text.trim().isEmpty) return text;

    return text
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatLocation(String? locationString) {
    if (locationString == null || locationString.trim().isEmpty) {
      return 'Mumbai, Bangalore, New Delhi, +3 More';
    }

    final locations = locationString.split(',').map((e) => e.trim()).toList();

    if (locations.length <= 3) {
      return locations.join(', ');
    } else {
      final shown = locations.take(3).join(', ');
      final remaining = locations.length - 3;
      return '$shown, +$remaining More';
    }
  }

  // Common confirm dialog function
  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline, size: 48, color: Color(0xff005E6A)),
                const SizedBox(height: 16),
                Text(
                  "Confirmation",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "No",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff005E6A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Yes",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}

class _ApplicantSkeletonList extends StatelessWidget {
  const _ApplicantSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: 6, // 6 fake applicants
        itemBuilder: (context, index) => const _ApplicantSkeletonItem(),
      ),
    );
  }
}

class _ApplicantSkeletonItem extends StatelessWidget {
  const _ApplicantSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xffe5ebeb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Top row: applicant name + arrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  'Applicant Name Placeholder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff003840),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              CircleAvatar(radius: 14),
            ],
          ),
          const SizedBox(height: 4),

          // 🔹 Inner white card – university / course / grade + shortlist row
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // University
                  Text(
                    'University Name Placeholder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF003840), fontSize: 12),
                  ),
                  SizedBox(height: 4),

                  // Course
                  Text(
                    'Course Name Placeholder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF003840), fontSize: 12),
                  ),
                  SizedBox(height: 6),

                  // Grade / Year
                  Text(
                    'Grade • Year Placeholder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF003840), fontSize: 12),
                  ),
                  SizedBox(height: 6),

                  // Shortlist row
                  Row(
                    children: [
                      Text(
                        'Shortlist:',
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF003840),
                          fontSize: 14,
                        ),
                      ),
                      Spacer(),
                      // Capsule placeholder (status chip)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          // color: Color(0xff005E6A),
                          // borderRadius: BorderRadius.all(Radius.circular(40)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 30,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//------------Wrap Text Code----------------

String _wrapTitle(String title) {
  List<String> words = title.split(' ');
  if (words.length <= 5) {
    return title;
  } else {
    // First 5 words in line 1, rest in line 2
    String firstLine = words.sublist(0, 5).join(' ');
    String secondLine = words.sublist(5).join(' ');
    return '$firstLine\n$secondLine';
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skillsconnect/HR/bloc/Applicant_details/applicant_deatils_event.dart';
import 'package:skillsconnect/HR/bloc/Applicants_Data/applicant_bloc.dart';
import 'package:skillsconnect/HR/bloc/Applicants_Data/applicant_event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/HR/model/applicant_model.dart';
import 'package:skillsconnect/HR/screens/applications_screen.dart';
import 'package:skillsconnect/HR/screens/notification_screen.dart';
import 'package:skillsconnect/HR/screens/summary_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../Error_Handler/subscription_expired_screen.dart';
import '../../utils/company_service.dart';
import '../bloc/Job/job_bloc.dart';
import '../bloc/Job/job_event.dart';
import '../bloc/Job/job_state.dart';
import '../model/job_model.dart';
import 'EnterOtpScreen.dart';
import 'ForceUpdate/Forcelogout.dart';
import 'ForceUpdate/force_update.dart';
import 'custom_app_bar.dart';
import 'interview_bottom_nav.dart';
import 'login_screen.dart';

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  int _selectedTab = 0;
  List<JobModel> _filteredJobs = [];
  String companyName = '';
  String companyLogo = '';
  FilterOption? jobType, jobTitle, workCulture, jobStatus, selectCourse, jobLocation;
  bool isFilterApplied = false;
  late final ScrollController _jobCtrl = ScrollController();
  String _searchQuery = '';




  @override
  void initState() {
    super.initState();
    loadCompanyName();
    context.read<JobBloc>().add(LoadJobsEvent());
    // Call async code via helper
    _initAsync();

    _jobCtrl.addListener(() {
      final st = context.read<JobBloc>().state;
      if (st is! JobLoaded) return;

      final pos = _jobCtrl.position;
      final atBottom = pos.hasPixels && pos.pixels >= pos.maxScrollExtent;

      if (atBottom && st.hasMore) {
        // next page (page + 1)
        context.read<JobBloc>().add(FetchJobsEvent(page: 0, limit: 5));
      }
    });

    // Wait until first frame is rendered, then check
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     checkAndForceUpdate(context);
    //   }
    // });
  }


  @override
  void dispose() {
    _jobCtrl.dispose();
    super.dispose();
  }


  // Helper async function
  Future<void> _initAsync() async {
    await CompanyInfoService.refreshSilently();
  }

  Future<void> loadCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('company_name') ?? '';
    final logoUrl = prefs.getString('company_logo');
    setState(() {
      companyName = name;
      companyLogo = logoUrl ?? '';
    });
  }

  //---------Filter Code Start------------------------------

  final List<FiltersConfigure> filters = [
    FiltersConfigure('Job Type', 'job_type', 'job_type'),
    FiltersConfigure('Job Title', 'title', 'title'),
    FiltersConfigure('Work Culture', 'opportunity_type', 'opportunity_type'),
    FiltersConfigure('Job Status', 'job_status', 'job_status'),
    FiltersConfigure('Course', 'course', 'course'),
    FiltersConfigure('Location', 'city_name', 'city_name'),
  ];

  void _applyFilters() async {
    print('🔽 Apply Filters Clicked');

    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    print('📦 Sending Filter Request...');
    print('Token: $token');
    print('Filters:');
    print('job_type: ${jobType?.name}');
    print('job_title: ${jobTitle?.name}');
    print('work_culture: ${workCulture?.name}');
    print('job_status: ${jobStatus?.name}');
    print('course: ${selectCourse?.name}');
    print('location: ${jobLocation?.name}');

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}jobs'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          // "company_name": "",

          if (jobType?.name != null && jobType!.name.isNotEmpty)
            "job_type": jobType!.name,

          if (jobTitle?.name != null && jobTitle!.name.isNotEmpty)
            "job_title": jobTitle!.name,

          if (workCulture?.name != null && workCulture!.name.isNotEmpty)
            "work_culuture": workCulture!.name,

          if (jobStatus?.name != null && jobStatus!.name.isNotEmpty)
            "job_status": jobStatus!.name,

          if (selectCourse?.name != null && selectCourse!.name.isNotEmpty)
            "course": selectCourse!.name,

          if (jobLocation?.name != null && jobLocation!.name.isNotEmpty)
            "location": jobLocation!.name,

          // Optional: only if pagination is still used
          // Otherwise, just remove these two lines
          // "page": "",
          // "rows": "",
        }),

      );

      print('📩 Response Status Code: ${response.statusCode}');
      print('📩 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobList = (data['data'] as List).map((e) => JobModel.fromJson(e)).toList();

        print('✅ Filtered Jobs Received: ${jobList.length}');

        if (mounted) {
          context.read<JobBloc>().add(ApplyFilterEvent(jobList));
          setState(() {
            isFilterApplied = true;
            _filteredJobs = jobList;
          });
        }
      } else {
        print('❌ API Error: ${response.statusCode}');
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Exception in _applyFilters: $e');
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Failed to load filtered jobs: $e")),
        // );
        showErrorSnackBar(context,"Failed to load filtered jobs");
      }
    }
  }

  void _clearFilters() {
    setState(() {
      jobType = null;
      jobTitle = null;
      workCulture = null;
      jobStatus = null;
      selectCourse = null;
      jobLocation = null;
      isFilterApplied = false;
      _filteredJobs.clear();

    });
    // context.read<JobBloc>().add(FetchJobsEvent(page: 0, limit: _itemsPerPage));
  }

  Future<void> _showFilterBottomSheet(BuildContext parentContext) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xffEBF6F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 36,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                          'Filters',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filters.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(filters[i].label, style: const TextStyle(color: Color(0xff003840))),
                              const SizedBox(height: 6),
                              DropdownSearch<FilterOption>(
                                selectedItem: [
                                  jobType,
                                  jobTitle,
                                  workCulture,
                                  jobStatus,
                                  selectCourse,
                                  jobLocation,
                                ][i],
                                asyncItems: (String filter) => fetchFilterOptions(filter, filters[i]),
                                itemAsString: (u) => u.name,
                                onChanged: (val) => setModalState(() {
                                  switch (i) {
                                    case 0: jobType = val; break;
                                    case 1: jobTitle = val; break;
                                    case 2: workCulture = val; break;
                                    case 3: jobStatus = val; break;
                                    case 4: selectCourse = val; break;
                                    case 5: jobLocation = val; break;
                                  }
                                }),
                                popupProps: const PopupProps.menu(showSearchBox: true),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'Please Select',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                                dropdownButtonProps: const DropdownButtonProps(
                                  icon: Icon(
                                    CupertinoIcons.chevron_down,
                                    color: Color(0xff003840),
                                    size: 16,
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              jobType = null;
                              jobTitle = null;
                              workCulture = null;
                              jobStatus = null;
                              selectCourse = null;
                              jobLocation = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Color(0xFF003840)),
                          ),
                          child: const Text('Clear', style: TextStyle(color: Color(0xFF003840))),
                        ),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003840),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Apply', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<List<FilterOption>> fetchFilterOptions(String query, FiltersConfigure config) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final Map<String, dynamic> body = {
      "company_name": "",
      "job_type": config.filterKey == "job_type" ? query : "",
      "job_title": config.filterKey == "title" ? query : "",
      "work_culuture": config.filterKey == "opportunity_type" ? query : "",
      "job_status": config.filterKey == "job_status" ? query : "",
      "course": config.filterKey == "course" ? query : "",
      "location": config.filterKey == "city_name" ? query : "",
      "page": "",
      "rows": "",
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.skillsconnect.in/dcxqyqzqpdydfk/api/jobs'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'] ?? [];
        final uniqueOptions = <String, FilterOption>{};

        for (var item in data) {
          final value = item[config.fieldName]?.toString();
          if (value != null && value.isNotEmpty) {
            uniqueOptions[value] = FilterOption.fromJson(item, config.fieldName);
          }
        }

        return uniqueOptions.values.toList();
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching filter options: $e");
      return [];
    }
  }


  //---------Filter Code End------------------------------


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: ListTile(
      //     leading: CircleAvatar(
      //       backgroundImage: companyLogo.isNotEmpty
      //           ? NetworkImage(companyLogo)
      //           : const AssetImage('assets/placeholder.png') as ImageProvider,
      //     ),
      //     title: Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff25282B))),
      //   ),
      //   actions: [
      //     Padding(
      //       padding: const EdgeInsets.only(right: 16.0),
      //       child: InkWell(
      //         borderRadius: BorderRadius.circular(20),
      //         onTap: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => NotificationsScreen()),
      //           );
      //         },
      //         child: CircleAvatar(
      //           backgroundColor: Colors.green.shade50,
      //           radius: 20,
      //           child: ClipOval(
      //             child: Image.asset(
      //               'assets/notification.png',
      //               height: 40,
      //               width: 40,
      //               fit: BoxFit.cover,
      //             ),
      //           ),
      //         ),
      //       ),
      //     ),
      //   ],
      //   backgroundColor: const Color(0xffebf6f7),
      //   elevation: 0,
      // ),
      appBar: const CustomAppBar(),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(66, 10, 26, 5),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Column(
                    children: [
                      Text(
                        'Active Jobs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _selectedTab == 0 ? const Color(0xFF003840) : Colors.grey,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: 100,
                        color: _selectedTab == 0 ? const Color(0xff00D584) : Colors.transparent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 50),
                GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Column(
                    children: [
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _selectedTab == 1 ? const Color(0xFF003840) : Colors.grey,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 3,
                        width: 80,
                        color: _selectedTab == 1 ? Colors.green : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedTab == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        onChanged: (query) {
                          _searchQuery = query.trim(); // 👈 add this

                          if (isFilterApplied) {
                            setState(() {
                              _filteredJobs = _filteredJobs.where((job) =>
                              job.title.toLowerCase().contains(query.toLowerCase()) ||
                                  job.location.toLowerCase().contains(query.toLowerCase())
                              ).toList();
                            });
                          } else {
                            context.read<JobBloc>().add(SearchJobsEvent(query));
                          }
                        },

                        // onChanged: (query) {
                        //   if (isFilterApplied) {
                        //     setState(() {
                        //       _filteredJobs = _filteredJobs.where((job) =>
                        //       job.title.toLowerCase().contains(query.toLowerCase()) ||
                        //           job.location.toLowerCase().contains(query.toLowerCase())
                        //       ).toList();
                        //     });
                        //   } else {
                        //     context.read<JobBloc>().add(SearchJobsEvent(query));
                        //   }
                        // },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(color: Colors.green.shade50)),
                        ),
                      ),
                    ),
                  ),
                  // Filter code Comment

                  // const SizedBox(width: 10),
                  // Container(
                  //   padding: const EdgeInsets.all(2),
                  //   decoration: BoxDecoration(
                  //     shape: BoxShape.circle,
                  //     border: Border.all(
                  //       color: const Color(0x20005E6A),
                  //       width: 2,
                  //     ),
                  //   ),
                  //   child: InkWell(
                  //     onTap: () => _showFilterBottomSheet(context),
                  //     borderRadius: BorderRadius.circular(100),
                  //     child: const CircleAvatar(
                  //       radius: 18,
                  //       backgroundColor: Colors.white,
                  //       child: Icon(
                  //         Icons.filter_list_rounded,
                  //         size: 20,
                  //         color: Color(0xff003840),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          Expanded(
            child: _selectedTab == 0
                ? BlocBuilder<JobBloc, JobState>(
              builder: (context, state) {
                //  1. If filters are applied, use local list (_paginatedJobs)
                if (isFilterApplied) {
                  return _filteredJobs.isEmpty
                      ? const Center(child: Text('No jobs'))
                      : ListView.builder(
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      return JobCard(job: _filteredJobs[index]);
                    },
                  );
                }

                //  2. While loading
                // if (state is JobLoading) {
                //   return const Center(child: CircularProgressIndicator());
                // }

                //  2. While loading
                if (state is JobLoading) {
                  return Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      itemCount: 5, // 5 fake cards
                      itemBuilder: (context, index) => const JobHRCardSkeleton(),
                    ),
                  );
                }


                // if (state is JobForceLogout) {
                //   // 1) storage clear
                //   () async {
                //     final sp = await SharedPreferences.getInstance();
                //     await sp.remove('auth_token');
                //     await sp.remove('user_data');
                //     await sp.remove('user_id');
                //     // agar app me aur bhi session keys hain to yahan remove kar do
                //
                //     // 2) navigation (safest: pushAndRemoveUntil)
                //     if (context.mounted) {
                //       Navigator.of(context).pushAndRemoveUntil(
                //         MaterialPageRoute(builder: (_) =>  LoginScreen()), // ✅ direct LoginScreen
                //             (route) => false,
                //       );
                //     }
                //   }(); // fire-and-forget to avoid setState in build warnings
                //
                //   // is frame me kuch render na karo
                //   return const SizedBox.shrink();
                // }


                //  3. If error
                if (state is JobError) {
                  print('🟠 JobError Occurred!');
                  print('🔹 Status Code: ${state.statusCode}');
                  print('🔹 Message: ${state.message}');

                  int? extractedCode;
                  if (state.statusCode == null && state.message != null) {
                    final match = RegExp(r'\b(\d{3})\b').firstMatch(state.message!);
                    if (match != null) {
                      extractedCode = int.tryParse(match.group(1)!);
                      print('🧩 Extracted Status Code from message: $extractedCode');
                    }
                  }

                  final actualCode = state.statusCode ?? extractedCode;
                  print('✅ Final Status Code Used: $actualCode');


                  // 🔴 NEW: 401 → force logout
                  if (actualCode == 401) {
                    ForceLogout.run(context, message: 'You are currently logged in on another device. '
                        'Logging in here will log you out from the other device');
                    return const SizedBox.shrink(); // UI placeholder while navigating
                  }

                  // 🔴 NEW: 403 → force logout
                  if (actualCode == 403) {
                    ForceLogout.run(context, message: "session expired.");
                    return const SizedBox.shrink();
                  }

                  // 🔹 403 detect hone par direct subscription page
                  final isExpired403 = actualCode == 406;

                  if (isExpired403) {
                    print('⚠️ Subscription expired detected (403)');
                    return const SubscriptionExpiredScreen();
                  }

                  final failure = ApiHttpFailure(
                    statusCode: actualCode,
                    body: state.message,
                  );

                  print('❌ Navigating to OopsPage with failure: $failure');
                  return OopsPage(failure: failure);
                }
                // if (state is JobError) {
                //   return Center(
                //     child: Text("Error: ${state.message}",
                //         style: const TextStyle(color: Colors.red)),
                //   );
                // }

                // 4. If jobs are loaded
                if (state is JobLoaded) {
                  final jobs = state.jobs;

                  // 🔹 Agar bilkul jobs hi nahi aayi (no search, no filter) -> "No jobs"
                  if (!isFilterApplied && _searchQuery.isEmpty && jobs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No jobs',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0x80003840),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  // 🔹 Agar search kiya hai aur result empty hai -> bhi "No jobs"
                  if (!isFilterApplied && _searchQuery.isNotEmpty && jobs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Data',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0x80003840),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  final showLoaderRow = state.hasMore; // agar isFetchingMore flag hai to usse use karo

                  final itemCount = jobs.length + (showLoaderRow ? 1 : 0);

                  return ListView.builder(
                    controller: _jobCtrl,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      final isLoader = showLoaderRow && index == itemCount - 1;
                      if (isLoader) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      }
                      final job = jobs[index];
                      return JobCard(job: job);
                    },
                  );
                }

                return const SizedBox();
              },
            )
                : const SummaryScreen(),
          ),

        ],
      ),
    );
  }
}



class JobHRCardSkeleton extends StatelessWidget {
  const JobHRCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xffe5ebeb),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Inner white card – same structure as JobCard
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 5, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Job Title Placeholder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003840),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 4),

                    // Location
                    Text(
                      'Location Placeholder',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF003840),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    SizedBox(height: 8),

                    // Job Type chip
                    Align(
                      alignment: Alignment.centerLeft,
                      child:  DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xffEBF6F7),
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          border: Border.fromBorderSide(
                            BorderSide(color: Color(0x40003840)),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Job Type',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF003840),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 6),

                    // Salary + Applicants row
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xffEBF6F7),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0x40003840)),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '₹ Salary / Stipend',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF003840),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xffEBF6F7),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0x40003840)),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '120 Applications',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF003840),
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

            // 🔹 Bottom row: expiry pill + status + arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: expiry pill
                Container(
                  width: 175,
                  margin: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xff701100),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Job expires in 7 days',
                          style: TextStyle(
                            color: Color(0xff701100),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    // Status chip
                    Container(
                      margin: const EdgeInsets.fromLTRB(0, 4, 0, 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCAFEE3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Publish',
                        style: TextStyle(
                          color: Color(0xff006A41),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Arrow icon
                    Container(
                      margin: const EdgeInsets.fromLTRB(1, 4, 4, 6),
                      padding: const EdgeInsets.all(6),
                      child:CircleAvatar(radius: 14),

                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}




////------------------Filter Api Start------------------
class FiltersConfigure {
  final String label;
  final String filterKey;
  final String fieldName;

  const FiltersConfigure(this.label, this.filterKey, this.fieldName);
}

class FilterOption {
  final String name;
  final int id;

  FilterOption({required this.name, required this.id});

  factory FilterOption.fromJson(Map<String, dynamic> json, String field) {
    return FilterOption(
      name: json[field]?.toString() ?? '',
      id: json['id'] ?? 0,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is FilterOption && other.name == name && other.id == id);

  @override
  int get hashCode => name.hashCode ^ id.hashCode;
}

////------------------Filter Api End------------------


// class JobCard extends StatelessWidget {
//   final JobModel job;
//   const JobCard({super.key, required this.job});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       color: const Color(0xffe5ebeb),
//       child: Padding(
//         padding: const EdgeInsets.all(0.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               color: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//                 side: BorderSide(color: Colors.grey.shade200),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 5, 10, 10),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       job.title,
//                       style: const TextStyle(
//
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF003840)),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//
//                     Text(
//                       job.location,
//                       style: const TextStyle(fontSize: 12, color: Color(0xFF003840)),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                     ),
//
//                     const SizedBox(height: 8),
//                     Container(
//                       padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: const Color(0xffEBF6F7),
//                         borderRadius: BorderRadius.circular(30),
//                         border: Border.all(color: const Color(0x40003840)),
//                       ),
//                       child: Text(
//                         job.type,
//                         style: const TextStyle(
//                             fontSize: 12, color: Color(0xFF003840)),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     // ✅ Conditional Salary/Stipend Container
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: const Color(0xffEBF6F7),
//                             borderRadius: BorderRadius.circular(30),
//                             border: Border.all(color: const Color(0x40003840)),
//                           ),
//                           child: Builder(
//                             builder: (_) {
//                               // Opportunity check
//                               if (job.opportunityType == "Full-Time") {
//                                 return Text(
//                                   "₹ ${job.salary}",
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Color(0xFF003840),
//                                   ),
//                                 );
//                               } else if ([
//                                 "Internship",
//                                 "Live Projects",
//                                 "Challenges",
//                                 "Apprenticeship",
//                               ].contains(job.opportunityType)) {
//                                 // stipend check
//                                 final stipend = job.stipendType;
//                                 if (stipend == null ||
//                                     stipend.toString().isEmpty ||
//                                     stipend.toString() == 'unpaid'||
//                                     stipend.toString() == "0") {
//                                   return const Text(
//                                     "₹ Unpaid",
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Color(0xFF003840),
//                                     ),
//                                   );
//                                 } else {
//                                   return Text(
//                                     "₹ $stipend",
//                                     style: const TextStyle(
//                                       fontSize: 12,
//                                       color: Color(0xFF003840),
//                                     ),
//                                   );
//                                 }
//                               } else {
//                                 return const Text(
//                                   "-",
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Color(0xFF003840),
//                                   ),
//                                 );
//                               }
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: const Color(0xffEBF6F7),
//                             borderRadius: BorderRadius.circular(30),
//                             border: Border.all(color: const Color(0x40003840)),
//                           ),
//                           child: Text(
//                             "${job.applicants} Applications",
//                             style: const TextStyle(fontSize: 12, color: Color(0xFF003840)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   width: 175,
//                   margin: const EdgeInsets.fromLTRB(8, 4, 8, 6),
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.info_outline_rounded,
//                           size: 16, color: Color(0xff701100)),
//                       const SizedBox(width: 6),
//                       Flexible(
//                         child: Text(
//                           'Job expires in ${job.enddate.toString()} days',
//                           style: const TextStyle(
//                               color: Color(0xff701100),
//                               fontWeight: FontWeight.bold,
//                               fontFamily: 'Inter',
//                               fontSize: 12),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Container(
//                       margin: const EdgeInsets.fromLTRB(0, 4, 0, 6),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: job.status == 'Publish'
//                             ? const Color(0xFFCAFEE3)
//                             : const Color(0xFFFCDDD7),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         job.status,
//                         style: TextStyle(
//                           color: job.status == 'Publish'
//                               ? const Color(0xff006A41)
//                               : const Color(0xffB22121),
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => BlocProvider(
//                               create: (_) =>
//                               ApplicantBloc()..add(LoadDataApplicants(job)),
//                               child: ApplicationsScreen(job: job),
//                             ),
//                           ),
//                         );
//                       },
//                       child: Container(
//                         margin: const EdgeInsets.fromLTRB(1, 4, 4, 6),
//                         padding: const EdgeInsets.all(6),
//                         decoration: const BoxDecoration(
//                           color: Color(0xff005E6A),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(Icons.arrow_forward_ios,
//                             size: 12, color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 )
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

class JobCard extends StatelessWidget {
  final JobModel job;
  const JobCard({super.key, required this.job});

  bool _has(String? s) => s != null && s.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Derived flags/values
    final hasTitle     = _has(job.title);
    final hasLocation  = _has(job.location);
    final hasType      = _has(job.type);
    final hasStatus    = _has(job.status);
    final hasApplicants= job.applicants != null; // int? or num? → presence check
    // enddate could be int(days) / String — hide if empty/zero/invalid
    final String endDaysStr = '${job.enddate ?? ''}';
    final bool hasEndDays = endDaysStr.trim().isNotEmpty && endDaysStr.trim() != '0';

    // ---- Salary/Stipend chip text (or null to hide) ----
    String? _salaryChip() {
      final opp = job.opportunityType;
      if (!_has(opp)) return null;

      if (opp == "Full-Time") {
        final sal = job.salary?.toString();
        if (_has(sal) && sal != '0') {
          return "₹ $sal";
        }
        return null;
      }

      if (["Internship", "Live Projects", "Challenges", "Apprenticeship"].contains(opp)) {
        final st = job.stipendType?.toString();
        if (!_has(st) || st == "0") return "₹ Unpaid";
        if (st!.toLowerCase() == 'unpaid') return "₹ Unpaid";
        return "₹ $st";
      }

      return null;
    }

    final String? salaryChipText = _salaryChip();

    // ---- Small chip builder (reused) ----
    Widget _chip(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xffEBF6F7),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x40003840)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF003840)),
        ),
      );
    }

    // Build dynamic chips row (salary/stipend + applicants)
    final List<Widget> metaChips = [
      if (salaryChipText != null) _chip(salaryChipText),
      if (hasApplicants) ...[
        const SizedBox(width: 8),
        _chip("${job.applicants} Applications"),
      ],
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xffe5ebeb),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 5, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle)
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003840),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    if (hasLocation)
                      Text(
                        job.location,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF003840)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),

                    if (hasType) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffEBF6F7),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0x40003840)),
                        ),
                        child: Text(
                          job.type,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF003840)),
                        ),
                      ),
                    ],

                    if (metaChips.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(children: metaChips),
                    ],
                  ],
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: expiry pill (hide if days not available)
                if (hasEndDays)
                  Container(
                    width: 175,
                    margin: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xff701100)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Job expires in $endDaysStr days',
                            style: const TextStyle(
                              color: Color(0xff701100),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(width: 175), // keep row layout stable if needed

                Row(
                  children: [
                    // Status pill (hide if missing)
                    if (hasStatus)
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 4, 0, 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: job.status == 'Publish'
                              ? const Color(0xFFCAFEE3)
                              : const Color(0xFFFCDDD7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          job.status,
                          style: TextStyle(
                            color: job.status == 'Publish'
                                ? const Color(0xff006A41)
                                : const Color(0xffB22121),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              // ❌ ..add(LoadDataApplicants(job)) hata do
                              create: (_) => ApplicantBloc(),
                              child: ApplicationsScreen(job: job),
                            ),
                          ),
                        );
                      },
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (_) => BlocProvider(
                      //         create: (_) => ApplicantBloc()..add(LoadDataApplicants(job)),
                      //         child: ApplicationsScreen(job: job),
                      //       ),
                      //     ),
                      //   );
                      // },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(1, 4, 4, 6),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xff005E6A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}


















































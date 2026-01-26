import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';
import 'package:skillsconnect/TPO/Screens/acc_screen.dart';
import 'package:skillsconnect/TPO/Screens/applicant_interview_screen.dart';
import 'package:skillsconnect/TPO/Screens/tpo_home_inner_applicants.dart';
import 'package:skillsconnect/TPO/Screens/tpo_students.dart';
import 'package:skillsconnect/TPO/Screens/tpo_contact_screen.dart';
import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
import 'package:skillsconnect/TPO/Screens/tpo_interview.dart';
import 'package:skillsconnect/TPO/Screens/tpo_notification.dart';
import 'package:skillsconnect/TPO/Screens/tpo_summary_screens.dart';
import 'package:skillsconnect/TPO/TpoHomeInnerApplicants/tpoinnerapplicants_event.dart';
import 'package:skillsconnect/TPO/TPO_Home/tpo_home_event.dart';
import 'package:skillsconnect/TPO/TPO_Home/tpo_home_state.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../HR/bloc/Login/login_bloc.dart';
import '../../HR/screens/ForceUpdate/Forcelogout.dart';
import '../../HR/screens/ForceUpdate/force_update.dart';
import '../../HR/screens/login_screen.dart';
import '../Students/students_bloc.dart' show InstituteBloc;
import '../Students/students_event.dart';
import '../My_Account/api_services.dart';
import '../TPO_Home/tpo_home_bloc.dart';
import 'dart:convert';

import '../Tpo_Contact/tpo_contact_bloc.dart';
import '../Tpo_Contact/tpo_contact_event.dart' show TpoLoadContact;

class TpoHomeScreen extends StatefulWidget {

  const TpoHomeScreen({super.key,});

  @override
  State<TpoHomeScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<TpoHomeScreen> {
  int _selectedIndex = 0;


  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0); // pehle Home par le jao
      return false; // pop mat karo
    }
    return true; // Home par ho to exit allow
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [

      const JobScreenBody(),
      BlocProvider(
        create: (_) => InstituteBloc()..add(const LoadInstitutes()),
        child: InstituteScreen(),
      ),
      InterviewDataScreen(),
      BlocProvider(
        create: (_) => TpoContactBloc()..add(TpoLoadContact(page: 1)),
        child: TpoContactScreen(),
      ),
      const AccountScreen(),
    ];

    return WillPopScope( onWillPop: _onWillPop ,child:Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        showUnselectedLabels: true,
        items: [
          _buildNavItem(assetPath: 'assets/home.png', label: 'Home', index: 0),
          _buildNavItem(assetPath: 'assets/students.png', label: 'Students', index: 1),
          _buildNavItem(assetPath: 'assets/interviews.png', label: 'Interviews', index: 2),
          _buildNavItem(assetPath: 'assets/phone.png', label: 'Calls', index: 3),
          _buildNavItem(assetPath: 'assets/account.png', label: 'Account', index: 4),
        ],
      ),
    ) );

  }

  BottomNavigationBarItem _buildNavItem({
    required String assetPath,
    required String label,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff005E6A) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              height: 24,
              width: 24,
              color: isSelected ? Colors.white : const Color(0xff005E6A),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xff005E6A),
                fontWeight: FontWeight.w500,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
      label: '',
    );
  }
}

class JobScreenBody extends StatefulWidget {
  const JobScreenBody({super.key});

  @override
  State<JobScreenBody> createState() => _JobScreenBodyState();
}

class _JobScreenBodyState extends State<JobScreenBody> {
  int _selectedTab = 0;
  bool _showDropdown = false;
  String? userImg;
  String? role;
  bool isFilterApplied = false;
  List<TpoHomeJobModel> _filteredJobs = [];
  final TextEditingController _searchController = TextEditingController();
  FilterOption? jobType, jobTitle, workCulture, jobStatus, selectCourse, jobLocation;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;




  @override
  void initState() {
    super.initState();
    context.read<TpoHomeBloc>().add(LoadTpoJobsEvent());

    Tpoprofile.refreshHeaderFromServer();
    loadUserData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        // near bottom -> ask bloc to load more
        context.read<TpoHomeBloc>().add(LoadMoreTpoJobsEvent());
      }
    });



    // Wait until first frame is rendered, then check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        checkAndForceUpdate(context);
      }
    });
  }

  Future<void> loadUserData() async {
    final data = await getUserData();
    setState(() {
      userImg = data['user_img'];
      role = data['role'];
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  // Filter Code

  final List<FiltersConfigure> filters = [
    FiltersConfigure('Job Type', 'job_type', 'job_type'),
    FiltersConfigure('Job Title', 'title', 'title'),
    FiltersConfigure('Work Culture', 'opportunity_type', 'opportunity_type'),
    FiltersConfigure('Job Status', 'job_status', 'job_status'),
    FiltersConfigure('Course', 'course', 'course'),
    FiltersConfigure('Location', 'city_name', 'city_name'),
  ];


  void _applyFilters() async {

    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}jobs'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({

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

        }),

      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobList = (data['data'] as List).map((e) => TpoHomeJobModel.fromJson(e)).toList();


        if (mounted) {
          context.read<TpoHomeBloc>().add(ApplyFilterEvent(jobList));
          setState(() {
            isFilterApplied = true;
            _filteredJobs = jobList;
          });
        }
      } else {
        print(' API Error: ${response.statusCode}');
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print(' Exception in _applyFilters: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load filtered jobs: $e")),
        );
      }
    }
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
        Uri.parse('${BASE_URL}jobs'),
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TpoCustomAppBar(),
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
              padding: const EdgeInsets.fromLTRB(15, 5, 8, 5),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (txt) {
                          _debounce?.cancel();
                          _debounce = Timer(const Duration(milliseconds: 300), () {
                            context.read<TpoHomeBloc>().add(SearchTpoJobs(txt));
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(color: Colors.green.shade50),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Container(
                  //   padding: const EdgeInsets.all(2),
                  //   decoration: BoxDecoration(
                  //     shape: BoxShape.circle,
                  //     border: Border.all(
                  //       color: Color(0x20005E6A),
                  //       width: 2,
                  //     ),
                  //   ),
                  //   child: InkWell(
                  //     onTap: () => _showFilterBottomSheet(context),
                  //     borderRadius: BorderRadius.circular(100),
                  //     child: CircleAvatar(
                  //       radius: 18,
                  //       backgroundColor: Colors.white,
                  //       child: const Icon(
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
                ? BlocBuilder<TpoHomeBloc, TpoHomeState>(
              builder: (context, state) {
                //  1. If filters are applied, use local list (_paginatedJobs)
                if (isFilterApplied) {
                  return _filteredJobs.isEmpty
                      ? const Center(child: Text('No jobs found with current filters'))
                      : ListView.builder(
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      return JobCard(job: _filteredJobs[index]);
                    },
                  );
                }

                // if (state is TPOJobLoading) {
                //   return const Center(child: CircularProgressIndicator());
                // }
                if (state is TPOJobLoading) {
                  return Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: 6, // 6 skeleton cards
                      itemBuilder: (context, index) => const JobCardSkeleton(),
                    ),
                  );
                }


                if (state is TpoJobLoaded) {
                  final jobs = state.jobs;

                  if (jobs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No jobs found',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: jobs.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < jobs.length) {
                        return JobCard(job: jobs[index]);
                      } else {
                        // end loader
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  );
                }



                if (state is TpoJobError) {
                  print("❌ DiscussionError: ${state.message}");

                  int? actualCode;

                  // 🔹 Try extracting status code (agar available ho)
                  if (state.message != null) {
                    final match = RegExp(r'\b(\d{3})\b').firstMatch(state.message!);
                    if (match != null) {
                      actualCode = int.tryParse(match.group(1)!);
                    }
                  }

                  // 🔴 401 → force logout
                  if (actualCode == 401) {
                    ForceLogout.run(
                      context,
                      message:
                      'You are currently logged in on another device. Logging in here will log you out from the other device.',
                    );
                    return const SizedBox.shrink();
                  }

                  // 🔴 403 → force logout
                  if (actualCode == 403) {
                    ForceLogout.run(
                      context,
                      message: 'Session expired.',
                    );
                    return const SizedBox.shrink();
                  }
                  final failure = ApiHttpFailure(
                    statusCode: actualCode,
                    body: state.message,
                  );
                  return OopsPage(failure: failure);
                }

                return const Center(child: CircularProgressIndicator());
              },
            )
                : const SummaryTpoScreen(),
          ),

        ],
      ),
    );
  }
}

class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

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
            // White inner card – exactly JobCard jaisa layout
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    // Yeh texts sirf layout ke liye hain, Skeletonizer inko
                    // grey shimmering bars me convert kar dega
                    Text('Job Title placeholder',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 6),
                    Text('Company Name placeholder',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 6),
                    Text('Location placeholder',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Mode • Remote',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Full-time',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('₹ 6 LPA',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('120 Applications',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom row: status + share + arrow
            Padding(
              padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Status chip
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text('Status'),
                  ),
                  SizedBox(width: 8),
                  // Share icon placeholder
                  CircleAvatar(radius: 14),
                  SizedBox(width: 8),
                  // Arrow icon placeholder
                  CircleAvatar(radius: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


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




class JobCard extends StatelessWidget {
  final TpoHomeJobModel job;
  const JobCard({super.key, required this.job});

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
            // ───────── White inner card (same style as first) ─────────
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
                    // Title
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

                    Text(
                      job.companyname,
                      style: const TextStyle(
                        fontSize: 14,
                        // fontWeight: FontWeight.bold,
                        color: Color(0xFF003840),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Location
                    Text(
                      job.location,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF003840)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 8),

                    // Mode / Jobtype chips (same pill style)
                    Row(
                      children: [
                        _pill(text: job.mode),
                        const SizedBox(width: 8),
                        _pill(text: job.jobtype),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // CTC / Applicants chips (same pill style)
                    Row(
                      children: [
                        if (job.ctc != null && job.ctc.toString().trim().isNotEmpty) ...[
                          _pill(text: '₹ ${job.ctc} LPA'),
                          const SizedBox(width: 8),
                        ],
                        _pill(text: '${job.applicants} Applications'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ───────── Bottom row (icons niche, same pattern) ─────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // left info pill


                // right actions: status + share + arrow
                Row(
                  children: [
                    // status chip (same colors as first card)
                    Container(
                      margin: const EdgeInsets.fromLTRB(8, 4, 0, 6),
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

                    // share button (icon niche lane ke liye yahin rakha)
                    InkWell(
                      onTap: () {
                        final jobLink = job.job_link;
                        Share.share('$jobLink');
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8, 4, 2, 6),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/share.png',
                          width: 14,
                          height: 14,
                          color: Color(0xff005E6A),
                        ),
                      ),
                    ),

                    // arrow button (navigate)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => TpoHomeBloc()
                                ..add(StudentLoadApplicants(job.jobId) as TpoHomeEvent),
                              child: StudentScreen(tpoHomeJobModel: job),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xff005E6A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // same pill style as first card
  Widget _pill({required String text}) {
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
}



// class JobCard extends StatelessWidget {
//   final TpoHomeJobModel job;
//   const JobCard({super.key, required this.job});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: Color(0xffe5ebeb),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(job.title,
//                       style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF003840))),
//                 ),
//                 Container(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: job.status == 'Publish'
//                         ? const Color(0xFFFCDDD7)
//                         : const Color(0xFFCAFEE3),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     job.status,
//                     style: TextStyle(
//                       color: job.status == 'Archive'
//                           ? Color(0xff006A41)
//                           : Color(0xffB22121),
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 // InkWell(
//                 //   onTap: () => showShareSheet(context),
//                 //   child: Image.asset(
//                 //     'assets/share.png',
//                 //     width: 20,
//                 //     height: 20,
//                 //     color: const Color(0xff005E6A), // optional
//                 //   ),
//                 // ),
//
//                 InkWell(
//                   onTap: () {
//                     final jobLink = 'https://forms.gle/jurSD2eqsSfPrkHg8';
//                     Share.share('Check out this job: $jobLink');
//                   },
//                   child: Image.asset(
//                     'assets/share.png',
//                     width: 20,
//                     height: 20,
//                     color: const Color(0xff005E6A),
//                   ),
//                 ),
//
//
//
//                 const SizedBox(width: 8),
//                 InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                         MaterialPageRoute(
//                         builder: (_) => BlocProvider(
//                       create: (_) => TpoHomeBloc()..add(StudentLoadApplicants(job) as TpoHomeEvent),
//                       child: StudentScreen(tpoHomeJobModel: job),
//                     ), ),
//                     );
//                   },
//                   child: Container(
//                     padding:
//                     const EdgeInsets.all(6),
//                     decoration: const BoxDecoration(
//                       color: Color(0xff005E6A),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.arrow_forward_ios,
//                       size: 14,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 2),
//             Card(
//               color: Colors.white,
//
//
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 side: BorderSide(color: Colors.grey.shade200),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Flexible(
//                           child: Text(
//                             job.location,
//                             style: const TextStyle(fontSize: 12, color: Color(0xFF003840)),
//                             overflow: TextOverflow.ellipsis,
//                             maxLines: 1,
//                           ),
//                         ),
//                         Container(
//                           height: 22,
//                           width: 22,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Color(0xFF2F7924), width: 1.5),
//                           ),
//                           child: const Center(
//                             child: Text(
//                               '01',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: Color(0xFF2F7924),
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             job.mode,
//                             style: TextStyle(color: Color(0xFF003840), fontSize: 12),
//                           ),
//                         ),
//                         Expanded(
//                           child: Text(
//                             job.jobtype,
//                             style: TextStyle(color: Color(0xFF003840), fontSize: 12),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                            '₹ ${job.ctc} LPA',
//                             style: TextStyle(color: Color(0xFF003840), fontSize: 12),
//                           ),
//                         ),
//                         Expanded(
//                           child: Text(
//                             job.applicants.toString(),
//                             style: TextStyle(color: Color(0xFF003840), fontSize: 12),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//
//                 ),
//               ),
//             ),
//             // if (job.expiryNotice.isNotEmpty)
//             //   Container(
//             //     margin: const EdgeInsets.only(top: 8),
//             //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             //     decoration: BoxDecoration(
//             //       color: Color(0xffFCDDD7),
//             //       borderRadius: BorderRadius.circular(20),
//             //     ),
//             //     child: Row(
//             //       children: [
//             //         const Icon(Icons.info_outline_rounded,
//             //             color: Color(0xff701100), size: 16),
//             //         const SizedBox(width: 6),
//             //         Expanded(
//             //           child: Text(
//             //             job.expiryNotice,
//             //             style: const TextStyle(
//             //                 color: Color(0xff701100),
//             //                 fontWeight: FontWeight.bold),
//             //           ),
//             //         ),
//             //       ],
//             //     ),
//             //   ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   //-----------------------------Share Button --------------------------------------------
//
//   void showShareSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // 🔹 Header Row
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Share link',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xff003840),
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.copy, size: 20, color: Color(0xff003840)),
//                         onPressed: () {
//                           // TODO: copy link logic
//                           Navigator.pop(context);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text("Link copied")),
//                           );
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close, size: 20, color: Color(0xff003840)),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//
//               const Divider(height: 12),
//
//               // 🔸 Share Options
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildShareIcon('assets/instagram.png', 'Instagram'),
//                     _buildShareIcon('assets/whatsapp.png', 'WhatsApp'),
//                     _buildShareIcon('assets/linkedin.png', 'LinkedIn'),
//                     _buildShareIcon('assets/twitter.png', 'X'),
//                     _buildShareIcon('assets/messages.png', 'Messages'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildShareIcon(String asset, String label) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Image.asset(asset, width: 32, height: 32),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: const TextStyle(fontSize: 10, color: Colors.black),
//         ),
//       ],
//     );
//   }
// }


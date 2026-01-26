import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skillsconnect/HR/bloc/College_invitation/college_bloc.dart';
import 'package:skillsconnect/HR/bloc/College_invitation/college_event.dart';
import 'package:skillsconnect/HR/bloc/College_invitation/college_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/HR/model/job_model.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../Calling/call_service.dart';
import '../bloc/Login/login_bloc.dart';
import 'EnterOtpScreen.dart';
import 'ForceUpdate/Forcelogout.dart';
import 'card_invitation_filter.dart';
import 'select_tpo_screen.dart';
import '../model/college_invitation_model.dart';
import 'college_inner_page.dart';
import 'package:http/http.dart' as http;

class FilterOption {
  final String name;
  final int id;

  FilterOption({required this.name, required this.id});

  factory FilterOption.fromJson(Map<String, dynamic> json, String field) {
    return FilterOption(
      name: json[field] ?? '',
      id: json['id'] ?? json['college_id'] ?? 0,
    );
  }


  @override
  String toString() => name;
}

class FilterConfig {
  final String label;
  final String filterKey;
  final String fieldName;

  FilterConfig(this.label, this.filterKey, this.fieldName);
}

class CollegeListScreen extends StatelessWidget {
  final JobModel job;

  const CollegeListScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CollegeInviteBloc(),
      child: CollegeListView(job: job),
    );
  }
}

class CollegeListView extends StatefulWidget {
  final JobModel job;
  const CollegeListView({super.key, required this.job});

  @override
  State<CollegeListView> createState() => _CollegeListViewState();
}

class _CollegeListViewState extends State<CollegeListView> {
  FilterOption? selectedCollege,
      selectedInstituteType,
      selectedState,
      selectedCity,
      selectedCourse,
      selectedSpecialization,
      selectedNAAcGrade,
      selctedCollegeStatus,
      selectedMyListName,
      selectJobId;
  bool isFilterTapped = false;
  bool isFilterActive = false;
  final ScrollController _scrollController = ScrollController();
  String selectedType = 'invitation'; // default type
  int? appliedCityId;
  int? appliedStateId;
  String? appliedCourse;
  String? appliedInstituteType;
  final String selectedstate = "";
  final String selectedcity = "";
  final String collegestatus = "";
  final String instituteType = "";
  final String course = "";
  final String naacGrade = "";
  final String myListName = " ";
  final String specialization = "";
  final String currentType = "";
  String? Hrid ;
  String? hrname ;
  String? _inviteCount; // state variable
  final Set<int> _calling = {}; // track college.id being called
  bool _tabLoading = false; // tab change par skeleton dikhane ke liye


// 🔎 common search across tabs
  final TextEditingController _searchCtrl = TextEditingController();




// state me rakho (already hoga, warna add kar lo)
  Map<String, dynamic> appliedFilters = {};

  void _refreshWithCurrentCriteria(String type) {
    final bloc = context.read<CollegeInviteBloc>();
    final q = _searchCtrl.text.trim();

    // Log
    print("🧩 Applied Filters: ${appliedFilters.isEmpty ? 'None' : appliedFilters}");

    // ✅ SEARCH + FILTERS (priority: search > filters > normal)
    if (q.isNotEmpty) {
      bloc.add(
        SearchCollegeEvent(
          query: q,
          jobId: widget.job.jobId,
          type: type,
          // ⬇️ pass ALL active filters so search runs within them
          collegeName   : (appliedFilters['college_name']        ?? '').toString(),
          instituteType : (appliedFilters['institute_type']      ?? '').toString(),
          selectedState : (appliedFilters['state_id']            ?? '').toString(),
          selectedcity  : (appliedFilters['city_id']             ?? '').toString(),
          course        : (appliedFilters['course_id']           ?? '').toString(),
          specialization: (appliedFilters['specialization_id']   ?? '').toString(),
          naacgrade     : (appliedFilters['naac_grade']          ?? '').toString(),
          mylistname    : (appliedFilters['mylist']              ?? '').toString(),
          collegestatus : (appliedFilters['collge_status']       ?? '').toString(),
        ),
      );
      return;
    }

    if (appliedFilters.isNotEmpty) {
      bloc.add(
        ApplyFilterCollegeEvent(
          jobId: widget.job.jobId,
          collegeName   : (appliedFilters['college_name']        ?? '').toString(),
          instituteType : (appliedFilters['institute_type']      ?? '').toString(),
          selectedState : (appliedFilters['state_id']            ?? '').toString(),
          selectedcity  : (appliedFilters['city_id']             ?? '').toString(),
          course        : (appliedFilters['course_id']           ?? '').toString(),
          specialization: (appliedFilters['specialization_id']   ?? '').toString(),
          naacgrade     : (appliedFilters['naac_grade']          ?? '').toString(),
          mylistname    : (appliedFilters['mylist']              ?? '').toString(),
          collegestatus : (appliedFilters['collge_status']       ?? '').toString(),
          type: type,
        ),
      );
      print("✅ Event Added: ApplyFilterCollegeEvent(filters applied)");
      return;
    }

    // normal load
    bloc.add(LoadInitialColleges(
      jobId: widget.job.jobId,
      type: type,
      page: 1,
    ));
  }

  // void _refreshWithCurrentCriteria(String type) {
  //   final bloc = context.read<CollegeInviteBloc>();
  //   final q = _searchCtrl.text.trim();
  //   print("🧩 Applied Filters: ${appliedFilters.isEmpty ? 'None' : appliedFilters}");
  //
  //   // ✅ SEARCH + FILTERS (priority: search > filters > normal)
  //   if (q.isNotEmpty) {
  //     bloc.add(
  //       SearchCollegeEvent(
  //         query: q,
  //         jobId: widget.job.jobId,
  //         // filters (optional; agar SearchCollegeEvent support karta ho)
  //         selectedState: (appliedFilters['state_id'] ?? '').toString(),
  //         selectedcity:  (appliedFilters['city_id']  ?? '').toString(),
  //         type: type, // 'invitation' | 'invited'
  //       ),
  //     );
  //     return;
  //   }
  //
  //   if (appliedFilters.isNotEmpty) {
  //     bloc.add(
  //       ApplyFilterCollegeEvent(
  //         jobId: widget.job.jobId,
  //         // 👇 external sheet ke result keys ko map kar rahe
  //         collegeName   : (appliedFilters['college_name']        ?? '').toString(),
  //         instituteType : (appliedFilters['institute_type']      ?? '').toString(),
  //         selectedState : (appliedFilters['state_id']            ?? '').toString(),
  //         selectedcity  : (appliedFilters['city_id']             ?? '').toString(),
  //         course        : (appliedFilters['course_id']         ?? '').toString(),
  //         specialization: (appliedFilters['specialization_id'] ?? '').toString(),
  //         naacgrade     : (appliedFilters['naac_grade']          ?? '').toString(),
  //         type: type,
  //       ),
  //     );
  //     print("✅ Event Added: ApplyFilterCollegeEvent(filters applied)");
  //
  //     return;
  //   }
  //
  //   // normal load
  //   bloc.add(LoadInitialColleges(
  //     jobId: widget.job.jobId,
  //     type: type,
  //     page: 1,
  //   ));
  // }


  // ⬇️  ADD THESE TWO HELPERS INSIDE THIS STATE CLASS
  bool _hasAny(Map<String, dynamic> m, List<String> keys) {
    return keys.any((k) {
      final v = m[k];
      if (v == null) return false;
      final s = v.toString().trim();
      return s.isNotEmpty && s != '0'; // 0 ko empty treat karo if needed
    });
  }

  int _filterBadgeCount(Map<String, dynamic> m) {
    int c = 0;
    if (_hasAny(m, ['college_id', 'college_name'])) c++;               // College
    if (_hasAny(m, ['institute_type'])) c++;                           // Institute Type
    if (_hasAny(m, ['state_id', 'state_name'])) c++;                   // State
    if (_hasAny(m, ['city_id', 'city_name'])) c++;                     // City
    if (_hasAny(m, ['course_id', 'course_name'])) c++;                 // Course
    if (_hasAny(m, ['specialization_id', 'specialization_name'])) c++; // Specialization
    if (_hasAny(m, ['naac_grade'])) c++;                               // NAAC
    return c;
  }


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // _loadInitialData();
    _refreshWithCurrentCriteria(selectedType); // e.g. 'invitation'
    loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }



  Future<void> loadUserData() async {
    final data = await getUserData();
    setState(() {
      Hrid  = data['id'].toString();
      hrname = data['full_name'];

    });
  }

  void _applyFilters() async {
    appliedCityId = 0;
    appliedStateId = 0;

    // if (selectedCity != null && selectedCity!.name.isNotEmpty) {
    //   appliedCityId = await _getCityIdByName(selectedCity!.name);
    // }
    //
    // if (selectedState != null && selectedState!.name.isNotEmpty) {
    //   appliedStateId = await _getStateIdByName(selectedState!.name);
    // }

    appliedCourse = selectedCourse?.name;
    appliedInstituteType = selectedInstituteType?.name;

    context.read<CollegeInviteBloc>().add(ApplyFilterCollegeEvent(
          jobId: widget.job.jobId,
          collegeName: selectedCollege?.name,
      selectedState: appliedStateId != 0 ? appliedStateId.toString() : null,
      selectedcity: appliedCityId != 0 ? appliedCityId.toString() : null,
          collegestatus: selctedCollegeStatus?.name,
          instituteType: appliedInstituteType,
          course: appliedCourse,
          naacgrade: selectedNAAcGrade?.name,
          mylistname: selectedMyListName?.name,
          specialization: selectedSpecialization?.name,
          type: selectedType,
        ));
  }

  void _loadInitialData({int page = 1}) {
    BlocProvider.of<CollegeInviteBloc>(context).add(LoadInitialColleges(
      collegeName: selectedCollege?.name ?? '',
      instituteType: appliedInstituteType ?? '',
      selectedState: appliedStateId?.toString() ?? '',
      selectedcity: appliedCityId?.toString() ?? '',
      course: appliedCourse ?? '',
      specialization: selectedSpecialization?.name ?? '',
      naacgrade: selectedNAAcGrade?.name ?? '',
      mylistname: selectedMyListName?.name ?? '',
      collegestatus: selctedCollegeStatus?.name ?? '',
      jobId: widget.job.jobId,
      type: selectedType,
      page: page,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  void _loadMoreData({int page = 1}) {
    BlocProvider.of<CollegeInviteBloc>(context).add(LoadMoreColleges(
      collegeName: selectedCollege?.name ?? '',
      instituteType: appliedInstituteType ?? '',
      selectedState: appliedStateId?.toString() ?? '',
      selectedcity: appliedCityId?.toString() ?? '',
      course: appliedCourse ?? '',
      specialization: selectedSpecialization?.name ?? '',
      naacgrade: selectedNAAcGrade?.name ?? '',
      mylistname: selectedMyListName?.name ?? '',
      collegestatus: selctedCollegeStatus?.name ?? '',
      jobId: widget.job.jobId,
      type: selectedType,
      page: page,
    ));
  }

  final List<FilterConfig> filters = [
    FilterConfig('College Name OR Id', 'college_name', 'college_name'),
    FilterConfig('Institute Type', 'institute_type', 'institute_type'),
    FilterConfig('State', 'state_name', 'state_name'),
    FilterConfig('City', 'city', 'city_name'),
    FilterConfig('Course', 'course', 'course'),
    FilterConfig('Speacialization', 'specialization', 'specialization'),
    FilterConfig('NAAC Grade', 'naac', 'naac'),

  ];

  Future<void> _showFilterBottomSheet(BuildContext parentContext) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, //  Allows full-screen height
      backgroundColor: Colors.transparent, //  Makes rounded top visible
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height, //  Full screen height
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
                  // 🔼 Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),

                  //  Filter List (scrollable)
                  Expanded(
                    child: ListView.builder(
                      itemCount: filters.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(filters[i].label,
                                  style: const TextStyle(
                                      color: Color(0xff003840))),
                              const SizedBox(height: 6),
                              DropdownSearch<FilterOption>(
                                selectedItem: [
                                  selectedCollege,
                                  selectedInstituteType,
                                  selectedState,
                                  selectedCity,
                                  selectedCourse,
                                  selectedSpecialization,
                                  selectedNAAcGrade,
                                  selectedMyListName,
                                  selctedCollegeStatus,
                                ][i],
                                asyncItems: (String filter) {
                                  if (i == 2) {
                                    // State filter
                                    return fetchStates(filter);
                                  } else if (i == 3) {
                                    // City filter
                                    return fetchCities(filter);
                                  }


                                  else {
                                    // Other filters → old API
                                    return fetchOptions(filter, filters[i], widget.job.jobId);
                                  }
                                },
                                itemAsString: (FilterOption u) => u.name,
                                onChanged: (val) => setModalState(() {
                                  switch (i) {
                                    case 0:
                                      selectedCollege = val;
                                      break;
                                    case 1:
                                      selectedInstituteType = val;
                                      break;
                                    case 2:
                                      selectedState = val;
                                      break;
                                    case 3:
                                      selectedCity = val;
                                      break;
                                    case 4:
                                      selectedCourse = val;
                                      break;
                                    case 5:
                                      selectedSpecialization = val;
                                      break;
                                    case 6:
                                      selectedNAAcGrade = val;
                                      break;
                                    case 7:
                                      selectedMyListName = val;
                                      break;
                                    case 8:
                                      selctedCollegeStatus = val;
                                      break;
                                  }
                                }),
                                popupProps: const PopupProps.menu(showSearchBox: true),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'Please Select',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    fillColor: Colors.white, // white background
                                    filled: true,
                                  ),
                                ),
                                dropdownButtonProps: const DropdownButtonProps(
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: Color(0xff003840),
                                    size: 28,
                                  ),
                                ),
                              ),

                              // DropdownSearch<FilterOption>(
                              //   selectedItem: [
                              //     selectedCollege,
                              //     selectedInstituteType,
                              //     selectedState,
                              //     selectedCity,
                              //     selectedCourse,
                              //     selectedSpecialization,
                              //     selectedNAAcGrade,
                              //     selectedMyListName,
                              //     selctedCollegeStatus,
                              //   ][i],
                              //   asyncItems: (String filter) => fetchOptions(
                              //       filter, filters[i], widget.job.jobId),
                              //   itemAsString: (u) => u.name,
                              //   onChanged: (val) => setModalState(() {
                              //     switch (i) {
                              //       case 0:
                              //         selectedCollege = val;
                              //         break;
                              //       case 1:
                              //         selectedInstituteType = val;
                              //         break;
                              //       case 2:
                              //         selectedState = val;
                              //         break;
                              //       case 3:
                              //         selectedCity = val;
                              //         break;
                              //       case 4:
                              //         selectedCourse = val;
                              //         break;
                              //       case 5:
                              //         selectedSpecialization = val;
                              //         break;
                              //       case 6:
                              //         selectedNAAcGrade = val;
                              //         break;
                              //       case 7:
                              //         selectedMyListName = val;
                              //         break;
                              //       case 8:
                              //         selctedCollegeStatus = val;
                              //         break;
                              //     }
                              //   }),
                              //   popupProps:
                              //       const PopupProps.menu(showSearchBox: true),
                              //   dropdownDecoratorProps: DropDownDecoratorProps(
                              //     dropdownSearchDecoration: InputDecoration(
                              //       labelText: 'Please Select',
                              //       border: OutlineInputBorder(
                              //           borderRadius:
                              //               BorderRadius.circular(28)),
                              //       fillColor:
                              //           Colors.white, //  set white background
                              //       filled: true, //  enable filling background
                              //     ),
                              //   ),
                              //   dropdownButtonProps: const DropdownButtonProps(
                              //     icon: Icon(
                              //       // CupertinoIcons.chevron_down,
                              //       Icons.expand_more,  // 👈 Material icon
                              //       color: Color(0xff003840),
                              //       size: 28,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🔵 Clear Button
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              // Reset dropdown selections
                              selectedCollege = null;
                              selectedCity = null;
                              selectedInstituteType = null;
                              selectedSpecialization = null;
                              selectedCourse = null;
                              selectedMyListName = null;
                              selectedNAAcGrade = null;
                              selectedState = null;
                              selctedCollegeStatus = null;

                              // Reset applied IDs & filter values
                              appliedCityId = 0;
                              appliedStateId = 0;
                              appliedCourse = null;
                              appliedInstituteType = null;
                            });

                            // Close bottom sheet and load unfiltered data
                            _loadInitialData(page: 1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003840),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Row(
                            children: [
                              Text('Clear',
                                  style: TextStyle(color: Color(0xFFFFFFFF))),
                              SizedBox(width: 6),
                              Icon(Icons.clear, color: Color(0xFFFFFFFF)),
                            ],
                          ),
                        ),

                        // 🟢 Apply Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003840),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Row(
                            children: [
                              Text('Apply',
                                  style: TextStyle(color: Colors.white)),
                              SizedBox(width: 6),
                              Icon(Icons.check_circle, color: Colors.white),
                            ],
                          ),
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

  @override
  Widget build(BuildContext context) {
    // ⬇️ current bloc state read karke pata karo ki list khaali hai ya nahi
    final blocState = context.watch<CollegeInviteBloc>().state;
    // final bool noColleges = blocState is CollegeLoaded && blocState.colleges.isEmpty;
    // final bool noColleges = blocState is CollegeLoaded
    //     && blocState.colleges.isEmpty
    //     && appliedFilters.isEmpty;

    final filterValues = [
      selectedCollege,
      selectedCity,
      selectedInstituteType,
      selectedSpecialization,
      selectedCourse,
      selectedMyListName,
      selectedNAAcGrade,
      selectedState,
      selctedCollegeStatus,
    ];


    return Scaffold(
      body: Column(
        children: [

        PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: SafeArea(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(15, 5, 8, 5),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchCtrl,
                          builder: (context, value, _) {
                            return TextField(
                              controller: _searchCtrl,
                              textInputAction: TextInputAction.search,
                              onChanged: (_) {
                                // realtime search + same filters on current tab
                                _refreshWithCurrentCriteria(selectedType);
                              },
                              onSubmitted: (_) => _refreshWithCurrentCriteria(selectedType),
                              decoration: InputDecoration(
                                hintText: 'Search',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: value.text.isNotEmpty
                                    ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _refreshWithCurrentCriteria(selectedType);
                                  },
                                )
                                    : null,
                                contentPadding:
                                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(color: Colors.green.shade50),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Expanded(
                    //   child: SizedBox(
                    //     height: 40,
                    //     child: TextField(
                    //       // enabled: !noColleges,                // ⬅️ add
                    //       // onChanged: noColleges                // ⬅️ disable callback when empty
                    //       //     ? null
                    //       //     : (query) {
                    //       //   final blocState = context.read<CollegeInviteBloc>().state;
                    //       //   String currentType = 'invitation';
                    //       //   if (blocState is CollegeLoaded) currentType = blocState.type;
                    //       //
                    //       //   context.read<CollegeInviteBloc>().add(
                    //       //     SearchCollegeEvent(
                    //       //       query: query.trim(),
                    //       //       jobId: widget.job.jobId,
                    //       //       selectedState: selectedstate,
                    //       //       selectedcity: selectedcity,
                    //       //       type: selectedType,
                    //       //     ),
                    //       //   );
                    //       // },
                    //
                    //       controller: _searchCtrl,
                    //       textInputAction: TextInputAction.search,
                    //       onChanged: (_) {
                    //         // realtime search + same filters on current tab
                    //         _refreshWithCurrentCriteria(selectedType);
                    //       },
                    //       // onChanged: (query) {
                    //       //   final blocState =
                    //       //       context.read<CollegeInviteBloc>().state;
                    //       //
                    //       //   String currentType = 'invitation';
                    //       //   if (blocState is CollegeLoaded) {
                    //       //     currentType = blocState.type;
                    //       //   }
                    //       //
                    //       //   context.read<CollegeInviteBloc>().add(
                    //       //         // SearchCollegeEvent(
                    //       //         //   query: query.trim(),
                    //       //         //   jobId: widget.job.jobId,
                    //       //         //   selectedState: appliedStateId?.toString() ?? '',
                    //       //         //   selectedcity: appliedCityId?.toString() ?? '',
                    //       //         //   collegestatus: selctedCollegeStatus?.name ?? '',
                    //       //         //   instituteType: appliedInstituteType ?? '',
                    //       //         //   course: appliedCourse ?? '',
                    //       //         //   naacgrade: selectedNAAcGrade?.name ?? '',
                    //       //         //   mylistname: selectedMyListName?.name ?? '',
                    //       //         //   specialization: selectedSpecialization?.name ?? '',
                    //       //         //   type: currentType,
                    //       //         // ),
                    //       //         SearchCollegeEvent(
                    //       //           query: query.trim(),
                    //       //           jobId: widget.job.jobId,
                    //       //           selectedState: selectedstate,
                    //       //           selectedcity: selectedcity,
                    //       //           type: selectedType,
                    //       //         ),
                    //       //       );
                    //       // },
                    //       decoration: InputDecoration(
                    //         hintText: 'Search',
                    //         prefixIcon: const Icon(Icons.search),
                    //         suffixIcon: value.text.isNotEmpty
                    //             ? IconButton(
                    //           icon: const Icon(Icons.close),
                    //           onPressed: () {
                    //             _searchCtrl.clear();
                    //             _refreshWithCurrentCriteria(selectedType);
                    //           },
                    //         )
                    //             : null,
                    //         contentPadding: const EdgeInsets.symmetric(
                    //             vertical: 0, horizontal: 16),
                    //         border: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(28),
                    //           borderSide:
                    //               BorderSide(color: Colors.green.shade50),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFilterTapped ? const Color(0xFF1A4514) : const Color(0x20005E6A),
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final res = await showCollegeFilterBottomSheet(
                            context,
                            widget.job.jobId,
                            initial: appliedFilters.isEmpty ? null : appliedFilters, // 👈 prefill
                          );
                          if (res == null) return;


                          // CLEAR case (bottom-sheet ne {'cleared': true} bheja)
                          if (res is Map && res['cleared'] == true) {
                            setState(() => appliedFilters = {});
                            _refreshWithCurrentCriteria(selectedType);
                            return;
                          }

                        // APPLY case -> res map me saare selected keys (id + name)
                          setState(() => appliedFilters = Map<String, dynamic>.from(res));
                          _refreshWithCurrentCriteria(selectedType);

                          // if (res.isEmpty) {
                          //   context.read<CollegeInviteBloc>().add(
                          //     LoadInitialColleges(jobId: widget.job.jobId, type: selectedType, page: 1),
                          //   );
                          // } else {
                          //   context.read<CollegeInviteBloc>().add(
                          //     ApplyFilterCollegeEvent(
                          //       jobId: widget.job.jobId,
                          //       collegeName   : res['college_name']?.toString() ?? '',
                          //       instituteType : res['institute_type']?.toString() ?? '',
                          //       selectedState : res['state_id']?.toString() ?? '',
                          //       selectedcity  : res['city_id']?.toString() ?? '',
                          //       course        : res['course_name']?.toString() ?? '',
                          //       specialization: res['specialization_name']?.toString() ?? '', // ✅
                          //       naacgrade     : res['naac_grade']?.toString() ?? '',
                          //       type: selectedType,
                          //     ),
                          //   );
                          // }
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isFilterActive ? const Color(0xff003840) : Colors.white,
                              child: Icon(
                                Icons.filter_list_rounded,
                                size: 20,
                                color: isFilterActive ? Colors.white : const Color(0xff003840),
                              ),
                            ),

                            // 🔴 Badge: logical count
                            if (_filterBadgeCount(appliedFilters) > 0)
                              Positioned(
                                right: -2,
                                top: -8, // UI tweak ok
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color:  Color(0xff003840),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    _filterBadgeCount(appliedFilters).toString(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // -------------------Chips Invited--------------------------------
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(
          //       18, 0, 16, 5), // ️ (left, top, right, bottom)
          //   child: Row(
          //     children: [
          //       GestureDetector(
          //         onTap: () {
          //           setState(() {
          //             selectedType = 'invitation';
          //           });
          //           context.read<CollegeInviteBloc>().add(
          //                 LoadInitialColleges(
          //                   jobId: widget.job.jobId,
          //                   type: selectedType, page: 1,
          //                   // include other filters if needed
          //                 ),
          //               );
          //         },
          //         child: Container(
          //           padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          //           decoration: BoxDecoration(
          //             color: selectedType == 'invitation'
          //                 ? Color(0xffFFEDD2)
          //                 : Color(0xffFFEDD2),
          //             borderRadius: BorderRadius.circular(30),
          //           ),
          //           child: Text(
          //             "Invite",
          //             style: TextStyle(
          //               fontSize: 12,
          //               color: Color(0xFFC64C2D),
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ),
          //       ),
          //       SizedBox(width: 10),
          //       GestureDetector(
          //         onTap: () {
          //           setState(() {
          //             selectedType = 'excluded';
          //           });
          //           context.read<CollegeInviteBloc>().add(
          //                 LoadInitialColleges(
          //                     jobId: widget.job.jobId,
          //                     type: selectedType,
          //                     page: 1),
          //               );
          //         },
          //         child: Container(
          //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //           decoration: BoxDecoration(
          //             color: selectedType == 'excluded'
          //                 ? Color(0xffFAE0E0)
          //                 : Color(0xffFAE0E0),
          //             borderRadius: BorderRadius.circular(30),
          //           ),
          //           child: Text(
          //             "Excluded",
          //             style: TextStyle(
          //               fontSize: 12,
          //               color: Color(0xFFB22121),
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ),
          //       ),
          //       SizedBox(width: 10),
          //       GestureDetector(
          //         onTap: () {
          //           setState(() {
          //             selectedType = 'invited';
          //           });
          //           context.read<CollegeInviteBloc>().add(
          //                 LoadInitialColleges(
          //                     jobId: widget.job.jobId,
          //                     type: selectedType,
          //                     page: 1),
          //               );
          //         },
          //         child: Container(
          //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //           decoration: BoxDecoration(
          //             color: selectedType == 'invited'
          //                 ? Color(0xffCAFEE3)
          //                 : Color(0xffCAFEE3),
          //             borderRadius: BorderRadius.circular(30),
          //           ),
          //           child: Text(
          //             "Invited",
          //             style: TextStyle(
          //               fontSize: 12,
          //               color: Color(0xFF006A41),
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 16, 5),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double tabWidth = constraints.maxWidth / 2; // 2 tabs now
                  final bloc = context.read<CollegeInviteBloc>();
                  final invitedText = bloc.inviteCountLabel; // e.g. "Invited 0/20"

                  int selectedIndex = 0;
                  if (selectedType == 'invited') selectedIndex = 1;

                  return Stack(
                    children: [
                      // 🔹 Sliding background indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: tabWidth * selectedIndex,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: selectedIndex == 0
                                ? const Color(0xffFFEDD2)
                                : const Color(0xffCAFEE3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      // 🔹 Tabs row — now fully tappable
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              // onTap: () {
                              //   setState(() => selectedType = 'invitation');
                              //   _refreshWithCurrentCriteria('invitation');
                              //   // context.read<CollegeInviteBloc>().add(
                              //   //   LoadInitialColleges(
                              //   //     jobId: widget.job.jobId,
                              //   //     type: selectedType,
                              //   //     page: 1,
                              //   //   ),
                              //   // );
                              // },
                              // INVITE tab

                              onTap: () {
                                setState(() {
                                  selectedType = 'invitation';
                                  _tabLoading = true;              // <-- skeleton ON
                                });
                                _refreshWithCurrentCriteria('invitation');
                              },
                              child: Center(
                                child: Text(
                                  "Invite",
                                  style: TextStyle(
                                    color: const Color(0xFFC64C2D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              // INVITED tab
                              onTap: () {
                                setState(() {
                                  selectedType = 'invited';
                                  _tabLoading = true;              // <-- skeleton ON
                                });
                                _refreshWithCurrentCriteria('invited');
                              },
                              // onTap: () {
                              //   setState(() => selectedType = 'invited');
                              //   _refreshWithCurrentCriteria('invited');
                              //   // context.read<CollegeInviteBloc>().add(
                              //   //   LoadInitialColleges(
                              //   //     jobId: widget.job.jobId,
                              //   //     type: selectedType,
                              //   //     page: 1,
                              //   //   ),
                              //   // );
                              // },
                              child: Center(
                                child: Text(
                                  invitedText,
                                  style: TextStyle(
                                    color: const Color(0xFF006A41),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),



          //  Body Content
          Expanded(
            child: BlocConsumer<CollegeInviteBloc, CollegeState>(
              listener: (context, state) {
                // jaise hi naya data aa jaye ya error aaye -> skeleton band
                if (state is CollegeLoaded || state is CollegeError) {
                  if (mounted) setState(() => _tabLoading = false);
                }
              },
              builder: (context, state) {
                // 1) Agar humne tab switch kiya hai -> force skeleton
                if (_tabLoading) {
                  return const _CollegeListSkeleton();
                }

                // 2) Pehli load ya empty-loading par bhi skeleton
                if (state is CollegeInitial ||
                    (state is CollegeLoading && state.colleges.isEmpty)) {
                  return const _CollegeListSkeleton();
                }

                if (state is CollegeError && state.colleges.isEmpty) {
                  print("❌ CollegeError: ${state.error}");

                  // 🔹 Try extracting status code from error message if available
                  int? actualCode;
                  if (state.error != null) {
                    final match = RegExp(r'\b(\d{3})\b').firstMatch(state.error!);
                    if (match != null) {
                      actualCode = int.tryParse(match.group(1)!);
                    }
                  }

                  // 🔴 NEW: 401 → force logout
                  if (actualCode == 401) {
                    ForceLogout.run(
                      context,
                      message:
                      'You are currently logged in on another device. Logging in here will log you out from the other device.',
                    );
                    return const SizedBox.shrink(); // UI placeholder while navigating
                  }

                  // 🔴 NEW: 403 → force logout
                  if (actualCode == 403) {
                    ForceLogout.run(
                      context,
                      message: 'Session expired.',
                    );
                    return const SizedBox.shrink();
                  }

                  final failure = ApiHttpFailure(
                    statusCode: null,
                    body: state.error,
                  );
                  return OopsPage(failure: failure);
                }

                // ⬇️ NEW: empty loaded state => centered text
                if (state is CollegeLoaded && state.colleges.isEmpty) {
                  return const Center(
                    child: Text(
                      "No colleges",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff003840),
                      ),
                    ),
                  );
                }


                // Get current list of colleges (empty list if state is invalid)
                final colleges = state is CollegeLoaded ? state.colleges : [];


                // Remove duplicates by college ID (or any unique identifier)
                final uniqueColleges = colleges
                    .fold<Map<int, College>>(
                  {},
                      (map, college) {
                    final id = college.id;
                    if (!map.containsKey(id)) {
                      map[id] = college;
                    }
                    return map;
                  },
                ).values
                    .toList();




                /// With Api Status //////

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                  itemCount: uniqueColleges.length +
                      ((state is CollegeLoaded && !state.hasReachedMax)
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.colleges.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final college = state.colleges[index];
                    final isCalling = _calling.contains(college.id); // ✅ Add this line



                    return Card(
                      color: Color(0xffe5ebeb),
                      // margin: EdgeInsets.symmetric(vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Color(0x33005E6A)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    college.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Color(0xff003840),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            CollegeInnerPage(
                                              collegeId: college.id,
                                              jobId: widget.job.jobId,
                                            )),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Color(0xff005E6A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.arrow_forward_ios,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        college.statename,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xff003840),
                                        ),
                                      ),

                                      // 👇 verification_status ke hisaab se icon show hoga
                                      if (college.verification_status == "Partially-verified")
                                        Image.asset(
                                          'assets/tick.png',
                                          height: 20,
                                          width: 20,
                                        )
                                      else if (college.verification_status == "Verified")
                                        Image.asset(
                                          'assets/tick.png', // ✅ green verified icon
                                          height: 20,
                                          width: 20,
                                          color: Colors.green,
                                          // color: Color(0xff003840),
                                        )
                                      else
                                        const SizedBox(), // Un-verified case: nothing
                                    ],
                                  ),

                                  // Row(
                                  //   mainAxisAlignment:
                                  //       MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     Text(college.statename,
                                  //         style: TextStyle(
                                  //             fontSize: 14,
                                  //             color: Color(0xff003840))),
                                  //     Image.asset('assets/tick.png',
                                  //         height: 20, width: 20),
                                  //   ],
                                  // ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Registration Received",
                                          style: TextStyle(
                                              color: Color(0xff003840))),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(0xffCCDFE1),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                            college.cvRecieved.toString(),
                                            style: TextStyle(
                                                color: Color(0xff003840))),
                                      ),
                                    ],
                                  ),
                                  // SizedBox(height: 10),
                                  // Row(
                                  //   mainAxisAlignment:
                                  //       MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     Text("Status",
                                  //         style: TextStyle(
                                  //             color: Color(0xff003840))),
                                  //     Container(
                                  //       padding: EdgeInsets.symmetric(
                                  //           horizontal: 10, vertical: 4),
                                  //       decoration: BoxDecoration(
                                  //         color: _getStatusBackgroundColor(
                                  //             college.status),
                                  //         borderRadius:
                                  //             BorderRadius.circular(20),
                                  //       ),
                                  //       child: Text(
                                  //         capitalizeFirstLetter(college.status),
                                  //         style: TextStyle(
                                  //           color: college.statusColor,
                                  //           fontWeight: FontWeight.w600,
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  SizedBox(height: 4),
                                  (college.minsalary != null &&
                                          college.maxsalary != null &&
                                          college.minsalary
                                              .toString()
                                              .trim()
                                              .isNotEmpty &&
                                          college.maxsalary
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("Median Salary",
                                                style: TextStyle(
                                                    color: Color(0xff003840))),
                                            Text(
                                                '${college.minsalary} - ${college.maxsalary}',
                                                style: TextStyle(
                                                    color: Color(0xff003840))),
                                          ],
                                        )
                                      : SizedBox.shrink(),
                                ],
                              ),
                            ),
                            if (college.status == "invitation") ...[
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Align(
                                    child: SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.75, // 👈 85% of screen width
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await _inviteCollege(widget.job.jobId, college.id);
                                          },

                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:  Colors.white,
                                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            side: BorderSide(color: Color(0xff005E6A)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [ Text("Invite",style:
                                            TextStyle(color: Color(0xff005E6A),
                                                fontFamily: 'Inter',fontSize: 14,fontWeight: FontWeight.bold),),
                                              SizedBox(width: 6),
                                              Icon(Icons.arrow_forward, size: 18, color: Color(0xff005E6A),),
                                            ],
                                          ) ,
                                        )

                                    ),
                                  ),
                                  // SizedBox(width: 10),
                                  // Align(
                                  //   child: SizedBox(
                                  //       width: 145,
                                  //       child: ElevatedButton(
                                  //         onPressed: () {
                                  //           // Call action
                                  //           handleCall(context, college);   // ✅ yeh call karega
                                  //
                                  //         },
                                  //         style: ElevatedButton.styleFrom(
                                  //           backgroundColor:  Color(0xff005E6A),
                                  //           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  //         ),
                                  //         child: Row(
                                  //           mainAxisAlignment: MainAxisAlignment.center,
                                  //           children: [ Text("Call",style:
                                  //           TextStyle(color: Colors.white,
                                  //               fontFamily: 'Inter',fontSize: 14,fontWeight: FontWeight.bold),),
                                  //             SizedBox(width: 6),
                                  //             Icon(Icons.arrow_forward, size: 18, color: Colors.white,),
                                  //           ],
                                  //         ) ,
                                  //       )
                                  //
                                  //   ),
                                  // ),
                                ],
                              ),
                            ]
                            else if (college.status == "invited") ...[

                              SizedBox(height: 10),
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.75,
                                  child: ElevatedButton(

                                    onPressed: isCalling ? null : () => handleCall(context, college),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff005E6A),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (!isCalling) ...[
                                          const Text(
                                            "Call",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                                        ] else ...[
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Calling…",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                )
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'invitation':
        return const Color(0xffFFEDD2); // Light Orange
      case 'excluded':
        return const Color(0xffFAE0E0); // Light Red
      case 'invited':
        return const Color(0xffCAFEE3); // Light Green
      default:
        return Colors.grey.shade200; // Default fallback
    }
  }

  /// Status First letter capital

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // filter city
  Future<int> _getCityIdByName(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse(
          '${BASE_URL}master/city/list'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "city_name": cityName,
        // "offset": "0",
        // "limit": "1"
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      if (data != null && data.isNotEmpty) {
        return data[0]['id'] ?? 0;
      }
    }

    return 0;
  }

  // filter State
  Future<List<FilterOption>> fetchStates(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('${BASE_URL}master/state/list'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "state_name": query,
      }),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data
          .map((e) => FilterOption(
        id: e['id'] ?? 0,
        name: e['state_name'] ?? '',
      ))
          .toList();
    } else {
      print("❌ State API error: ${response.statusCode}");
      return [];
    }
  }

  Future<List<FilterOption>> fetchCities(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('${BASE_URL}master/city/list'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "city_name": query,
      }),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'] ?? [];
      return data
          .map((e) => FilterOption(
        id: e['id'] ?? 0,
        name: e['city_name'] ?? '',
      ))
          .toList();
    } else {
      print("❌ City API error: ${response.statusCode}");
      return [];
    }
  }

  // Future<int> _getStateIdByName(String stateName) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('auth_token');
  //
  //   final response = await http.post(
  //     Uri.parse(
  //         'https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/master/state/list'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       if (token != null) 'Authorization': 'Bearer $token',
  //     },
  //     body: jsonEncode({
  //       "state_name": stateName,
  //     }),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body)['data'];
  //     if (data != null && data.isNotEmpty) {
  //       return data[0]['id'] ?? 0;
  //     }
  //   }
  //
  //   return 0;
  // }
  Future<void> handleCall(BuildContext context, College college) async {
    // 🧠 Only show loader for direct call (one TPO)
    if (college.tpoUsers.length == 1) {
      setState(() => _calling.add(college.id)); // show loader
      try {
        final tpo = college.tpoUsers.first;
        await CallService.startCall(
          context: context,
          callerId: Hrid.toString(),
          callerName: hrname.toString(),
          receiverId: tpo.id.toString(),
          receiverName: tpo.fullName.toString(),
        );
      } catch (e) {
        debugPrint("❌ Call error: $e");
      } finally {
        setState(() => _calling.remove(college.id)); // hide loader
      }
    }

    // 🧭 Multiple TPOs → open selection screen (no loader)
    else if (college.tpoUsers.length > 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectTpoScreen(tpoUsers: college.tpoUsers),
        ),
      );
    }

    // 🚫 No TPO
    else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("No TPO assigned for this college")),
      // );
      showSuccessSnackBar(context, "No TPO assigned for this college");

    }
  }

  // void handleCall(BuildContext context, College college) {
  //   if (college.tpoUsers.length == 1) {
  //     // ✅ Direct Call
  //     final tpo = college.tpoUsers.first;
  //     print("☎️ Starting call → HR=$Hrid → TPO=${tpo.id}");
  //
  //     CallService.startCall(
  //       // context: context,
  //       // callerId: "18209",     // HR ID
  //       // callerName: "HR John", // HR Name
  //       // receiverId: "107378",  // TPO ID
  //       // receiverName: "TPO Anita",
  //
  //
  //       context: context,
  //       callerId: Hrid.toString(),     // HR ID
  //       callerName: hrname.toString(), // HR Name
  //       receiverId: tpo.id.toString(),  // TPO ID
  //       receiverName: tpo.fullName.toString(),
  //
  //
  //     );
  //
  //     print("Tapped");
  //     print("☎️ Starting call → HR=$Hrid → TPO=${tpo.id}");
  //
  //   } else if (college.tpoUsers.length > 1) {
  //     // ✅ Open Select TPO Screen
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => SelectTpoScreen(tpoUsers: college.tpoUsers),
  //       ),
  //     );
  //   } else {
  //     // ❌ No TPO found
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("No TPO assigned for this college")),
  //     );
  //   }
  // }

  /// 🔹 Helper method for tabs

  /// 🔹 Helper method for tabs
  Widget _buildTab({
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  int _getAppliedFilterCount() {
    int count = 0;

    if (selectedCollege != null) count++;
    if (selectedInstituteType != null) count++;
    if (selectedState != null) count++;
    if (selectedCity != null) count++;
    if (selectedCourse != null) count++;
    if (selectedSpecialization != null) count++;
    if (selectedNAAcGrade != null) count++;
    if (selectedMyListName != null) count++;
    if (selctedCollegeStatus != null) count++;

    return count;
  }

  Future<void> _inviteCollege(int jobId, int collegeId) async {
    // small loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse(
        '${BASE_URL}job/dashboard/invite-college',
      );

      final body = {
        "job_id": jobId,
        "college_id": [collegeId],       // ✅ API expects a list
        "selectedType": "invite",        // ✅ per your spec
      };

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      Navigator.of(context).pop(); // close loader

      final Map<String, dynamic> m = jsonDecode(resp.body);
      final bool ok = (m['status'] == true);
      final String msg = (m['msg'] ?? '').toString();
      final String inviteCount = (m['invite_count'] ?? '').toString();
      final String detail = (m['ErrorTable'] is List && (m['ErrorTable'] as List).length > 1)
          ? ((m['ErrorTable'] as List)[1] ?? '').toString()
          : '';

      // ✅ Yahi pe update karo state me
      setState(() {
        _inviteCount = inviteCount.replaceAll("Invited ", "");
        // Sirf 2565/20000 rakhega
      });
      // quick HTML tag strip (ErrorTable has <strong> sometimes)
      final cleanDetail = detail.replaceAll(RegExp(r'<[^>]*>'), '');

      final fullMessage = [
        if (msg.isNotEmpty) msg,
        if (inviteCount.isNotEmpty) inviteCount,
        if (cleanDetail.trim().isNotEmpty) cleanDetail.trim(),
      ].join('\n');

      showSuccessSnackBar(context,fullMessage.isNotEmpty ? fullMessage : (ok ? 'Invited' : 'Failed'));
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(fullMessage.isNotEmpty ? fullMessage : (ok ? 'Invited' : 'Failed')),
      //     backgroundColor: ok ? Colors.green : Colors.red,
      //   ),
      // );

      // refresh list so card status updates (keeps current tab/filter)
      _loadInitialData(page: 1);
    } catch (e) {
      Navigator.of(context).pop(); // close loader if error
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Invite failed: $e')),
      // );
      showErrorSnackBar(context, "Invite failed" );

    }
  }
}

class _CollegeListSkeleton extends StatelessWidget {
  const _CollegeListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        itemCount: 6, // 6 fake cards
        itemBuilder: (context, index) => const _CollegeSkeletonCard(),
      ),
    );
  }
}

class _CollegeSkeletonCard extends StatelessWidget {
  const _CollegeSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffe5ebeb),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x33005E6A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Top row: college name + arrow button
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'College Name Placeholder',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xff003840),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white60,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🔹 Inner white container – same feel as real card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // State + tick
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'State Name Placeholder',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff003840),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Icon(
                        Icons.verified,
                        size: 20,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Registration Received row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Registration Received",
                        style: TextStyle(color: Color(0xff003840)),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xffCCDFE1),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            '00',
                            style: TextStyle(color: Color(0xff003840)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Median salary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Median Salary",
                        style: TextStyle(color: Color(0xff003840)),
                      ),
                      Text(
                        '₹ 0 - 0',
                        style: TextStyle(color: Color(0xff003840)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 Bottom button row (Invite / Call) – layout only
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 230,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      // side: const BorderSide(color: Color(0xff005E6A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Invite",
                          style: TextStyle(
                            color: Color(0xff005E6A),
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Color(0xff005E6A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// Suggestion List API (Dropdown ke liye)
Future<List<FilterOption>> fetchOptions(
    String query, FilterConfig config, int jobId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  // 🔹 For all other filters
  final Map<String, dynamic> body = {
    "college_name": config.filterKey == "college_name" ? query : "",
    "college_id": 0,
    "institute_type": config.filterKey == "institute_type" ? query : "",
    "state": "",
    "city": "", // leave blank here
    "course": config.filterKey == "course" ? query : "",
    "specialization": config.filterKey == "specialization" ? query : "",
    "naac_grade": config.filterKey == "naac" ? query : "",
    "mylist": config.filterKey == "mylist" ? int.tryParse(query) ?? 0 : 0,
    "collge_status": config.filterKey == "collge_status" ? query : "",
    "email_delivery_status": "",
    "invitation_before": 0,
    "job_id": jobId,
    // "limit": 100,
    // "offset": 0,
    "type": "invitation",
    "page": 1
  };

  final response = await http.post(
    Uri.parse(
        '${BASE_URL}job/dashboard/college-invite'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body)['data'] ?? [];
    return data.map((e) => FilterOption.fromJson(e, config.fieldName)).toList();
  } else {
    print(
        "API error for ${config.label}: ${response.statusCode} ${response.body}");
    return [];
  }
}



// // lib/TPO/Students/tpo_home_inner_applicants.dart  (poora working)
// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';
// import 'package:skillsconnect/TPO/Screens/tpo_inner_applicants_filter.dart';
// import 'package:skillsconnect/TPO/Screens/tpo_applicant_details_screen.dart';
// import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
// import 'package:skillsconnect/TPO/TPO_Applicant_details/applicant_deatils_bloc.dart';
// import 'package:skillsconnect/TPO/TPO_Applicant_details/applicant_deatils_event.dart';
//
// import 'package:skillsconnect/TPO/Students/tpoinnerapplicants_bloc.dart';
// import 'package:skillsconnect/TPO/Students/tpoinnerapplicants_event.dart';
// import 'package:skillsconnect/TPO/Students/tpoinnerapplicants_state.dart';
//
// import '../../Error_Handler/app_error.dart';
// import '../../Error_Handler/oops_screen.dart';
//
// class StudentScreen extends StatefulWidget {
//   final TpoHomeJobModel tpoHomeJobModel;
//   const StudentScreen({super.key, required this.tpoHomeJobModel});
//
//   @override
//   _StudentScreenState createState() => _StudentScreenState();
// }
//
// class _StudentScreenState extends State<StudentScreen> {
//   final TextEditingController _searchCtrl = TextEditingController();
//   Timer? _debounce; // 👈 add
//
//   // 👇 add these
//   late final ScrollController _scrollCtrl;
//   DateTime _lastScrollFire = DateTime.fromMillisecondsSinceEpoch(0);
//   static const _fireGap = Duration(milliseconds: 900); // same as bloc cooldown
//
//
//   //
//   // @override
//   // void dispose() {
//   //   _debounce?.cancel(); // 👈
//   //   _searchCtrl.dispose();
//   //   super.dispose();
//   // }
//
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollCtrl = ScrollController();
//     _scrollCtrl.addListener(() {
//       final bloc = context.read<StudentBloc>();
//       final st = bloc.state;
//       if (st is! StudentLoaded) return;
//
//       final nearBottom =
//           _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels <= 160;
//
//       if (nearBottom && st.hasMore && !st.isLoadingMore) {
//         // throttle to avoid bursts
//         final now = DateTime.now();
//         if (now.difference(_lastScrollFire) >= _fireGap) {
//           _lastScrollFire = now;
//           bloc.add(StudentLoadMoreEvent(widget.tpoHomeJobModel.jobId));
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchCtrl.dispose();
//     _scrollCtrl.dispose(); // 👈 add
//     super.dispose();
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     final jobId = widget.tpoHomeJobModel.jobId;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: const TpoCustomAppBar(),
//       body: BlocProvider(
//         create: (_) => StudentBloc()..add(StudentLoadApplicants(jobId, limit: 5)),
//         child: BlocBuilder<StudentBloc, StudentState>(
//           builder: (context, state) {
//
//             // -------- filter count from current state --------
//             int filterCount = 0;
//             StudentQuery? currentQuery;
//             if (state is StudentLoaded) {
//               currentQuery = state.query;
//               filterCount = [
//                 (currentQuery.collegeId ),
//                 currentQuery.processId,
//                 currentQuery.statusId,
//                 (currentQuery.stateId ),
//                 (currentQuery.cityId),
//               ].where((e) => e != null).length;
//             }
//
//             bool noStudentsAndNoFilters = false;
//             if (state is StudentLoaded) {
//               noStudentsAndNoFilters =
//                   state.student.isEmpty && filterCount == 0 && state.query.search.isEmpty;
//             }
//
//             // ------- SEARCH + FILTER ROW -------
//
//             final topBar = Padding(
//               padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: SizedBox(
//                       height: 40,
//                        child:  GestureDetector(
//                           onTap: () {
//                             if (noStudentsAndNoFilters) {
//                             Showsnackbar(context,"No Students");
//                             }
//                           },
//                           child: AbsorbPointer( // 👈 block real input
//                             absorbing: noStudentsAndNoFilters,
//                             child: TextField(
//                               controller: _searchCtrl,
//                               enabled: !noStudentsAndNoFilters, // 👈 yeh add
//                               textInputAction: TextInputAction.search,
//                               onChanged:  (text) {
//                                 context.read<StudentBloc>().add(
//                                   StudentSearchEvent(jobId, text.trim()),
//                                 );
//                               },
//                               decoration: InputDecoration(
//                                 hintText: 'Search by student or college',
//                                 prefixIcon: const Icon(Icons.search),
//                                 suffixIcon: (_searchCtrl.text.isNotEmpty)
//                                     ? IconButton(
//                                   icon: const Icon(Icons.close),
//                                   onPressed: () {
//                                     _searchCtrl.clear();
//                                     context
//                                         .read<StudentBloc>()
//                                         .add(StudentSearchEvent(jobId, ""));
//                                   },
//                                 )
//                                     : null,
//                                 contentPadding:
//                                 const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(28),
//                                   borderSide: BorderSide(color: Colors.green.shade50),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         )
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Stack(
//                     clipBehavior: Clip.none,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                             color: const Color(0x20005E6A),
//                             width: 2,
//                           ),
//                         ),
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(100),
//                           onTap: () async {
//                             if (noStudentsAndNoFilters) {
//                               // ❌ disabled hai -> snackbar
//                               Showsnackbar(context,"No Students");
//                               return;
//                             }
//                             final bloc = context.read<StudentBloc>();
//                             await showStudentFilterBottomSheet(
//                               context,
//                               jobId: jobId,
//                               initial: (state is StudentLoaded) ? state.query : null,
//                               onFiltersUpdated: (c) {},
//                             );
//                           },
//                           child: CircleAvatar(
//                             radius: 16,
//                             backgroundColor:
//                             noStudentsAndNoFilters ? Colors.grey.shade200 : Colors.white,
//                             child: Icon(
//                               Icons.filter_list_rounded,
//                               size: 20,
//                               color: noStudentsAndNoFilters
//                                   ? Colors.grey
//                                   : const Color(0xff003840),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       // 🔔 badge agar filterCount > 0 hai
//                       if (filterCount > 0)
//                         Positioned(
//                           right: -4,
//                           top: -4,
//                           child: Container(
//                             padding:
//                             const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: const Color(0xff003840),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '$filterCount',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//             if (state is StudentLoading || state is StudentInitial) {
//               return Column(
//                 children: [
//                   topBar,
//                   const Expanded(child: Center(child: CircularProgressIndicator())),
//                 ],
//               );
//             }
//
//             if (state is StudentError) {
//               print("❌ StudentError: ${state.message}");
//
//               final failure =
//               ApiHttpFailure(statusCode: null, body: state.message);
//               return Column(
//                 children: [
//                   topBar,
//                   Expanded(child: OopsPage(failure: failure)),
//                 ],
//               );
//             }
//
//             if (state is! StudentLoaded) {
//               return Column(
//                 children: [
//                   topBar,
//                   const Expanded(child: SizedBox.shrink()),
//                 ],
//               );
//             }
//
//
//
//             final students = state.student;
//
//             if (students.isEmpty) {
//               return Column(
//                 children: [
//                   topBar,
//                   const Expanded(
//                     child: Center(
//                       child: Text(
//                         'No students',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Color(0x80003840),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             }
//
//             return Column(
//               children: [
//                 topBar,
//                 Expanded(
//                   child: NotificationListener<ScrollNotification>(
//                     onNotification: (sn) {
//                       if (sn.metrics.pixels >= sn.metrics.maxScrollExtent - 120) {
//                         context.read<StudentBloc>().add(StudentLoadMoreEvent(jobId));
//                       }
//                       return false;
//                     },
//                     child: ListView.builder(
//                       itemCount: students.length,
//                       itemBuilder: (context, index) {
//                         final a = students[index];
//                         return GestureDetector(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => BlocProvider(
//                                   create: (_) => ApplicanDetailBloc()
//                                     ..add(LoadApplicant(
//                                       applicationId: a.application_id,
//                                       jobId: a.job_id,
//                                       userId: a.user_id,
//                                       applicationStatus: a.application_status,
//                                     )),
//                                   child: TpoApplicantDetailsScreen(
//                                     applicationId: a.application_id,
//                                     jobId: a.job_id,
//                                     applicationStatus: a.application_status,
//                                     userId: a.user_id,
//                                     job: widget.tpoHomeJobModel,
//                                     applicantModel: a,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Container(
//                             margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: const Color(0xffe5ebeb),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: Colors.grey.shade50),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Padding(
//                                       padding: const EdgeInsets.only(left: 10),
//                                       child: Text(
//                                         a.name,
//                                         style: const TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                     Padding(
//                                       padding: const EdgeInsets.only(right: 8),
//                                       child: Container(
//                                         padding: const EdgeInsets.all(6),
//                                         decoration: const BoxDecoration(
//                                           color: Color(0xff005E6A),
//                                           shape: BoxShape.circle,
//                                         ),
//                                         child: const Icon(
//                                           Icons.arrow_forward_ios,
//                                           size: 14,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 Card(
//                                   color: Colors.white,
//                                   shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12)),
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(12.0),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(a.university,
//                                             style: const TextStyle(
//                                                 color: Color(0xFF003840), fontSize: 14)),
//                                         const SizedBox(height: 4),
//                                         Text(a.degree,
//                                             style: const TextStyle(color: Color(0xFF003840))),
//                                         const SizedBox(height: 4),
//                                         Row(
//                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                           children: [
//                                             Text(
//                                               '${a.grade} ${a.grade_type} | ${a.year}',
//                                               style: const TextStyle(
//                                                   color: Color(0xFF003840), fontSize: 14),
//                                             ),
//                                             Chip(
//                                               label: Text(
//                                                 a.application_status,
//                                                 style: const TextStyle(
//                                                     color: Color(0xffC64C2D), fontSize: 13),
//                                               ),
//                                               backgroundColor: const Color(0xffFFEDD2),
//                                               shape: RoundedRectangleBorder(
//                                                   borderRadius: BorderRadius.circular(40)),
//                                               materialTapTargetSize:
//                                               MaterialTapTargetSize.shrinkWrap,
//                                               visualDensity: VisualDensity.compact,
//                                               padding: const EdgeInsets.symmetric(
//                                                   horizontal: 12, vertical: 6),
//                                             ),
//                                           ],
//                                         )
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   void Showsnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: TextStyle(color: Colors.white, fontSize: 14),
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10), // ✅ Rectangular with little radius
//         ),
//         duration: Duration(seconds: 2),
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//     );
//   }
//
// }
//
//
//
//
//
//

// lib/TPO/Students/tpo_home_inner_applicants.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';
import 'package:skillsconnect/TPO/Screens/tpo_inner_applicants_filter.dart';
import 'package:skillsconnect/TPO/Screens/tpo_applicant_details_screen.dart';
import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
import 'package:skillsconnect/TPO/TPO_Applicant_details/applicant_deatils_bloc.dart';
import 'package:skillsconnect/TPO/TPO_Applicant_details/applicant_deatils_event.dart';

import 'package:skillsconnect/TPO/TpoHomeInnerApplicants/tpoinnerapplicants_bloc.dart';
import 'package:skillsconnect/TPO/TpoHomeInnerApplicants/tpoinnerapplicants_event.dart';
import 'package:skillsconnect/TPO/TpoHomeInnerApplicants/tpoinnerapplicants_state.dart';

import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../HR/screens/ForceUpdate/Forcelogout.dart';

class StudentScreen extends StatefulWidget {
  final TpoHomeJobModel tpoHomeJobModel;
  const StudentScreen({super.key, required this.tpoHomeJobModel});

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // 👇 Applicant screen जैसा scroller + throttle
  late final ScrollController _scrollCtrl;

  // 👇 add this
  late final StudentBloc _bloc;

  DateTime _lastScrollFire = DateTime.fromMillisecondsSinceEpoch(0);
  static const _fireGap = Duration(milliseconds: 900); // bloc cooldown जैसा

  @override
  void initState() {
    super.initState();
    // 👇 make a single instance and fire first load here
    _bloc = StudentBloc()
      ..add(StudentLoadApplicants(widget.tpoHomeJobModel.jobId, limit: 5));

    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(() {
      final st = _bloc.state;
      if (st is! StudentLoaded) return;

      // bottom के 160px के अंदर पहुँचते ही load-more trigger
      final nearBottom =
          _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels <=
          160;

      if (nearBottom && st.hasMore && !st.isLoadingMore) {
        final now = DateTime.now();
        if (now.difference(_lastScrollFire) >= _fireGap) {
          _lastScrollFire = now;
          _bloc.add(StudentLoadMoreEvent(widget.tpoHomeJobModel.jobId));
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    appliedStudentFilters.clear(); // ✅ back press par clear
    _bloc.close(); // 👈 important
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobId = widget.tpoHomeJobModel.jobId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _JobTitleAppBar(title: widget.tpoHomeJobModel.title),
      body: BlocProvider.value(
        value: _bloc, // 👈 provide the same instance
        child: BlocBuilder<StudentBloc, StudentState>(
          builder: (context, state) {
            // -------- filter count from current state --------
            int filterCount = 0;
            StudentQuery? currentQuery;
            if (state is StudentLoaded) {
              currentQuery = state.query;
              filterCount = [
                (currentQuery.collegeId),
                currentQuery.processId,
                currentQuery.statusId,
                (currentQuery.stateId),
                (currentQuery.cityId),
              ].where((e) => e != null).length;
            }

            bool noStudentsAndNoFilters = false;
            if (state is StudentLoaded) {
              noStudentsAndNoFilters =
                  state.student.isEmpty &&
                  filterCount == 0 &&
                  state.query.search.isEmpty;
            }

            // ------- SEARCH + FILTER ROW -------
            final topBar = Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          if (noStudentsAndNoFilters) {
                            Showsnackbar(context, "No Students");
                          }
                        },
                        child: AbsorbPointer(
                          absorbing: noStudentsAndNoFilters,
                          child: TextField(
                            controller: _searchCtrl,
                            enabled: !noStudentsAndNoFilters,
                            textInputAction: TextInputAction.search,
                            onChanged: (text) {
                              context.read<StudentBloc>().add(
                                StudentSearchEvent(jobId, text.trim()),
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by student or college',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: (_searchCtrl.text.isNotEmpty)
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        context.read<StudentBloc>().add(
                                          StudentSearchEvent(jobId, ""),
                                        );
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: Colors.green.shade50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x20005E6A),
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () async {
                            if (noStudentsAndNoFilters) {
                              Showsnackbar(context, "No Students");
                              return;
                            }
                            final bloc = context.read<StudentBloc>();
                            await showStudentFilterBottomSheet(
                              context,
                              jobId: jobId,
                              initial: (state is StudentLoaded)
                                  ? state.query
                                  : null,
                              onFiltersUpdated: (c) {},
                            );
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: noStudentsAndNoFilters
                                ? Colors.grey.shade200
                                : Colors.white,
                            child: Icon(
                              Icons.filter_list_rounded,
                              size: 20,
                              color: noStudentsAndNoFilters
                                  ? Colors.grey
                                  : const Color(0xff003840),
                            ),
                          ),
                        ),
                      ),
                      if (filterCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff003840),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$filterCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );

            // ------- STATES -------
            // if (state is StudentLoading || state is StudentInitial) {
            //   return Column(
            //     children: [
            //       topBar,
            //       const Expanded(child: Center(child: CircularProgressIndicator())),
            //     ],
            //   );
            // }
            if (state is StudentLoading || state is StudentInitial) {
              return Column(
                children: [
                  topBar,
                  Expanded(child: _StudentSkeletonList()),
                ],
              );
            }

            if (state is StudentError) {
              // ignore: avoid_print
              print("❌ StudentError: ${state.message}");
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
                ForceLogout.run(context, message: 'Session expired.');
                return const SizedBox.shrink();
              }
              final failure = ApiHttpFailure(
                statusCode: actualCode,
                body: state.message,
              );
              return Column(
                children: [
                  topBar,
                  Expanded(child: OopsPage(failure: failure)),
                ],
              );
            }

            if (state is! StudentLoaded) {
              return Column(
                children: [
                  topBar,
                  const Expanded(child: SizedBox.shrink()),
                ],
              );
            }

            final loaded = state as StudentLoaded;
            final students = loaded.student;

            if (students.isEmpty) {
              return Column(
                children: [
                  topBar,
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No students',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0x80003840),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // ---------- Loaded: EXACT Applicant-style scroller ----------
            final bool hasMore = loaded.hasMore;
            final bool isLoadingMore = loaded.isLoadingMore;

            return CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // top search/filter bar
                SliverToBoxAdapter(child: topBar),

                // list items
                SliverList.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final a = students[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (_) => ApplicanDetailBloc()
                                ..add(
                                  LoadApplicant(
                                    applicationId: a.application_id,
                                    jobId: a.job_id,
                                    userId: a.user_id,
                                    applicationStatus: a.application_status,
                                  ),
                                ),
                              child: TpoApplicantDetailsScreen(
                                applicationId: a.application_id,
                                jobId: a.job_id,
                                applicationStatus: a.application_status,
                                userId: a.user_id,
                                job: widget.tpoHomeJobModel,
                                applicantModel: a,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffe5ebeb),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade50),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // header row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      trimText(
                                        toTitleCase(a.name),
                                        17,
                                      ), // 👈 yahan use hua method
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xff005E6A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((a.university ?? '').isNotEmpty)
                                      Text(
                                        trimText(a.university, 20),
                                        style: const TextStyle(
                                          color: Color(0xFF003840),
                                          fontSize: 12,
                                        ),
                                      ),

                                    if ((a.university ?? '').isNotEmpty)
                                      const SizedBox(height: 4),

                                    if ((a.degree ?? '').isNotEmpty)
                                      Text(
                                        a.degree,
                                        style: const TextStyle(
                                          color: Color(0xFF003840),
                                          fontSize: 12,
                                        ),
                                      ),

                                    if ((a.degree ?? '').isNotEmpty)
                                      const SizedBox(height: 4),

                                    if ((a.grade ?? '').isNotEmpty ||
                                        (a.year ?? '').isNotEmpty ||
                                        (a.application_status ?? '').isNotEmpty)

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if ((a.grade ?? '').isNotEmpty ||
                                              (a.year ?? '').isNotEmpty)
                                            Text(
                                              '${a.grade ?? ''} ${a.grade_type ?? ''} | ${a.year ?? ''}',
                                              style: const TextStyle(
                                                color: Color(0xFF003840),
                                                fontSize: 12,
                                              ),
                                            ),

                                          if ((a.application_status ?? '')
                                              .isNotEmpty)
                                            Chip(
                                              label: Text(
                                                a.application_status,
                                                style: TextStyle(
                                                  color: hexToColor(
                                                    a.application_status_textname,
                                                  ), // TEXT COLOR
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor: hexToColor(
                                                a.application_status_colorname,
                                              ), // BG COLOR
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 6,
                                                  ),
                                            ),

                                          // if ((a.application_status ?? '').isNotEmpty)
                                          //   Chip(
                                          //     label: Text(
                                          //       a.application_status,
                                          //       style: const TextStyle(
                                          //         color: Color(0xffC64C2D),
                                          //         fontSize: 12,
                                          //       ),
                                          //     ),
                                          //     backgroundColor: const Color(0xffFFEDD2),
                                          //     shape: RoundedRectangleBorder(
                                          //       borderRadius: BorderRadius.circular(40),
                                          //     ),
                                          //     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          //     visualDensity: VisualDensity.compact,
                                          //     padding: const EdgeInsets.symmetric(
                                          //       horizontal: 6,
                                          //       vertical: 6,
                                          //     ),
                                          //   ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // bottom loader
                if (isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // end spacer
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            );
          },
        ),
      ),
    );
  }

  void Showsnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  String trimText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text; // agar short hai to seedha text dikhaye
    } else {
      return '${text.substring(0, maxLength)}...'; // agar lamba hai to ... lagaye
    }
  }

  Color hexToColor(String code) {
    code = code.replaceAll("#", "");
    return Color(int.parse("FF$code", radix: 16));
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
}

// skeleton loader ui
class _StudentSkeletonList extends StatelessWidget {
  const _StudentSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6, // 6 fake skeleton rows
        itemBuilder: (context, index) => const _StudentSkeletonItem(),
      ),
    );
  }
}

class _StudentSkeletonItem extends StatelessWidget {
  const _StudentSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffe5ebeb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header row: IMAGE (avatar) + name + arrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: avatar + text
              Expanded(
                child: Row(
                  children: [
                    // const CircleAvatar(
                    //   radius: 18,
                    //   // real loading me Skeletonizer is circle ko
                    //   // grey shimmer bana dega = image skeleton
                    // ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Name Placeholder',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // SizedBox(height: 4),
                          // Text(
                          //   'College / University Placeholder',
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT: arrow button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(radius: 14),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 🔹 Details card skeleton (same layout jaise real card)
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // University
                  const Text(
                    'University Name Placeholder',
                    style: TextStyle(color: Color(0xFF003840), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Degree
                  const Text(
                    'Degree Placeholder',
                    style: TextStyle(color: Color(0xFF003840), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Grade + year + status chip row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'CGPA • Year Placeholder',
                          style: TextStyle(
                            color: Color(0xFF003840),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: const Text(
                          'Status',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        // backgroundColor: const Color(0xffFFEDD2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
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

class _JobTitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _JobTitleAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xffebf6f7),
      foregroundColor: const Color(0xff003840),

      centerTitle: false, // 👈 left align (gap control milta hai)
      titleSpacing: 0, // 👈 leading aur title ke beech ka default 16px hatao
      leadingWidth: 60, // 👈 default ~56 hota hai, isse aur kam ho jayega

      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        onPressed: () => Navigator.of(context).maybePop(),
      ),

      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xff003840),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
import 'package:skillsconnect/TPO/Screens/tpo_inner_institute_detailspage.dart';
import 'package:skillsconnect/TPO/Screens/tpo_students_filter.dart';

import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../HR/screens/ForceUpdate/Forcelogout.dart';
import '../Students/students_bloc.dart';
import '../Students/students_event.dart';
import '../Students/students_state.dart';
import '../Model/c_model.dart';
import '../TPO_Applicant_details/applicant_deatils_bloc.dart';
import '../TPO_Applicant_details/applicant_deatils_event.dart';

class InstituteScreen extends StatefulWidget {
  const InstituteScreen({super.key});

  @override
  State<InstituteScreen> createState() => _InstituteScreenState();
}

class _InstituteScreenState extends State<InstituteScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _query = '';
  // local paging tracker (UI side)
  int _page = 1;
  final int _limit = 5;

  // 🔹 ACTIVE FILTERS (college, course, year, status)
  InstituteFilter _activeFilter = const InstituteFilter();

  int get _filterCount => _activeFilter.activeCount;
  bool get _hasFilters => _activeFilter.hasAny;

  @override
  void initState() {
    super.initState();

    // First load (page 0)
    context.read<InstituteBloc>().add(const FetchInstitutes(page: 1, limit: 5));

    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final st = context.read<InstituteBloc>().state;
    if (st is! InstituteLoaded) return;

    final position = _scrollCtrl.position;

    if (st.hasMore &&
        !st.isFetchingMore &&
        position.hasPixels &&
        position.atEdge &&
        position.pixels > 0) {
      _page += 1;

      final q = _searchCtrl.text.trim(); // 👈 current search term
      final f = _activeFilter;

      context.read<InstituteBloc>().add(
        FetchInstitutes(
          page: _page,
          limit: _limit,
          studentName: q, // 🔑 keep server-side filter on pagination too
          collegeName: f.collegeId?.toString() ?? '',
          courseId: f.courseId?.toString() ?? '',
          passoutYear: f.passoutYear ?? '',
          status: f.status ?? '',
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F8),
      appBar: TpoCustomAppBar(),
      body: Column(
        children: [
          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        final q = v.trim();

                        // UI side local state
                        setState(() => _query = q.toLowerCase());
                        _page = 1; // scroll paging reset

                        // current active filters
                        final f = _activeFilter;
                        final finalStudentName =
                        (f.studentName != null && f.studentName!.isNotEmpty && q.isNotEmpty)
                            ? "${f.studentName} $q"     // ✅ combine both
                            : (q.isNotEmpty ? q : (f.studentName ?? ''));

                        // 🔥 ab search bhi filters ke saath hi jayega
                        context.read<InstituteBloc>().add(
                          ResetInstitutes(
                            collegeName: f.collegeId?.toString() ?? '',
                            courseId:    f.courseId?.toString() ?? '',
                            passoutYear: f.passoutYear ?? '',
                            studentName: finalStudentName ?? '',                // 👈 search text
                            status:      f.status ?? '',
                          ),
                        );
                      },

                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        // 👇 NEW: clear (X) button
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            // text clear
                            _searchCtrl.clear();
                            setState(() => _query = '');
                            _page = 1;

                            // current active filters
                            final f = _activeFilter;

                            // 🔁 search hatao, filters same rakho
                            context.read<InstituteBloc>().add(
                              ResetInstitutes(
                                collegeName: f.collegeId?.toString() ?? '',
                                courseId:    f.courseId?.toString() ?? '',
                                passoutYear: f.passoutYear ?? '',
                                studentName: '',              // 👈 search empty
                                status:      f.status ?? '',
                              ),
                            );

                            // optional: list ko top pe le jao
                            _scrollCtrl.jumpTo(0);
                          },
                        ),

                        // suffixIcon: _searchCtrl.text.isEmpty
                        //     ? null
                        //     : IconButton(
                        //         icon: const Icon(Icons.close),
                        //         onPressed: () {
                        //           // text clear
                        //           _searchCtrl.clear();
                        //           setState(() => _query = '');
                        //           _page = 1;
                        //
                        //           // list ko full reset/search-clear karao
                        //           context.read<InstituteBloc>().add(
                        //             const InstituteSearchEvent(search: ''),
                        //           );
                        //
                        //           // optional: list top pe le jana ho to
                        //           // _scrollCtrl.jumpTo(0);
                        //         },
                        //       ),

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.green.shade50),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 🔽 FILTER BUTTON
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
                          // bottom sheet open karo
                          final result = await showInstituteFilterBottomSheet(
                            context,
                            initial: _activeFilter,
                          );

                          if (result != null) {
                            setState(() {
                              _activeFilter = result;
                            });

                            _page = 1;
                            final search = _searchCtrl.text.trim();

                            context.read<InstituteBloc>().add(
                              ResetInstitutes(
                                collegeName: result.collegeId?.toString() ?? '',
                                courseId: result.courseId?.toString() ?? '',
                                passoutYear: result.passoutYear ?? '',
                                studentName: result.studentName ?? '',   // 👈 IMPORTANT
                                status: result.status ?? '',
                              ),
                            );

                            _scrollCtrl.jumpTo(0);
                          }
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: Color(0xff003840),
                          ),
                        ),
                      ),
                    ),
                    if (_filterCount > 0)
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
                            '$_filterCount',
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
          ),

          Expanded(
            child: BlocBuilder<InstituteBloc, InstituteState>(
              builder: (context, state) {
                // if (state is InstituteLoading || state is InstituteInitial) {
                //   return const Center(child: CircularProgressIndicator());
                // }
                if (state is InstituteLoading || state is InstituteInitial) {
                  return Skeletonizer(
                    enabled: true,
                    child: ListView.separated(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: 6, // 6 fake skeleton cards
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          const _InstituteCardSkeleton(),
                    ),
                  );
                }

                if (state is InstituteError) {
                  print("❌ InstituteError occurred: ${state.message}");

                  int? actualCode;

                  // 🔹 Try extracting status code (agar available ho)
                  if (state.message != null) {
                    final match = RegExp(
                      r'\b(\d{3})\b',
                    ).firstMatch(state.message!);
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
                    statusCode: null,
                    body: state.message,
                  );
                  return OopsPage(failure: failure);
                }

                if (state is InstituteLoaded) {
                  final all = state.institutes;

                  if (all.isEmpty) {
                    return const Center(
                      child: Text(
                        'No data',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0x80003840),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // ✅ just use server-provided page as-is
                  final list = all;

                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'No data',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0x80003840),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  final itemCount =
                      list.length +
                      ((state.hasMore && state.isFetchingMore) ? 1 : 0);
                  return ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      // bottom loader row
                      final isLoaderRow =
                          (state.hasMore &&
                          state.isFetchingMore &&
                          i == itemCount - 1);
                      if (isLoaderRow) {
                        return _buildBottomLoader();
                      }

                      final s = list[i];
                      return _InstituteCard(s: s);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _InstituteCardSkeleton extends StatelessWidget {
  const _InstituteCardSkeleton({super.key});

  String _truncate(String v, {int max = 26}) {
    if (v.length <= max) return v;
    return '${v.substring(0, max - 2)}..';
  }

  @override
  Widget build(BuildContext context) {
    // Skeletonizer in sab Text / CircleAvatar / Container ko
    // grey shimmering skeleton me convert kar dega
    return Card(
      color: const Color(0xffEAF4F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffEBF6F7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW: (yahan ek chhota logo/DP feel de dete hain)
            Row(
              children: [
                // fake logo / image skeleton
                // const CircleAvatar(
                //   radius: 18,
                //   // Skeletonizer isko circle skeleton bana dega
                // ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _truncate('Institute Name Placeholder'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xff003840),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CircleAvatar(radius: 14),

                // Padding(
                //   padding: const EdgeInsets.only(right: 8),
                //   child: Container(
                //     padding: const EdgeInsets.all(6),
                //     decoration: const BoxDecoration(
                //       color: Colors.white,
                //       shape: BoxShape.circle,
                //     ),
                //     child: const Icon(
                //       Icons.arrow_forward_ios,
                //       size: 14,
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
              ],
            ),

            const SizedBox(height: 6),

            // WHITE CARD – same structure jaise original _InstituteCard
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 150, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'College Name Placeholder',
                    style: TextStyle(color: Color(0xff003840), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Course Name Placeholder',
                    style: TextStyle(color: Color(0xff003840), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Marks • Grade • Year Placeholder',
                    style: TextStyle(color: Color(0xff003840), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstituteCard extends StatelessWidget {
  const _InstituteCard({required this.s});
  final InstituteModel s;

  String _truncate(String v, {int max = 26}) {
    if (v.length <= max) return v;
    return '${v.substring(0, max - 2)}..';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffEAF4F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xffEBF6F7)),
      ),

      // ⬇️ yahan se: Padding ko InkWell se wrap kiya
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          int _toInt(dynamic v) => (v is int) ? v : int.tryParse('$v') ?? 0;

          final int applicationId = _toInt(s.id ?? s.id);
          final int userId = _toInt(s.userId ?? s.id);

          if (applicationId == 0 || userId == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Missing user/application id')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (_) => ApplicanDetailBloc()
                  ..add(
                    LoadApplicant(
                      applicationId: applicationId,
                      jobId: 0,
                      userId: userId,
                      applicationStatus: "",
                    ),
                  ),
                child: TpoInnerInstituteDetailspage(
                  applicationId: applicationId,
                  userId: userId,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(width: 4,),
                  Expanded(
                    child: Text(
                      // _truncate(
                      //   s.fullName.isNotEmpty
                      //       ? s.fullName
                      //       : '${s.firstName} ${s.lastName}'.trim(),
                      // ),
                      _truncate(
                        toTitleCase(
                          s.fullName.isNotEmpty
                              ? s.fullName
                              : '${s.firstName} ${s.lastName}'.trim(),
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xff003840),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // IDs pick karna (defensive cast)
                        int _toInt(dynamic v) =>
                            (v is int) ? v : int.tryParse('$v') ?? 0;

                        final int applicationId = _toInt(
                          // try common field names; apne InstituteModel ke exact fields yahan set kar do
                          s.id ?? s.id,
                        );
                        final int userId = _toInt(s.userId ?? s.id);

                        if (applicationId == 0 || userId == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Missing user/application id'),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (_) => ApplicanDetailBloc()
                                ..add(
                                  LoadApplicant(
                                    applicationId: applicationId,
                                    jobId: 0,
                                    userId: userId,
                                    applicationStatus: "",
                                  ),
                                ),
                              child: TpoInnerInstituteDetailspage(
                                applicationId: applicationId,
                                userId: userId,
                              ),
                            ),
                          ),
                        );
                      },
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
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.collegeName,
                      style: const TextStyle(
                        color: Color(0xff003840),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.courseName,
                      style: const TextStyle(
                        color: Color(0xff003840),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${s.marks} ${s.grade_type}          ${s.passing_year}',
                          style: const TextStyle(
                            color: Color(0xff003840),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

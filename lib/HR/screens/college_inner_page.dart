import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skillsconnect/HR/screens/notification_screen.dart';

import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../bloc/College_Inner_Page/c_inner_bloc.dart';
import '../bloc/College_Inner_Page/c_inner_event.dart';
import '../bloc/College_Inner_Page/c_inner_state.dart';
import '../model/c_innerpage_model.dart';
import 'ForceUpdate/Forcelogout.dart';

class CollegeInnerPage extends StatefulWidget {
  final int collegeId;
  final int jobId;

  const CollegeInnerPage({
    super.key,
    required this.collegeId,
    required this.jobId,
  });

  @override
  State<CollegeInnerPage> createState() => _CollegeInnerPageState();
}

class _CollegeInnerPageState extends State<CollegeInnerPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CollegeBloc()
        ..add(
          FetchCollegeDetails(collegeId: widget.collegeId, jobId: widget.jobId),
        ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xffEBF6F7),
          title: const Text(
            'College Inner Page',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: false, // 👈 ye line
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_sharp, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ), // 👈 jitna chahe adjust karo
              child: IconButton(
                icon: Image.asset(
                  'assets/notification.png',
                  height: 38,
                  width: 38,
                  fit: BoxFit.cover,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: BlocBuilder<CollegeBloc, CollegeState>(
          builder: (context, state) {
            if (state is CollegeLoading) {
              return const _CollegeInnerSkeleton();
            } else if (state is CollegeLoaded) {
              return _buildContent(state.college, state.courses);
            } else if (state is CollegeError) {
              print("❌ CollegeError: ${state.error}");

              int? actualCode;
              if (state.error != null) {
                final match = RegExp(r'\b(\d{3})\b').firstMatch(state.error!);
                if (match != null) {
                  actualCode = int.tryParse(match.group(1)!);
                }
              }

              if (actualCode == 401) {
                ForceLogout.run(
                  context,
                  message:
                      'You are currently logged in on another device. Logging in here will log you out from the other device.',
                );
                return const SizedBox.shrink();
              }

              if (actualCode == 403) {
                ForceLogout.run(context, message: 'Session expired.');
                return const SizedBox.shrink();
              }

              final failure = ApiHttpFailure(
                statusCode: actualCode,
                body: state.error,
              );
              return OopsPage(failure: failure);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  // ====== Reusable card (design unchanged), with optional trailing button ======
  Widget _buildCard(String title, List<Widget> children, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xff003840),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffEBF6F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildContent(CollegeInfo college, List<CourseInfo> courses) {
    final first = courses.isNotEmpty ? courses.first : null;
    final rest = courses.length > 1 ? courses.sublist(1) : const <CourseInfo>[];

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6), // 👈 adjust karo
                  child: Image.asset('assets/bank.png', height: 40, width: 40),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        college.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff003840),
                          fontFamily: "Inter",
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              college.address,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Inter",
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (college.verification_status ==
                              "Partially-verified")
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
                            )
                          else
                            const SizedBox(), // Un-verified case: nothing
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0x3080AFB4), thickness: 2),

          // // header
          // ListTile(
          //   leading: Image.asset('assets/bank.png', height: 34, width: 34),
          //   title: Text(
          //     college.name,
          //     maxLines: 2, // 👈 max 2 lines
          //     overflow: TextOverflow.ellipsis, // 👈 3rd line cut with "..."
          //     style: const TextStyle(
          //       fontSize: 18,
          //       fontWeight: FontWeight.bold,
          //       color: Color(0xff003840),
          //       fontFamily: "Inter",
          //     ),
          //   ),
          //   subtitle: Text(
          //     college.address,
          //     maxLines: 3, // 👈 max 2 lines
          //     overflow: TextOverflow.ellipsis, // 👈 ellipsis apply
          //     style: TextStyle(
          //       fontSize: 14,
          //       fontFamily: "Inter",
          //       color: Colors.grey.shade500,
          //       fontWeight: FontWeight.w700,
          //     ),
          //   ),
          // ),
          //
          // const Divider(color: Color(0x3080AFB4), thickness: 2),

          // --- College Info ---
          _maybeCard(
            'College Info',
            [
              _maybeInfoRow(
                'assets/institute.png',
                'Institute Type',
                college.instituteType,
              ),
              _maybeInfoRow(
                'assets/bag.png',
                'NAACs Grades',
                college.naacGrade,
              ),
              _maybeInfoRow(
                'assets/year.png',
                'Year of establishment',
                college.establishmentYear,
              ),
              _maybeInfoRow(
                'assets/person.png',
                'Ownership',
                college.ownership,
              ),
              _maybeInfoRow('assets/location.png', 'Address', college.address),
            ].whereType<Widget>().toList(),
          ),

          // --- College Details (only if course exists) ---
          if (first != null)
            _maybeCard(
              'College Details',
              [..._courseBlock(first)],
              trailing: (courses.length > 1)
                  ? TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xffEBF6F7), // text color
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllCoursesPage(
                              courses: courses, // 👈 pura list bhejo
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Show more',
                        style: TextStyle(
                          color: Color(0xff003840),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),

          // --- Contact Person ---
          _maybeCard('College Contact Person', [
            ?_maybeInfoRow(
              'assets/person.png',
              'Name',
              college.contactNamesJoined.isNotEmpty
                  ? college.contactNamesJoined
                  : '-', // agar empty ho to fallback
            ),
            _infoRow(
              'assets/prof.png',
              'Position',
              college.roleName,
            ), // 👈 static
          ]),

          // _maybeCard('College Contact Person', [
          //   _maybeInfoRow('assets/person.png', 'Name', college.contactNamesJoined),
          //   // _maybeInfoRow('assets/mail.png', 'Email', college.email),
          //   // _maybeInfoRow('assets/mobile.png', 'Phone Number', college.mobile),
          //   _infoRow('assets/prof.png', 'Position', "College TPO"), // 👈 static allowed
          // ].whereType<Widget>().toList()),
          const SizedBox(height: 20),
        ].whereType<Widget>().toList(), // 👈 skip nulls
      ),
    );
  }

  Widget _infoRow(String iconPath, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            iconPath,
            width: 16,
            height: 16,
            color: const Color(0xff003840),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xff003840),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff003840),
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _maybeInfoRow(String iconPath, String label, String? value) {
    if (value == null || value.trim().isEmpty) return null; // 👈 skip empty
    return _infoRow(iconPath, label, value);
  }

  Widget? _maybeCard(String title, List<Widget> children, {Widget? trailing}) {
    if (children.isEmpty) return null; // 👈 agar koi row hi nahi hai
    return _buildCard(title, children, trailing: trailing);
  }

  // Single course block (3–4 lines like before)
  List<Widget> _courseBlock(CourseInfo c) {
    return [
      _infoRow('assets/institute.png', 'Course Name', c.courseName),
      _infoRow('assets/bag.png', 'Specialization', c.specialization),
      _infoRow(
        'assets/salary.png',
        'Median Salary (In LPA)',
        c.minPackage.isEmpty ? '-/-' : c.minPackage,
      ),
      _infoRow('assets/seats.png', 'Seats Offered', c.seatOffered),
    ];
  }
}

class _CollegeInnerSkeleton extends StatelessWidget {
  const _CollegeInnerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Top header – college name + address + tick
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Image.asset(
                      'assets/bank.png',
                      height: 40,
                      width: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'College Name Placeholder',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff003840),
                            fontFamily: "Inter",
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Address line 1, City, State, Country',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Inter",
                            color: Colors.grey,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0x3080AFB4), thickness: 2),

            // 🔹 College Info card
            _SkeletonSectionCard(
              title: 'College Info',
              rows: const [
                _SkeletonRow(label: 'Institute Type'),
                _SkeletonRow(label: 'NAACs Grades'),
                _SkeletonRow(label: 'Year of establishment'),
                _SkeletonRow(label: 'Ownership'),
                _SkeletonRow(label: 'Address'),
              ],
            ),

            // 🔹 College Details card
            _SkeletonSectionCard(
              title: 'College Details',
              rows: const [
                _SkeletonRow(label: 'Course Name'),
                _SkeletonRow(label: 'Specialization'),
                _SkeletonRow(label: 'Median Salary (In LPA)'),
                _SkeletonRow(label: 'Seats Offered'),
              ],
            ),

            // 🔹 Contact Person card
            _SkeletonSectionCard(
              title: 'College Contact Person',
              rows: const [
                _SkeletonRow(label: 'Name'),
                _SkeletonRow(label: 'Position'),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SkeletonSectionCard extends StatelessWidget {
  final String title;
  final List<_SkeletonRow> rows;

  const _SkeletonSectionCard({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xff003840),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffEBF6F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final String label;

  const _SkeletonRow({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left icon placeholder
          CircleAvatar(radius: 14),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xff003840),
            ),
          ),
          const SizedBox(width: 40),
          const Expanded(
            flex: 3,
            child: Text(
              'Value Placeholder',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xff003840),
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Course Details Card

class AllCoursesPage extends StatelessWidget {
  final List<CourseInfo> courses;

  const AllCoursesPage({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffEBF6F7),
        title: const Text('All Courses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_sharp, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, i) {
          final c = courses[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffEBF6F7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('assets/institute.png', 'Course Name', c.courseName),
                _infoRow('assets/bag.png', 'Specialization', c.specialization),
                _infoRow(
                  'assets/salary.png',
                  'Median Salary (In LPA)',
                  c.minPackage.isEmpty ? '—' : c.minPackage,
                ),
                _infoRow(
                  'assets/seats.png',
                  'Seats Offered',
                  c.seatOffered.toString(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String iconPath, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            iconPath,
            width: 16,
            height: 16,
            color: const Color(0xff003840),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xff003840),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff003840),
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

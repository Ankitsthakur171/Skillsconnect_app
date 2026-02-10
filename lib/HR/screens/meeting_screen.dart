import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/HR/bloc/Applicant_details/applicant_deatils_bloc.dart';
import 'package:skillsconnect/HR/bloc/Applicant_details/applicant_deatils_event.dart';
import 'package:skillsconnect/HR/screens/EnterOtpScreen.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../bloc/InterView_bottom/inetrview_state.dart';
import '../bloc/InterView_bottom/interview_bloc.dart';
import '../bloc/InterView_bottom/interview_event.dart';

import '../model/interview_bottom.dart';
import 'ForceUpdate/Forcelogout.dart';
import 'interview_stu_details.dart';

class MeetingScreen extends StatefulWidget {
  final ScheduledMeeting meeting;

  const MeetingScreen({super.key, required this.meeting});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  bool _showDetails = true;
  final GlobalKey _key = GlobalKey();
  int selectedIndex = 0;
  String companyName = '';
  String companyLogo = '';
  final GlobalKey _popupKey = GlobalKey();
  late String _selectedStatus;
  // _MeetingScreenState ke andar (class level par)
  final Map<int, String> _statusByAppId = {}; // key = attendee.applicationId
  bool _isMenuOpen = false; // 👈 state variable banao
  int? _openMenuAppId; // जो row खुला है उसका appId, नहीं तो null
  // 🔎 NEW: search ke liye
  final TextEditingController _searchCtl = TextEditingController();
  String _q = '';
  final Set<String> _selectedAttendees =
      {}; // attendee.applicationId ya unique id
// ✅ Local list so UI can refresh immediately after delete
  late List<Attendee> _attendees;

// ✅ delete click pe kaun-sa row delete ho raha hai, remember
  int? _pendingDeleteUserId;
  int? _pendingDeleteAppId;

  final List<String> _statusOptions = [
    // 'Applied',
    'Cv Shortlist',
    'HR Reject',
    // 'Candidate Declined',
    // 'Round Shortlisted',
    // 'Hold/Follow up',
    'Final Selected',
    // 'Hired',
  ];

  @override
  void initState() {
    super.initState();
    loadCompanyName();
    // _selectedStatus = widget.meeting.allAttendees.ap;
    _attendees = widget.meeting.allAttendees; // ✅ Initialize local list
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Applied':
        return const Color(0xffE4D7F5);
      case 'Cv Shortlist':
        return const Color(0xffFCE7C1);
      case 'HR Reject':
        return const Color(0xffFAD5D1);
      case 'Candidate Declined':
        return const Color(0xffF7CFC5);
      case 'Round Shortlisted':
        return const Color(0xffFFD980);
      case 'Hold/Follow up':
        return const Color(0xffFFF3A3);
      case 'Final Selected':
        return const Color(0xff199C3E);
      case 'Hired':
        return const Color(0xffD8F4B3);
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Applied':
        return Colors.deepPurple;
      case 'Cv Shortlist':
        return Colors.brown;
      case 'HR Reject':
        return Colors.redAccent;
      case 'Candidate Declined':
        return Colors.brown.shade700;
      case 'Round Shortlisted':
        return Colors.deepOrange;
      case 'Hold/Follow up':
        return Colors.orange;
      case 'Final Selected':
        return Colors.white;
      case 'Hired':
        return const Color(0xff005E38);
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;

    // final attendees = meeting.students;
    final attendees = _attendees;

// ✅ Counts will auto-update when attendee list changes
    final liveCount = attendees.where((a) => a.isAttended == "Yes").length;
    final totalCount = attendees.length;


// 🔎 NEW: name ya college par filter (case-insensitive)
    final filtered = (_q.isEmpty)
        ? attendees
        : attendees.where((a) {
      final name = (a.fullName ?? '').toLowerCase();
      final college = (a.collegeName ?? '').toLowerCase();
      return name.contains(_q) || college.contains(_q);
    }).toList();


    return BlocConsumer<DiscussionBloc, DiscussionState>(
      listener: (context, state) {
        if (state is MeetingDeleted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(state.message),
          //     backgroundColor: Colors.green,
          //   ),
          // );
          showSuccessSnackBar(context, state.message);
          Navigator.of(context).pop();
        }

        if (state is AttendeeDeleted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(state.message),
          //     backgroundColor: Colors.green,
          //   ),
          // );
          showSuccessSnackBar(context, state.message);
          // ✅ UI turant refresh: remove the deleted attendee from local list
          setState(() {
            if (_pendingDeleteUserId != null) {
              _attendees.removeWhere((a) => a.userId == _pendingDeleteUserId);
            } else if (_pendingDeleteAppId != null) {
              _attendees.removeWhere((a) => a.applicantApplicationId == _pendingDeleteAppId);
            }

            if (_pendingDeleteAppId != null) {
              _selectedAttendees.remove(_pendingDeleteAppId.toString());
            }

            _pendingDeleteUserId = null;
            _pendingDeleteAppId = null;
            _openMenuAppId = null;
          });
        }

        if (state is DiscussionError) {
          // ❌ Yahan return mat karo
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          // );
          showErrorSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is DiscussionError) {
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
          final failure = ApiHttpFailure(statusCode: actualCode, body: state.message);
          // ✅ Yahan UI return karna sahi jagah hai
          return OopsPage(failure: failure);
        }
        return Scaffold(
          backgroundColor: const Color(0xffffffff),
          body: SafeArea(
            child: Column(
              children: [
                /// ----- Header -----
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  color: const Color(0xffebf6f7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: companyLogo.isNotEmpty
                                ? NetworkImage(companyLogo)
                                : const AssetImage('assets/building.png')
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${meeting.interviewName} | ${meeting.jobTitle}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Image(
                                      image: AssetImage('assets/building.png'),
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      getShortCompanyName(companyName),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Image(
                                      image: AssetImage(
                                        meeting.platform == "manual"
                                            ? "assets/meeting.png"
                                            : meeting.platform == "zoom"
                                            ? "assets/join.png"
                                            : meeting.platform == "google-meet"
                                            ? "assets/gmeet.png"
                                            : meeting.platform == ""
                                            ? "assets/manual.png"
                                            : "assets/join.png", // 👈 default
                                      ),
                                      height: 18,
                                      width: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${liveCount} / ${totalCount}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 5, 5, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff003840),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showDetails = !_showDetails;
                                });
                              },
                              child: _showDetails
                                  ? Image.asset(
                                      'assets/arrow_down.png',
                                      width: 18,
                                      height: 18,
                                    )
                                  : Image.asset(
                                      'assets/arrow_up.png',
                                      width: 18,
                                      height: 18,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              detailRow(
                                'assets/calender.png',
                                meeting.formattedInterviewDate,
                              ),
                              const SizedBox(height: 8),
                              detailRow(
                                'assets/alarm.png',
                                "${meeting.formattedStartTime} to ${meeting.formattedEndTime}",
                              ),
                              const SizedBox(height: 8),
                              // detailRow('assets/person.png', meeting.moderator ?? "HR Manager"),
                              Row(
                                children: [
                                  const Image(
                                    image: AssetImage('assets/person.png'),
                                    width: 16,
                                    height: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "HR Manager",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xff003840),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      meeting.moderators.first.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xff003840),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (meeting.moderatoremail != null &&
                                  meeting.moderatoremail!.trim().isNotEmpty)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // line height fix
                                  children: [
                                    const Image(
                                      image: AssetImage('assets/mail.png'),
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "Moderator",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xff003840),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        meeting.moderatoremail!,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xff003840),
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        crossFadeState: _showDetails
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),

                /// ----- Search Bar + More Menu -----
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 8, 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: TextField(
                            controller: _searchCtl,                 // 🔎 NEW
                            onChanged: (v) => setState(() {         // 🔎 NEW
                              _q = v.trim().toLowerCase();
                            }),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              prefixIcon: const Icon(Icons.search),
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
                      const SizedBox(width: 10),
                      Container(
                        key: _key,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x20005E6A),
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _showCustomMenu(context, meeting.id),
                          borderRadius: BorderRadius.circular(100),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.more_vert_outlined,
                              size: 20,
                              color: Color(0xff003840),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// ----- Attendees -----
                Expanded(
                  child: (_q.isNotEmpty && filtered.isEmpty)
                      ? const Center(
                    child: Text(
                      'No data found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Color(0xff003840)),
                    ),
                  )
                      :  ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final attendee = filtered[index];
                      final popupKey =
                          GlobalKey<
                            PopupMenuButtonState<String>
                          >(); // unique per-row
                      final bool isThisMenuOpen =
                          _openMenuAppId == attendee.applicantApplicationId;

                      final String rowStatus =
                          _statusByAppId[attendee.applicantApplicationId] ??
                          (attendee.applicationStatusName?.trim().isNotEmpty ==
                                  true
                              ? attendee.applicationStatusName!
                              : 'Applied');
                      return
                        GestureDetector(
                          onTap: () {
                            final appId = attendee.applicantApplicationId;
                            final jobId = attendee.jobId;
                            final userId = attendee.userId;

                            // Guard: if any required id is missing, bail out gracefully
                            if (appId == null || jobId == null || userId == null) {
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   const SnackBar(content: Text('Missing applicant IDs')),
                              // );
                              showErrorSnackBar(context, "Missing applicant IDs");
                              return;
                            }

                            // Map Attendee -> ApplicantModel
                            final applicantModel = meeting;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider(
                                  create: (_) => ApplicanDetailBloc()
                                    ..add(
                                      LoadApplicant(
                                        applicationId: appId,              // now non-null int
                                        jobId: jobId,                      // now non-null int
                                        applicationStatus: attendee.applicationStatusName ?? '',
                                        userId: userId,                    // now non-null int
                                      ),
                                    ),
                                  child: InterViewStuDetail(
                                    applicationId: appId,
                                    jobId: jobId,
                                    // applicationStatus: attendee.applicationStatusName ?? '',
                                    userId: userId,
                                    // applicantModel: applicantModel,       // correct type
                                    // job: widget.meeting,                           // pass if your screen requires it
                                  ),
                                ),
                              ),
                            );
                          },

                          child:Card(
                        color: const Color(0xffe5ebeb),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// top row
                              Row(
                                children: [
                                  Checkbox(
                                    value: _selectedAttendees.contains(
                                      attendee.applicantApplicationId
                                          .toString(),
                                    ), // ✅ String compare
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedAttendees.add(
                                            attendee.applicantApplicationId
                                                .toString(),
                                          ); // ✅ String add
                                        } else {
                                          _selectedAttendees.remove(
                                            attendee.applicantApplicationId
                                                .toString(),
                                          ); // ✅ String remove
                                        }
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          _truncateName(
                                            toTitleCase(attendee.fullName),
                                            maxLength: 18,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF003840),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD573),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Color(0xFFDEAA2F),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            attendee.sendNotificationCount
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF000000),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFB22121),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Image.asset(
                                        'assets/delete.png',
                                        width: 16,
                                        height: 16,
                                      ),
                                      onPressed: () {
                                        _deleteAttendee(attendee);
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              /// details card
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      /// Status
                                      Row(
                                        children: [
                                          const Text(
                                            "Status:",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF003840),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  attendee.isAttended == "Yes"
                                                  ? const Color(0xffCAFEE3)
                                                  : Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              attendee.isAttended == "Yes"
                                                  ? "Joined"
                                                  : "Not Joined",
                                              style: TextStyle(
                                                color:
                                                    attendee.isAttended == "Yes"
                                                    ? const Color(0xff006A41)
                                                    : Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 5),

                                      /// College
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'College:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF003840),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Text(
                                              attendee.collegeName ?? "",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF003840),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      /// Shortlist
                                      Row(
                                        children: [
                                          const Text(
                                            'Shortlist:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF003840),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          PopupMenuButton<String>(
                                            key: ValueKey(
                                              attendee.applicantApplicationId,
                                            ), // unique key per-row

                                            onOpened: () {
                                              setState(
                                                () => _openMenuAppId = attendee
                                                    .applicantApplicationId,
                                              );
                                            },
                                            onCanceled: () {
                                              setState(
                                                () => _openMenuAppId = null,
                                              );
                                            },
                                            onSelected: (String selected) async {
                                              setState(
                                                () => _openMenuAppId = null,
                                              ); // close hone par reset

                                              final confirm =
                                                  await _showConfirmDialog(
                                                    context,
                                                    "Are you sure you want to change status?",
                                                  );

                                              if (!confirm) return;

                                              // UI turant update
                                              this.setState(() {
                                                attendee.applicationStatusName =
                                                    selected;
                                              });

                                              try {
                                                final prefs =
                                                    await SharedPreferences.getInstance();
                                                final token = prefs.getString(
                                                  'auth_token',
                                                );
                                                if (token == null) {
                                                  // ScaffoldMessenger.of(
                                                  //   context,
                                                  // ).showSnackBar(
                                                  //   const SnackBar(
                                                  //     content: Text(
                                                  //       "Authentication token not found",
                                                  //     ),
                                                  //     backgroundColor:
                                                  //         Colors.red,
                                                  //   ),
                                                  // );
                                                  showErrorSnackBar(context, "Authentication token not found");
                                                  return;
                                                }

                                                final url = Uri.parse(
                                                  '${BASE_URL}job/dashboard/update-application-status',
                                                );

                                                final body = {
                                                  "job_id": attendee.jobId,
                                                  "action": selected,
                                                  "application_id_list": [
                                                    attendee
                                                        .applicantApplicationId,
                                                  ],
                                                  "process_id": "",
                                                };

                                                final response = await http
                                                    .post(
                                                      url,
                                                      headers: {
                                                        "Content-Type":
                                                            "application/json",
                                                        "Authorization":
                                                            "Bearer $token",
                                                      },
                                                      body: jsonEncode(body),
                                                    );

                                                final decoded = jsonDecode(
                                                  response.body,
                                                );
                                                if (response.statusCode ==
                                                        200 &&
                                                    decoded["status"] == true) {
                                                  // ScaffoldMessenger.of(
                                                  //   context,
                                                  // ).showSnackBar(
                                                  //   SnackBar(
                                                  //     content: const Text(
                                                  //       "Status updated successfully",
                                                  //       style: TextStyle(
                                                  //         color: Colors.white,
                                                  //       ),
                                                  //     ),
                                                  //     backgroundColor:
                                                  //         Colors.green,
                                                  //     duration: const Duration(
                                                  //       seconds: 2,
                                                  //     ),
                                                  //     behavior: SnackBarBehavior
                                                  //         .floating,
                                                  //     margin:
                                                  //         const EdgeInsets.symmetric(
                                                  //           horizontal: 20,
                                                  //           vertical: 10,
                                                  //         ),
                                                  //     shape: RoundedRectangleBorder(
                                                  //       borderRadius:
                                                  //           BorderRadius.circular(
                                                  //             10,
                                                  //           ),
                                                  //     ),
                                                  //   ),
                                                  // );
                                                  showSuccessSnackBar(context, "Status updated successfully");
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Failed: ${decoded['message'] ?? 'Unknown error'}",
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Error: ${e.toString()}",
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return _statusOptions.map((
                                                status,
                                              ) {
                                                return PopupMenuItem<String>(
                                                  value: status,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 3,
                                                        horizontal: 0,
                                                      ),
                                                  height: 20,
                                                  child: Center(
                                                    child: Container(
                                                      width: 120,
                                                      height: 25,
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(
                                                          status,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          status,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                _getStatusTextColor(
                                                                  status,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList();
                                            },

                                            // look & feel
                                            padding: EdgeInsets.zero,
                                            color: Colors.white,
                                            offset: const Offset(0, 30),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),

                                            // 👇 Yeh child pura clickable hoga (smooth ripple ke saath)
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xff005E6A),
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                        rowStatus,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            40,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      rowStatus,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontFamily: "Inter",
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            _getStatusTextColor(
                                                              rowStatus,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Image.asset(
                                                    isThisMenuOpen
                                                        ? 'assets/uparrow.png'
                                                        : 'assets/downarrow.png', // 👈 agar band hai
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper row
  Widget detailRow(String iconPath, String text) {
    return Row(
      children: [
        Image.asset(iconPath, width: 16, height: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xff003840)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Delete attendee with API
  ///
  Future<void> _deleteAttendee(Attendee attendee) async {
    String? reason = await _showReasonBottomSheet(context);
    if (reason == null || reason.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 12),

                // Title
                const Text(
                  "Confirm Delete",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff003840),
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  "Are you sure you want to remove this participant?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),

                // Reason (preview)
                Text(
                  "Reason: $reason",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xffB22121),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Delete",
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

    if (confirmed == true) {
      // ✅ remember which row is being deleted so we can update UI on success
      setState(() {
        _pendingDeleteUserId = attendee.userId;
        _pendingDeleteAppId = attendee.applicantApplicationId;
      });
      context.read<DiscussionBloc>().add(
        DeleteAttendeeEvent(
          meetingId: attendee.meetingId.toString(),
          userId: attendee.userId,
          reason: reason,
        ),
      );
    }
  }


  /// Reason bottom sheet
  Future<String?> _showReasonBottomSheet(BuildContext context) {
    String tempReason = '';
    final controller = TextEditingController();
    bool showError = false;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Delete",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 🔴 Label with required asterisk
                   RichText(
                    text: TextSpan(
                      text: 'Please provide a reason',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      children: [
                        TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 2,
                    onChanged: (v) {
                      tempReason = v;
                      if (showError && v.trim().isNotEmpty) {
                        setState(() => showError = false);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Enter reason...",
                      errorText: showError ? 'Reason is required' : null, // ✅ Required indication
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF005E6A)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005E6A),
                        ),
                        onPressed: () {
                          final value = controller.text.trim();
                          if (value.isEmpty) {
                            setState(() => showError = true); // ✅ Block submit + show error
                            return;
                          }
                          Navigator.pop(context, value);
                        },
                        child: const Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Context menu
  void _showCustomMenu(BuildContext context, int meetingId) async {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 6,
        offset.dx + size.width,
        offset.dy,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        _buildSelectableMenuItem(
          index: 0,
          iconPath: 'assets/send.png',
          text: 'Send Reminder',
          meetingId: meetingId,
        ),
        // _buildSelectableMenuItem(
        //   index: 1,
        //   iconPath: 'assets/edit.png',
        //   text: 'Edit Meeting',
        //   meetingId: meetingId,
        // ),
        // _buildSelect_sendReminder
        //   index: 2,
        //   iconPath: 'assets/add_user.png',
        //   text: 'Add Student',
        //   meetingId: meetingId,
        // ),
        _buildSelectableMenuItem(
          index: 2,
          iconPath: 'assets/delete.png',
          text: 'Delete Meeting',
          meetingId: meetingId,
          defaultColor: Colors.red,
        ),
      ],
    );
  }

  PopupMenuItem _buildSelectableMenuItem({
    required int index,
    required String iconPath,
    required String text,
    required int meetingId,
    Color defaultColor = const Color(0xFF005E6A),
  }) {
    final bool isSelected = selectedIndex == index;
    final Color bgColor = isSelected
        ? const Color(0xff005E6A)
        : Colors.transparent;
    final Color textColor = isSelected ? Colors.white : defaultColor;

    return PopupMenuItem(
      padding: EdgeInsets.zero,
      onTap: () {
        setState(() => selectedIndex = index);

        if (index == 0) {
          // 🔥 Send Reminder API
          _sendReminder(
            widget.meeting.id.toString(),
            widget.meeting.jobId.toString(),
          );
        } else if (index == 2) {
          _deleteMeeting(meetingId);
        }
      },
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Image.asset(iconPath, width: 20, height: 20, color: textColor),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMeeting(int meetingId) async {
    String? reason = await _showReasonBottomSheet(context);
    if (reason == null || reason.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⚠️ Warning Icon
                // const Icon(Icons.event_busy, color: Colors.red, size: 56),
                const SizedBox(height: 12),

                // Title
                const Text(
                  "Confirm Delete",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff003840),
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  "Are you sure you want to delete this meeting?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),

                // Reason highlight
                Text(
                  "Reason: $reason",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xffB22121),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Delete",
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

    if (confirmed == true) {
      context.read<DiscussionBloc>().add(
        DeleteMeetingEvent(meetingId: meetingId.toString(), reason: reason),
      );
    }
  }

  String getShortCompanyName(String name) {
    final parts = name.split(" ");
    if (parts.length > 2) {
      return "${parts[0]} ${parts[1]}...";
    }
    return name;
  }

  Future<void> _sendReminder(String meetingId, String jobId) async {
    if (_selectedAttendees.isEmpty) {
      showSuccessSnackBar(context, "Please select at least one attendee");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auth token not found"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final url = Uri.parse(
        '${BASE_URL}interview-room/send-notification-to-not-joined',
      );

      final body = {
        "meeting_id": meetingId,
        "job_id": jobId,
        "application_id_list": _selectedAttendees.toList(),
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded["status"] == true) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Reminder sent successfully"), backgroundColor: Colors.green),
        // );
        showSuccessSnackBar(context, "Reminder sent successfully");
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("Failed: ${decoded['msg'] ?? 'Unknown error'}"), backgroundColor: Colors.red),
        // );
        showErrorSnackBar(context, " Internal Server Error");
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      // );
      showErrorSnackBar(context, " Something Went Wrong");
    }
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10,
          ), // ✅ Rectangular with little radius
        ),
        duration: Duration(seconds: 2),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }


  String _truncateName(String name, {int maxLength = 12}) {
    if (name.length <= maxLength) return name;
    return "${name.substring(0, maxLength)}..";
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/HR/model/interview_bottom.dart';
import 'package:skeletonizer/skeletonizer.dart';

// TPO Interview bloc files
import 'package:skillsconnect/TPO/Interview/tpo_interview_bloc.dart';
import 'package:skillsconnect/TPO/Interview/tpo_interview_event.dart';
import 'package:skillsconnect/TPO/Interview/tpo_interview_state.dart';

import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
import 'package:skillsconnect/TPO/Screens/tpo_inner_metting.dart';
import 'package:skillsconnect/TPO/Screens/tpo_notification.dart';
import 'package:url_launcher/url_launcher.dart';

// getUserData()
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../HR/bloc/Login/login_bloc.dart';
import '../../HR/screens/ForceUpdate/Forcelogout.dart';

class InterviewDataScreen extends StatefulWidget {
  const InterviewDataScreen({super.key});

  @override
  State<InterviewDataScreen> createState() => _InterviewDataScreenState();
}

class _InterviewDataScreenState extends State<InterviewDataScreen> {
  bool _showDropdown = true; // (future use)
  String? userImg;
  String? role;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final data = await getUserData();
    if (!mounted) return;
    setState(() {
      userImg = data['user_img'];
      role = data['role'];
    });
  }

  // ---------------- LIVE helpers (no design change) ----------------

  // parse month names like "Sep", "September"
  int? _monthFromName(String m) {
    final s = m.trim().toLowerCase();
    const map = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'sept': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };
    return map[s];
  }

  // parse dates like: "2025-09-11", "11-09-2025", "11 Sep 2025"
  DateTime? _parseDateFlexible(String? input) {
    if (input == null) return null;
    final s = input.trim();
    if (s.isEmpty) return null;

    // ISO: yyyy-MM-dd
    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso.hasMatch(s)) {
      try {
        return DateTime.parse('$s 00:00:00');
      } catch (_) {}
    }

    // dd-MM-yyyy
    final dmy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
    final m1 = dmy.firstMatch(s);
    if (m1 != null) {
      final d = int.parse(m1.group(1)!);
      final mo = int.parse(m1.group(2)!);
      final y = int.parse(m1.group(3)!);
      return DateTime(y, mo, d);
    }

    // dd MMM yyyy  (e.g., 11 Sep 2025)
    final dMonY = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$');
    final m2 = dMonY.firstMatch(s);
    if (m2 != null) {
      final d = int.parse(m2.group(1)!);
      final monStr = m2.group(2)!;
      final y = int.parse(m2.group(3)!);
      final mo = _monthFromName(monStr);
      if (mo != null) return DateTime(y, mo, d);
    }

    return null;
  }

  // parse times like: "14:30" or "2:30 PM"
  String? _toHHmm(String? time) {
    if (time == null) return null;
    var t = time.trim().toUpperCase();
    if (t.isEmpty) return null;

    // 24h => HH:mm
    final h24 = RegExp(r'^(\d{1,2}):(\d{2})$');
    final m0 = h24.firstMatch(t);
    if (m0 != null) {
      final hh = int.parse(m0.group(1)!);
      final mm = int.parse(m0.group(2)!);
      if (hh >= 0 && hh <= 23 && mm >= 0 && mm <= 59) {
        final hhStr = hh.toString().padLeft(2, '0');
        final mmStr = mm.toString().padLeft(2, '0');
        return '$hhStr:$mmStr';
      }
    }

    // 12h => h:mm AM/PM
    final h12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
    final m1 = h12.firstMatch(t);
    if (m1 != null) {
      var hh = int.parse(m1.group(1)!);
      final mm = int.parse(m1.group(2)!);
      final ap = m1.group(3)!; // AM / PM
      if (ap == 'AM') {
        if (hh == 12) hh = 0;
      } else if (ap == 'PM') {
        if (hh != 12) hh += 12;
      }
      final hhStr = hh.toString().padLeft(2, '0');
      final mmStr = mm.toString().padLeft(2, '0');
      return '$hhStr:$mmStr';
    }

    return null;
  }

  // combine date + time into DateTime (local)
  DateTime? _combineDateAndTime(String? dateStr, String? timeStr) {
    final date = _parseDateFlexible(dateStr);
    final hhmm = _toHHmm(timeStr);
    if (date == null || hhmm == null) return null;
    return DateTime.parse(
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $hhmm:00');
  }

  // main predicate: show LIVE only when now is within [start, end]
  bool _isLive({
    required String? dateLabel,
    required String? startLabel,
    required String? endLabel,
  }) {
    final start = _combineDateAndTime(dateLabel, startLabel);
    final end = _combineDateAndTime(dateLabel, endLabel);
    if (start == null || end == null) return false;
    final now = DateTime.now(); // local tz (IST on device)
    return (now.isAfter(start) || now.isAtSameMomentAs(start)) &&
        (now.isBefore(end) || now.isAtSameMomentAs(end));
  }

  // ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscussionBloc()..add(LoadDiscussions()),
      child: Scaffold(
        appBar: const TpoCustomAppBar(),
        body: BlocBuilder<DiscussionBloc, DiscussionState>(
          builder: (context, state) {
            
            // if (state is DiscussionLoading || state is DiscussionInitial) {
            //   return const Center(child: CircularProgressIndicator());
            // }
            if (state is DiscussionLoading || state is DiscussionInitial) {
              return const _InterviewSkeletonList();
            }

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
              final failure = ApiHttpFailure(
                statusCode: actualCode,
                body: state.message,
              );
              return OopsPage(failure: failure);
            }

            if (state is DiscussionLoaded) {
              if (state.meetings.isEmpty) {
                return const Center(
                  child: Text(
                    "No Interview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff003840),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.meetings.length,
                        itemBuilder: (context, index) {
                          final discussion = state.meetings[index];

                          final liveNow = _isLive(
                            dateLabel: discussion.formattedInterviewDate,
                            startLabel: discussion.formattedStartTime,
                            endLabel: discussion.formattedEndTime,
                          );

                          return InkWell(onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => DiscussionBloc(),
                                  child: TpoMeetingScreen(tpomeeting: discussion),
                                ),
                              ),
                            );
                          },
                          child:Card(
                            color: const Color(0xffe5ebeb),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Color(0xffEBF6F7)),
                            ),
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Text(
                                          discussion.interviewName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xff003840),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),

                                        // Company + LIVE (conditional)
                                        Row(
                                          children: [
                                            const Image(
                                              image: AssetImage('assets/building.png'),
                                              height: 18,
                                              width: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              discussion.companyName,
                                              style: const TextStyle(
                                                color: Color(0xff003840),
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),

                                            // 👉 LIVE only if within window
                                            if (liveNow)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'LIVE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Date row
                                        Row(
                                          children: [
                                            const Image(
                                              image: AssetImage('assets/calender.png'),
                                              height: 18,
                                              width: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "${discussion.formattedInterviewDate} | ${discussion.formattedStartTime}  to  ${discussion.formattedEndTime}",
                                                style: const TextStyle(
                                                  color: Color(0xff003840),
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Invited + Participants
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // LEFT: table icon + moderator name (bounded)
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Image(
                                                    image: AssetImage('assets/tableicon.png'),
                                                    height: 18,
                                                    width: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      (discussion.moderators.isNotEmpty
                                                          ? discussion.moderators.first.fullName
                                                          : '—') ??
                                                          '—',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Color(0xff003840),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // RIGHT: meeting mode + join icon (WHOLE AREA TAPPABLE)
                                            InkWell(
                                              onTap: () => _openMeeting(discussion), // <-- open on tap
                                              borderRadius: BorderRadius.circular(6),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      discussion.meetingMode ?? '—', // ya discussion.mettingmode
                                                      style: const TextStyle(
                                                        color: Color(0xff003840),
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Image(
                                                      image: AssetImage(
                                                        discussion.platform ==
                                                            "manual"
                                                            ? "assets/meeting.png"
                                                            : discussion.platform ==
                                                            "zoom"
                                                            ? "assets/join.png"
                                                            : discussion.platform ==
                                                            "google-meet"
                                                            ? "assets/gmeet.png"
                                                            : discussion.platform ==
                                                            ""
                                                            ? "assets/manual.png"
                                                            : "assets/join.png", // 👈 default
                                                      ),
                                                      height: 18,
                                                      width: 18,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )

                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ) );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            // Fallback
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Future<void> _openMeeting(ScheduledMeeting m) async {
    final link = (m.meetingLink ?? '').trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Meeting link not available")),
      );
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid meeting link: $link")),
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open meeting link")),
      );
    }
  }
}

class _InterviewSkeletonList extends StatelessWidget {
  const _InterviewSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: List.generate(
              4, // 4 fake interviews skeleton
                  (index) => const _InterviewSkeletonCard(),
            ),
          ),
        ),
      ),
    );
  }
}

class _InterviewSkeletonCard extends StatelessWidget {
  const _InterviewSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffe5ebeb),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xffEBF6F7)),
      ),
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Interview title
                  const Text(
                    'Interview Title Placeholder',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xff003840),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Company + LIVE chip placeholder
                  Row(
                    children: [
                      const Icon(
                        Icons.apartment,
                        size: 18,
                        color: Color(0xff003840),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Company Name Placeholder',
                          style: TextStyle(
                            color: Color(0xff003840),
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 5,
                      //     vertical: 2,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: Colors.red,
                      //     borderRadius: BorderRadius.circular(4),
                      //   ),
                      //   child: const Text(
                      //     'LIVE',
                      //     style: TextStyle(
                      //       color: Colors.white,
                      //       fontSize: 13,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Date + time row
                  Row(
                    children: const [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Color(0xff003840),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '11 Sep 2025 | 02:00 PM to 03:00 PM',
                          style: TextStyle(
                            color: Color(0xff003840),
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Moderator + meeting mode row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT: moderator name
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 18,
                              color: Color(0xff003840),
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Moderator Name Placeholder',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xff003840),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // RIGHT: meeting mode + icon
                      Row(
                        children: const [
                          Text(
                            'Zoom',
                            style: TextStyle(
                              color: Color(0xff003840),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          CircleAvatar(
                            radius: 10,
                            child: Icon(
                              Icons.videocam,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


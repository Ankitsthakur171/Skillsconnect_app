import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skillsconnect/HR/model/job_model.dart';
import 'package:skillsconnect/HR/screens/Interview_tab_innerView.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // link open karne ke liye
import '../bloc/InterView_Data/interviewtab_state.dart';
import '../bloc/InterView_Data/interviewtab_bloc.dart';
import '../bloc/InterView_Data/interviewtab_event.dart';
import '../model/interview_bottom.dart';
import 'EnterOtpScreen.dart';
import 'ForceUpdate/Forcelogout.dart';
import 'custom_app_bar.dart';
import 'interview_address_page.dart';
import 'notification_screen.dart';

class InterViewTab extends StatefulWidget {
  final List<ScheduledMeeting> meetings;
  final JobModel jobs;
  final bool showAppBar;   // 👈 new flag


  const InterViewTab({
    super.key, required this.meetings, this.showAppBar = true, required this.jobs  // by default AppBar dikhana

  });

  @override
  State<InterViewTab> createState() => _InterviewState();
}

class _InterviewState extends State<InterViewTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscussionBloc()..add(LoadDiscussions(jobId: widget.jobs.jobId.toString())),
      child: Scaffold(
        // appBar: const CustomAppBar(),
        appBar: widget.showAppBar ? const CustomAppBar() : null,  // 👈 condition
        body: BlocBuilder<DiscussionBloc, DiscussionState>(
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
              final failure = ApiHttpFailure(
                statusCode: actualCode,   // agar tumhare DiscussionError me code ho
                body: state.message,
              );
              return OopsPage(failure: failure);
            }

            if (state is DiscussionLoaded) {
              if (state.discussions.isEmpty) {
                // 👇 Agar koi interview/discussion nahi hai
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: state.discussions.length,
                        itemBuilder: (context, index) {
                          final discussion = state.discussions[index];
                          return Card(
                            color: const Color(0xffe5ebeb),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Color(0xffEBF6F7)),
                            ),
                            // margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        ' ${discussion.interviewName} | ${discussion.jobTitle} ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xff003840)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Transform.translate(
                                    //   offset: const Offset(0, -8), // shift upward by 6 pixels
                                    //   child: Container(
                                    //     width: 12,
                                    //     height: 12,
                                    //     decoration: BoxDecoration(
                                    //       shape: BoxShape.circle,
                                    //       color: Color(0xff003840), // inner color
                                    //       border: Border.all(
                                    //         color: Color(0xffCAFEE3),       // red border
                                    //         width: 2,
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding:
                                    const EdgeInsets.fromLTRB(12, 6, 4, 4),
                                    //margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Image(
                                              image: AssetImage(
                                                  'assets/alarm.png'),
                                              height: 18,
                                              width: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${discussion.formattedStartTime} to ${discussion.formattedEndTime}",
                                              style: const TextStyle(
                                                color: Color(0xff003840),
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                              ),
                                            ),
                                            // const SizedBox(
                                            //   width: 125,
                                            // ),
                                            const Spacer(),

                                            // LIVE badge sirf tab dikhega jab condition match kare
                                            if (_isLiveNow(discussion))
                                              Container(
                                                margin: const EdgeInsets.only(right: 8), // 👈 right spacing

                                                padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                  BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'LIVE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Image(
                                              image: AssetImage(
                                                'assets/year.png',
                                              ),
                                              height: 16,
                                              width: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(discussion.formattedInterviewDate,
                                                style: TextStyle(
                                                    color: Color(0xff003840),
                                                    fontFamily: 'Inter',
                                                    fontSize: 12)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  /// 👈 Left side: Invited count
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Color(0xffEBF6F7), width: 2),
                                      color: Color(0xffe5ebeb),
                                    ),
                                    child: Row(
                                      children: [
                                        const Image(
                                          image: AssetImage('assets/tperson.png'),
                                          height: 16,
                                          width: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${discussion.studentCount.toString().padLeft(2, '0')} Invited',
                                          style: const TextStyle(
                                            color: Color(0xff003840),
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// 👈 Right side: Meeting Mode + Icon
                                  Row(
                                    children: [
                                      Text(
                                        discussion.meetingMode ?? '—',
                                        style: const TextStyle(
                                          color: Color(0xff003840),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Image(
                                        image: AssetImage(
                                          discussion.platform == "manual"
                                              ? "assets/meeting.png"
                                              : discussion.platform == "zoom"
                                              ? "assets/join.png"
                                              : discussion.platform == "google-meet"
                                              ? "assets/gmeet.png"
                                              : discussion.platform == ""
                                              ? "assets/manual.png"
                                              : "assets/join.png", // 👈 default
                                        ),
                                        height: 18,
                                        width: 18,
                                      ),
                                      const SizedBox(width: 6),

                                    ],
                                  ),
                                ],
                              ),

                                        // Row(
                                        //   mainAxisAlignment:
                                        //   MainAxisAlignment.spaceBetween,
                                        //   children: [
                                        //     Container(
                                        //       padding:
                                        //       const EdgeInsets.symmetric(
                                        //           horizontal: 8,
                                        //           vertical: 4),
                                        //       decoration: BoxDecoration(
                                        //         borderRadius:
                                        //         BorderRadius.circular(20),
                                        //         border: Border.all(
                                        //             color: Color(0xffEBF6F7),
                                        //             width: 2),
                                        //         color: Color(0xffe5ebeb),
                                        //       ),
                                        //       child: Row(
                                        //         children: [
                                        //           Image(
                                        //             image: AssetImage(
                                        //               'assets/tperson.png',
                                        //             ),
                                        //             height: 16,
                                        //             width: 16,
                                        //           ),
                                        //           const SizedBox(width: 4),
                                        //           Text(
                                        //             '${discussion.studentCount.toString().padLeft(2, '0')} Invited',
                                        //             style: TextStyle(
                                        //                 color:
                                        //                 Color(0xff003840),
                                        //                 fontFamily: 'Inter',
                                        //                 fontSize: 12),
                                        //           ),
                                        //         ],
                                        //       ),
                                        //     ),
                                        //     // SizedBox(
                                        //     //   height: 28,
                                        //     //   width: 100, // adjust width based on number of images
                                        //     //   child: Stack(
                                        //     //     children: [
                                        //     //       for (int i = 0; i < discussion.participantImages.length; i++)
                                        //     //         Positioned(
                                        //     //           left: i * 20.0, // controls overlap amount
                                        //     //           child: CircleAvatar(
                                        //     //             radius: 14,
                                        //     //             backgroundImage: AssetImage(discussion.participantImages[i]),
                                        //     //           ),
                                        //     //         ),
                                        //     //       Positioned(
                                        //     //         left: discussion.participantImages.length * 20.0,
                                        //     //         child: const CircleAvatar(
                                        //     //           radius: 14,
                                        //     //           backgroundColor: Color(0xFF004D4D),
                                        //     //           child: Icon(Icons.add, color: Colors.white, size: 16),
                                        //     //         ),
                                        //     //       ),
                                        //     //     ],
                                        //     //   ),
                                        //     // ),
                                        //   ],
                                        // ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF005E6A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(22),
                                            ),
                                          ),
                                          onPressed: () {
                                            if (discussion.meetingMode == "in-office") {
                                              // 👉 View Address page open
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => MeetingDetailsPage(meeting: discussion),
                                                ),
                                              );
                                            } else {
                                              // 👉 Online meeting → join
                                              _joinInterview(context, discussion);
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                (discussion.meetingMode == "in-office")
                                                    ? "View Address"
                                                    : "Join Now",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_sharp,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8), // buttons ke beech gap
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF005E6A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(22),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final changed = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BlocProvider.value(
                                                  value: context.read<DiscussionBloc>(), // ✅ same bloc pass
                                                  child: InterviewTabInnerview(meeting: discussion),
                                                ),
                                              ),
                                            );

                                            // ✅ Sirf tab reload jab inner se delete hua ho
                                            if (changed == true) {
                                              if (!context.mounted) return;
                                              context.read<DiscussionBloc>().add(
                                                LoadDiscussions(jobId: widget.jobs.jobId.toString()),
                                              );
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text(
                                                "View Now",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_sharp,
                                                color: Colors.white,
                                                size: 12,
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
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
            return const _InterviewListSkeleton();
          },
        ),
      ),
    );
  }



  Future<void> _joinInterview(BuildContext context, dynamic discussion) async {
    try {
      // ✅ Agar platform blank hai → direct meeting_map_link open karo
      if ((discussion.platform ?? '').isEmpty) {
        final link = discussion.meetingmaplink?.toString().trim();
        if (link != null && link.isNotEmpty) {
          final uri = Uri.parse(link);
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched && mounted) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text("Could not open meeting link")),
            // );
            showErrorSnackBar(context, "Could not open meeting link");

          }
        } else {
          if (mounted) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text("Meeting link not available")),
            // );
            showErrorSnackBar(context, "Meeting link not available");

          }
        }
        return; // ✅ direct return, API call skip
      }

      // ✅ Agar platform available hai (zoom / gmeet etc.) → API call chalega
      final meetingId = (discussion.id ?? '').toString().trim();
      print("🔎 [join] meetingIdRaw=${discussion.id} -> meetingId='$meetingId'");
      if (meetingId.isEmpty) {
        if (!mounted) return;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Meeting ID missing")),
        // );
        showErrorSnackBar(context, "Meeting ID missing");

        return;
      }

      // Token nikaalo
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Token not found, please login again")),
        // );
        showErrorSnackBar(context, "Token not found, please login again");

        return;
      }

      // API call
      final url = Uri.parse(
        "${BASE_URL}interview-room/join-interview",
      );
      final body = {"meeting_id": meetingId};

      print("➡️ POST $url with body: $body");

      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("⬅️ Resp: ${resp.statusCode}");
      print("    Body: ${resp.body}");

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        final ok = (data["status"] == true) || (data["success"] == true);
        (data["meeting_link"] ?? data["link"] ?? data["url"])?.toString();

        final linkRaw = (data["meeting_link"] ?? data["link"] ?? data["url"])?.toString();

        if (ok && linkRaw != null && linkRaw.trim().isNotEmpty) {
          // Agar already http/https se start hota hai → direct use
          final finalLink = linkRaw.startsWith("http")
              ? linkRaw
              : "https://api.skillsconnect.in$linkRaw";

          final uri = Uri.parse(finalLink.trim());
          print("✅ Redirecting to: $uri");

          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text("Could not open meeting link")),
            // );
            showErrorSnackBar(context, "Could not open meeting link");

          }
          return;
        }
        else {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text("Invalid server response: ${resp.body}")),
          // );
          showErrorSnackBar(context, "Server Error");

          return;
        }
      }

      // Non-200 case
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Error: ${resp.statusCode} — ${resp.body}")),
      // );
      showErrorSnackBar(context, "Error: ${resp.statusCode}");

    } catch (e, st) {
      print("💥 _joinInterview error: $e\n$st");
      if (!mounted) return;
    //   // ScaffoldMessenger.of(context).showSnackBar(
    //   //   SnackBar(content: Text("Something went wrong: $e")),
    //   // );
    }
  }



  bool _isLiveNow(ScheduledMeeting discussion) {
    try {
      final now = DateTime.now();

      print("⏰ Now: $now");
      print("📌 formattedInterviewDate: ${discussion.formattedInterviewDate}");
      print("📌 startTime: ${discussion.startTime}");
      print("📌 endTime: ${discussion.endTime}");

      // "10th Sep, 2025" → remove "st/th/rd/nd"
      final cleanDate = discussion.formattedInterviewDate
          .replaceAll(RegExp(r'(st|nd|rd|th)'), '');

      // Parse date
      final date = DateFormat("d MMM, yyyy").parse(cleanDate);

      // Parse start & end time
      final startTime = DateFormat("HH:mm").parse(discussion.startTime);
      final endTime = DateFormat("HH:mm").parse(discussion.endTime);

      // Combine date + time
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      );

      print("▶️ Start: $start");
      print("⏹ End: $end");

      final live = now.isAfter(start) && now.isBefore(end);

      print("🎯 isLiveNow = $live");

      return live;
    } catch (e) {
      print("⚠️ Error parsing date/time: $e");
      return false;
    }
  }

// bool _isLiveNow(ScheduledMeeting discussion) {
//   try {
//     // Date (formattedInterviewDate string ko parse karo)
//     final date = DateTime.parse(discussion.formattedInterviewDate);
//     // Agar formattedInterviewDate string yyyy-MM-dd format me hai ✅
//
//     // Start aur end time ko parse karo
//     final start = DateTime.parse("${discussion.formattedInterviewDate} ${discussion.startTime}");
//     final end = DateTime.parse("${discussion.formattedInterviewDate} ${discussion.endTime}");
//
//     final now = DateTime.now();
//
//     // Sirf tabhi true jab same din aur abhi ka time start–end ke beech ho
//     return now.isAfter(start) && now.isBefore(end);
//   } catch (e) {
//     print("⚠️ Error parsing date/time: $e");
//     return false;
//   }
// }

}


class _InterviewListSkeleton extends StatelessWidget {
  const _InterviewListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: List.generate(
              4, // 4 fake cards
                  (index) => const _InterviewCardSkeleton(),
            ),
          ),
        ),
      ),
    );
  }
}

class _InterviewCardSkeleton extends StatelessWidget {
  const _InterviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffe5ebeb),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xffEBF6F7)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Title row
            const Text(
              'Interview Title | Job Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xff003840),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // 🔹 Inner white container – time/date/invited/mode
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // time + LIVE
                  Row(
                    children: const [
                      Image(
                        image: AssetImage('assets/alarm.png'),
                        height: 18,
                        width: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '10:00 AM to 11:00 AM',
                        style: TextStyle(
                          color: Color(0xff003840),
                          fontFamily: 'Inter',
                          fontSize: 12,
                        ),
                      ),
                      Spacer(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          // color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // date
                  Row(
                    children: const [
                      Image(
                        image: AssetImage('assets/year.png'),
                        height: 16,
                        width: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '10 Sep, 2025',
                        style: TextStyle(
                          color: Color(0xff003840),
                          fontFamily: 'Inter',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // invited + mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xffEBF6F7),
                            width: 2,
                          ),
                          color: const Color(0xffe5ebeb),
                        ),
                        child: Row(
                          children: const [
                            Image(
                              image: AssetImage('assets/tperson.png'),
                              height: 16,
                              width: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '05 Invited',
                              style: TextStyle(
                                color: Color(0xff003840),
                                fontFamily: 'Inter',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          SizedBox(width: 4),
                          Image(
                            image: AssetImage('assets/join.png'),
                            height: 18,
                            width: 18,
                          ),
                          SizedBox(width: 6),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 🔹 Buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005E6A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () {},
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Join Now',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_sharp,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005E6A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () {},
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Now',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_sharp,
                          color: Colors.white,
                          size: 12,
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




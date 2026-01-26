// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../HR/model/interview_bottom.dart';
// import '../Interview/tpo_interview_bloc.dart';
// import '../Interview/tpo_interview_state.dart';
//
// class TpoMeetingScreen extends StatefulWidget {
//   final ScheduledMeeting tpomeeting;
//
//   const TpoMeetingScreen({super.key, required this.tpomeeting});
//
//   @override
//   State<TpoMeetingScreen> createState() => _MeetingScreenState();
// }
//
// class _MeetingScreenState extends State<TpoMeetingScreen> {
//   bool _showDetails = true;
//   final GlobalKey _key = GlobalKey();
//   int selectedIndex = 0;
//   String companyName = '';
//   String companyLogo = '';
//   final GlobalKey _popupKey = GlobalKey();
//   late String _selectedStatus;
//
//   final Map<int, String> _statusByAppId = {};
//
//   final List<String> _statusOptions = [
//     'Cv Shortlist',
//     'HR Reject',
//     'Final Selected',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     loadCompanyName();
//   }
//
//   Future<void> loadCompanyName() async {
//     final prefs = await SharedPreferences.getInstance();
//     final name = prefs.getString('company_name') ?? '';
//     final logoUrl = prefs.getString('company_logo');
//     setState(() {
//       companyName = name;
//       companyLogo = logoUrl ?? '';
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final meeting = widget.tpomeeting;
//
//     return BlocListener<DiscussionBloc, DiscussionState>(
//       listener: (context, state) {
//
//         if (state is DiscussionError) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.message), backgroundColor: Colors.red),
//           );
//         }
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xffffffff),
//         body: SafeArea(
//           child: Column(
//             children: [
//               /// ----- Header -----
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 12,
//                 ),
//                 color: const Color(0xffebf6f7),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         IconButton(
//                           icon: const Icon(
//                             Icons.arrow_back_ios_new,
//                             color: Colors.black,
//                           ),
//                           onPressed: () => Navigator.of(context).pop(),
//                         ),
//                         CircleAvatar(
//                           radius: 20,
//                           backgroundColor: Colors.grey.shade200,
//                           backgroundImage: (meeting.companyLogo != null && meeting.companyLogo.isNotEmpty)
//                               ? NetworkImage(meeting.companyLogo)
//                               : const AssetImage('assets/building.png') as ImageProvider,
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 meeting.interviewName,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               Row(
//                                 children: [
//                                   const Image(
//                                     image: AssetImage('assets/building.png'),
//                                     width: 16,
//                                     height: 16,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     getShortCompanyName(meeting.companyName),
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   const Image(
//                                     image: AssetImage('assets/rank.png'),
//                                     width: 16,
//                                     height: 16,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   const Text(
//                                     "5/5",
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Divider(),
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(12, 5, 5, 0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             'Details',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xff003840),
//                             ),
//                           ),
//                           InkWell(
//                             onTap: () {
//                               setState(() {
//                                 _showDetails = !_showDetails;
//                               });
//                             },
//                             child: _showDetails
//                                 ? Image.asset(
//                               'assets/arrow_down.png',
//                               width: 18,
//                               height: 18,
//                             )
//                                 : Image.asset(
//                               'assets/arrow_up.png',
//                               width: 18,
//                               height: 18,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     AnimatedCrossFade(
//                       firstChild: const SizedBox(),
//                       secondChild: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             detailRow(
//                               'assets/calender.png',
//                               meeting.formattedInterviewDate,
//                             ),
//                             const SizedBox(height: 8),
//                             detailRow(
//                               'assets/alarm.png',
//                               "${meeting.formattedStartTime} to ${meeting.formattedEndTime}",
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               children: [
//                                 const Image(
//                                   image: AssetImage('assets/person.png'),
//                                   width: 16,
//                                   height: 16,
//                                 ),
//                                 const SizedBox(width: 6),
//                                 const Text(
//                                   "HR Manager",
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Color(0xff003840),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     meeting.moderators.first.fullName,
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                     textAlign: TextAlign.right,
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       color: Color(0xff003840),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               children: [
//                                 const Image(
//                                   image: AssetImage('assets/mail.png'),
//                                   width: 16,
//                                   height: 16,
//                                 ),
//                                 const SizedBox(width: 6),
//                                 const Text(
//                                   "Moderator",
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Color(0xff003840),
//                                   ),
//                                 ),
//                                 const Spacer(),
//                                 Expanded(
//                                   flex: 2,
//                                   child: Text(
//                                     meeting.moderators.first.email,
//                                     textAlign: TextAlign.right,
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       color: Color(0xff003840),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       crossFadeState: _showDetails
//                           ? CrossFadeState.showSecond
//                           : CrossFadeState.showFirst,
//                       duration: const Duration(milliseconds: 300),
//                     ),
//                   ],
//                 ),
//               ),
//
//               /// ----- Search Bar + More Menu -----
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(15, 8, 15, 5),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: SizedBox(
//                         height: 45,
//                         child: TextField(
//                           decoration: InputDecoration(
//                             hintText: 'Search',
//                             prefixIcon: const Icon(Icons.search),
//                             contentPadding: const EdgeInsets.symmetric(
//                               vertical: 0,
//                               horizontal: 16,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(28),
//                               borderSide: BorderSide(
//                                 color: Colors.green.shade50,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     // const SizedBox(width: 10),
//                     // Container(
//                     //   key: _key,
//                     //   padding: const EdgeInsets.all(2),
//                     //   decoration: BoxDecoration(
//                     //     shape: BoxShape.circle,
//                     //     border: Border.all(
//                     //       color: const Color(0x20005E6A),
//                     //       width: 2,
//                     //     ),
//                     //   ),
//                     //   child: InkWell(
//                     //     onTap: () => _showCustomMenu(context, meeting.id),
//                     //     borderRadius: BorderRadius.circular(100),
//                     //     child: const CircleAvatar(
//                     //       radius: 18,
//                     //       backgroundColor: Colors.white,
//                     //       child: Icon(
//                     //         Icons.more_vert_outlined,
//                     //         size: 20,
//                     //         color: Color(0xff003840),
//                     //       ),
//                     //     ),
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ),
//
//               /// ----- Attendees -----
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: meeting.students.length,
//                   itemBuilder: (context, index) {
//                     final attendee = meeting.students[index];
//                     final String rowStatus =
//                         _statusByAppId[attendee.applicantApplicationId] ??
//                             (attendee.applicationStatusName
//                                 ?.trim()
//                                 .isNotEmpty ==
//                                 true
//                                 ? attendee.applicationStatusName!
//                                 : 'Applied');
//                     return Card(
//                       color: const Color(0xffe5ebeb),
//                       margin: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 6,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(6.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             /// top row
//                             Row(
//                               children: [
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Row(
//                                     children: [
//                                       Text(
//                                         attendee.fullName,
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 18,
//                                           color: Color(0xFF003840),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 10,
//                                           vertical: 2,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: const Color(0xFFFFD573),
//                                           borderRadius:
//                                           BorderRadius.circular(12),
//                                           border: Border.all(
//                                             color: Color(0xFFDEAA2F),
//                                             width: 1,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           attendee.sendNotificationCount
//                                               .toString(),
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold,
//                                             color: Color(0xFF000000),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//
//                             /// details card
//                             Card(
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               color: Colors.white,
//                               child: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     /// Status
//                                     Row(
//                                       children: [
//                                         const Text(
//                                           "Status:",
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color: Color(0xFF003840),
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 20),
//                                         Container(
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 8,
//                                             vertical: 4,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: attendee.isAttended == "Yes"
//                                                 ? const Color(0xffCAFEE3)
//                                                 : Colors.red.shade100,
//                                             borderRadius:
//                                             BorderRadius.circular(12),
//                                           ),
//                                           child: Text(
//                                             attendee.isAttended == "Yes"
//                                                 ? "Joined"
//                                                 : "Not Joined",
//                                             style: TextStyle(
//                                               color:
//                                               attendee.isAttended == "Yes"
//                                                   ? const Color(0xff006A41)
//                                                   : Colors.red,
//                                               fontSize: 14,
//                                               fontWeight: FontWeight.w600,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//
//                                     const SizedBox(height: 5),
//
//                                     /// College
//                                     Row(
//                                       crossAxisAlignment:
//                                       CrossAxisAlignment.start,
//                                       children: [
//                                         const Text(
//                                           'College:',
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color: Color(0xFF003840),
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 15),
//                                         Expanded(
//                                           child: Text(
//                                             attendee.collegeName ?? "",
//                                             style: const TextStyle(
//                                               fontSize: 14,
//                                               color: Color(0xFF003840),
//                                               fontWeight: FontWeight.w600,
//                                             ),
//                                             overflow: TextOverflow.ellipsis,
//                                             maxLines: 2,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 5),
//
//                                     /// Shortlist
//                                     Row(
//                                       children: [
//                                         const Text(
//                                           'Shortlist:',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.w600,
//                                             color: Color(0xFF003840),
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         Container(
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 12,
//                                             vertical: 6,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: const Color(0xff005E6A),
//                                             borderRadius: BorderRadius.circular(
//                                               40,
//                                             ),
//                                           ),
//                                           child: Text(
//                                             attendee.applicationStatusName ??
//                                                 "",
//                                             style: const TextStyle(
//                                               fontSize: 14,
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// Helper row
//   Widget detailRow(String iconPath, String text) {
//     return Row(
//       children: [
//         Image.asset(iconPath, width: 16, height: 16),
//         const SizedBox(width: 6),
//         Expanded(
//           child: Text(
//             text,
//             style: const TextStyle(fontSize: 14, color: Color(0xff003840)),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }
//
//   String getShortCompanyName(String name) {
//     final parts = name.split(" ");
//     if (parts.length > 2) {
//       return "${parts[0]} ${parts[1]}...";
//     }
//     return name;
//   }
// }



import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../HR/model/interview_bottom.dart';
import '../../HR/screens/ForceUpdate/Forcelogout.dart';
import '../Interview/tpo_interview_bloc.dart';
import '../Interview/tpo_interview_state.dart';
import '../TpoInterviewStudent/tpointerinnerbloc.dart';
import '../TpoInterviewStudent/tpointerinnerevent.dart';
import 'Tpo_inner_details.dart';
import 'tpo_inner_institute_detailspage.dart' show TpoInnerInstituteDetailspage;

class TpoMeetingScreen extends StatefulWidget {
  final ScheduledMeeting tpomeeting;

  const TpoMeetingScreen({super.key, required this.tpomeeting});

  @override
  State<TpoMeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<TpoMeetingScreen> {
  bool _showDetails = true;
  final GlobalKey _key = GlobalKey();
  int selectedIndex = 0;
  String companyName = '';
  String companyLogo = '';
  final GlobalKey _popupKey = GlobalKey();
  late String _selectedStatus;

  final Map<int, String> _statusByAppId = {};
  final List<String> _statusOptions = [
    'Cv Shortlist',
    'HR Reject',
    'Final Selected',
  ];

  // 🔍 Search related
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadCompanyName();
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

  @override
  Widget build(BuildContext context) {
    final meeting = widget.tpomeeting;

    // 🔍 Filtered attendees list
    final attendees = meeting.students.where((attendee) {
      final query = _searchQuery.toLowerCase();
      return attendee.fullName.toLowerCase().contains(query) ||
          (attendee.collegeName?.toLowerCase().contains(query) ?? false);
    }).toList();

    return BlocConsumer<DiscussionBloc, DiscussionState>(
      listener: (context, state) {
        if (state is DiscussionError) {
          // ❌ UI return nahi karna, sirf side-effect
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
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
          final failure = ApiHttpFailure(
            statusCode: actualCode,
            body: state.message,
          );
          return OopsPage(failure: failure); // ✅ ab builder me safe
        }

        // 🔹 Normal Scaffold UI
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
                            backgroundImage:
                            (meeting.companyLogo != null && meeting.companyLogo.isNotEmpty)
                                ? NetworkImage(meeting.companyLogo)
                                : const AssetImage('assets/building.png') as ImageProvider,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meeting.interviewName,
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
                                      getShortCompanyName(meeting.companyName),
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
                                      "${meeting.liveattendee} / ${meeting.studentCount}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                )
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      meeting.moderators.first.email,
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

                /// ----- Search Bar -----
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name or college',
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
                    ],
                  ),
                ),

                /// ----- Attendees -----
                Expanded(
                  child: attendees.isEmpty
                      ? const Center(
                    child: Text(
                      'No data found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003840),
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: attendees.length,
                    itemBuilder: (context, index) {
                      final attendee = attendees[index];

                      // Safely grab IDs for navigation (adjust field names if yours differ)
                      final int? appId = (attendee.applicationId is int)
                          ? attendee.applicationId
                          : int.tryParse('${attendee.applicationId}');
                      final int? jobId = (attendee.jobId is int)
                          ? attendee.jobId
                          : int.tryParse('${attendee.jobId}');
                      final int? userId = (attendee.userId is int)
                          ? attendee.userId
                          : int.tryParse('${attendee.userId}');

                      return InkWell(
                        onTap: () {
                          // Only navigate when we have valid IDs
                          if (appId == null || jobId == null || userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Missing IDs for this applicant.'),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (_) => Tpointerinnerbloc()
                                  ..add(TpoInterviewLoadApplicant(
                                    applicationId: appId,
                                    jobId: jobId,
                                    applicationStatus:
                                    attendee.applicationStatusName ?? '',
                                    userId: userId,
                                  )),
                                child: TpoInnerDetails(
                                  applicationId: appId,
                                  userId: userId,
                                  jobid: jobId,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Card(
                          color: const Color(0xffe5ebeb),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
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
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                /// details card (unchanged UI)
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
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
                                                color: attendee.isAttended == "Yes"
                                                    ? const Color(0xffCAFEE3)
                                                    : Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                attendee.isAttended == "Yes"
                                                    ? "Joined"
                                                    : "Not Joined",
                                                style: TextStyle(
                                                  color: attendee.isAttended == "Yes"
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

                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                        const SizedBox(height: 5),

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
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xff005E6A),
                                                borderRadius: BorderRadius.circular(40),
                                              ),
                                              child: Text(
                                                attendee.applicationStatusName ?? "",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
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
                )

                // Expanded(
                //   child: ListView.builder(
                //     itemCount: attendees.length,
                //     itemBuilder: (context, index) {
                //       final attendee = attendees[index];
                //
                //       return Card(
                //         color: const Color(0xffe5ebeb),
                //         margin: const EdgeInsets.symmetric(
                //           horizontal: 12,
                //           vertical: 6,
                //         ),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(12),
                //         ),
                //         child: Padding(
                //           padding: const EdgeInsets.all(6.0),
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               Row(
                //                 children: [
                //                   const SizedBox(width: 8),
                //                   Expanded(
                //                     child: Row(
                //                       children: [
                //                         Text(
                //                           attendee.fullName,
                //                           style: const TextStyle(
                //                             fontWeight: FontWeight.bold,
                //                             fontSize: 18,
                //                             color: Color(0xFF003840),
                //                           ),
                //                         ),
                //                       ],
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //
                //               /// details card
                //               Card(
                //                 shape: RoundedRectangleBorder(
                //                   borderRadius: BorderRadius.circular(12),
                //                 ),
                //                 color: Colors.white,
                //                 child: Padding(
                //                   padding: const EdgeInsets.all(8.0),
                //                   child: Column(
                //                     crossAxisAlignment: CrossAxisAlignment.start,
                //                     children: [
                //                       Row(
                //                         children: [
                //                           const Text(
                //                             "Status:",
                //                             style: TextStyle(
                //                               fontSize: 14,
                //                               color: Color(0xFF003840),
                //                               fontWeight: FontWeight.w600,
                //                             ),
                //                           ),
                //                           const SizedBox(width: 20),
                //                           Container(
                //                             padding: const EdgeInsets.symmetric(
                //                               horizontal: 8,
                //                               vertical: 4,
                //                             ),
                //                             decoration: BoxDecoration(
                //                               color: attendee.isAttended == "Yes"
                //                                   ? const Color(0xffCAFEE3)
                //                                   : Colors.red.shade100,
                //                               borderRadius: BorderRadius.circular(12),
                //                             ),
                //                             child: Text(
                //                               attendee.isAttended == "Yes"
                //                                   ? "Joined"
                //                                   : "Not Joined",
                //                               style: TextStyle(
                //                                 color: attendee.isAttended == "Yes"
                //                                     ? const Color(0xff006A41)
                //                                     : Colors.red,
                //                                 fontSize: 14,
                //                                 fontWeight: FontWeight.w600,
                //                               ),
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                       const SizedBox(height: 5),
                //
                //                       Row(
                //                         crossAxisAlignment: CrossAxisAlignment.start,
                //                         children: [
                //                           const Text(
                //                             'College:',
                //                             style: TextStyle(
                //                               fontSize: 14,
                //                               color: Color(0xFF003840),
                //                               fontWeight: FontWeight.w600,
                //                             ),
                //                           ),
                //                           const SizedBox(width: 15),
                //                           Expanded(
                //                             child: Text(
                //                               attendee.collegeName ?? "",
                //                               style: const TextStyle(
                //                                 fontSize: 14,
                //                                 color: Color(0xFF003840),
                //                                 fontWeight: FontWeight.w600,
                //                               ),
                //                               overflow: TextOverflow.ellipsis,
                //                               maxLines: 2,
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                       const SizedBox(height: 5),
                //
                //                       Row(
                //                         children: [
                //                           const Text(
                //                             'Shortlist:',
                //                             style: TextStyle(
                //                               fontWeight: FontWeight.w600,
                //                               color: Color(0xFF003840),
                //                               fontSize: 14,
                //                             ),
                //                           ),
                //                           const SizedBox(width: 10),
                //                           Container(
                //                             padding: const EdgeInsets.symmetric(
                //                               horizontal: 12,
                //                               vertical: 6,
                //                             ),
                //                             decoration: BoxDecoration(
                //                               color: const Color(0xff005E6A),
                //                               borderRadius: BorderRadius.circular(40),
                //                             ),
                //                             child: Text(
                //                               attendee.applicationStatusName ?? "",
                //                               style: const TextStyle(
                //                                 fontSize: 14,
                //                                 fontWeight: FontWeight.bold,
                //                                 color: Colors.white,
                //                               ),
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //       );
                //     },
                //   ),
                // ),
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

  String getShortCompanyName(String name) {
    final parts = name.split(" ");
    if (parts.length > 2) {
      return "${parts[0]} ${parts[1]}...";
    }
    return name;
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
}

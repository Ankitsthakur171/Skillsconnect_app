import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skillsconnect/TPO/Model/student_model.dart';
import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';
import 'package:skillsconnect/TPO/Screens/tpo_cv_screen.dart';
import 'package:skillsconnect/TPO/Screens/tpo_video.dart';
import 'package:skillsconnect/TPO/TPO_Applicant_details/applicant_details_state.dart';
import 'package:skillsconnect/TPO/widgets/tpo_cv_card_college.dart';
import 'package:skillsconnect/TPO/widgets/tpo_cv_card_expierence.dart';
import 'package:skillsconnect/TPO/widgets/tpo_cv_card_project.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../HR/screens/ForceUpdate/Forcelogout.dart';
import '../Model/tpo_applicant_details_model.dart';
import '../TPO_Applicant_details/applicant_deatils_bloc.dart';
import '../TPO_Applicant_details/applicant_deatils_event.dart';
import '../widgets/tpo_cv_card_certification.dart';
import '../widgets/tpo_cv_card_details.dart';


class TpoApplicantDetailsScreen extends StatefulWidget {
  final int applicationId;
  final int jobId;
  final int userId;
  final String applicationStatus;
  final TpoHomeJobModel job;
  final StudentModel applicantModel;

  const TpoApplicantDetailsScreen({
    super.key,
    required this.applicationId,
    required this.jobId,
    required this.userId,
    required this.job,
    required this.applicationStatus,
    required this.applicantModel,
  });

  @override
  State<TpoApplicantDetailsScreen> createState() => _ApplicantCVScreenState();
}

class _ApplicantCVScreenState extends State<TpoApplicantDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  List<GlobalKey> _keys = [];
  bool _isManualScroll = false;
  late String _selectedStatus;
  final GlobalKey _popupKey = GlobalKey();



  final List<String> _statusOptions = [
    'Applied',
    'Cv Shortlist',
    'HR Reject',
    'Candidate Declined',
    'Round Shortlisted',
    'Hold/Follow up',
    'Final Selected',
    'Hired',
  ];

  @override
  void initState() {
    super.initState();
    _keys = List.generate(7, (index) => GlobalKey());
    _tabController = TabController(length: 7, vsync: this);
    _scrollController = ScrollController();
    _tabController.addListener(_handleTabSelection);
    _scrollController.addListener(_onScroll);
    _selectedStatus = widget.applicantModel.application_status;

    Future.microtask(() {
      context.read<ApplicanDetailBloc>().add(LoadApplicant(
        applicationId: widget.applicationId,
        jobId: widget.jobId,
        userId: widget.userId,
        applicationStatus: widget.applicationStatus,
      ));
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging || _isManualScroll) return;

    final ctx = _keys[_tabController.index].currentContext;
    if (ctx == null) return;

    _isManualScroll = true;
    try {
      // Calculate the exact scroll offset of the target section
      final renderObj = ctx.findRenderObject();
      if (renderObj == null) return;
      final viewport = RenderAbstractViewport.of(renderObj);
      if (viewport == null) return;

      final targetOffset = viewport.getOffsetToReveal(renderObj, 0.0).offset;

      _scrollController
          .animateTo(
        targetOffset.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      )
          .whenComplete(() {
        // small debounce so scroll listener doesn’t immediately fight back
        Future.delayed(const Duration(milliseconds: 80), () {
          _isManualScroll = false;
        });
      });
    } catch (_) {
      _isManualScroll = false;
    }
  }
  void _onScroll() {
    if (_isManualScroll) return;

    double minDist = double.infinity;
    int nearest = _tabController.index;

    for (int i = 0; i < _keys.length; i++) {
      final ctx = _keys[i].currentContext;
      if (ctx == null) continue;

      final renderObj = ctx.findRenderObject();
      if (renderObj == null) continue;

      final viewport = RenderAbstractViewport.of(renderObj);
      if (viewport == null) continue;

      // Offset at which this section would be revealed at top
      final sectionTop = viewport.getOffsetToReveal(renderObj, 0.0).offset;
      final dist = (sectionTop - _scrollController.offset).abs();

      if (dist < minDist) {
        minDist = dist;
        nearest = i;
      }
    }

    if (nearest != _tabController.index) {
      // Don’t animate the TabBar change (prevents jitter)
      _isManualScroll = true;
      _tabController.index = nearest;
      // release the guard in the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isManualScroll = false;
      });
    }
  }

  // void _handleTabSelection() {
  //   if (!_tabController.indexIsChanging && !_isManualScroll) {
  //     _isManualScroll = true;
  //     final keyContext = _keys[_tabController.index].currentContext;
  //     if (keyContext != null) {
  //       Scrollable.ensureVisible(
  //         keyContext,
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeInOut,
  //       ).then((_) {
  //         Future.delayed(const Duration(milliseconds: 300), () {
  //           _isManualScroll = false;
  //         });
  //       });
  //     }
  //   }
  // }
  //
  // void _onScroll() {
  //   if (_isManualScroll) return;
  //
  //   final scrollOffset = _scrollController.offset;
  //   double minDistance = double.infinity;
  //   int closestIndex = 0;
  //
  //   for (int i = 0; i < _keys.length; i++) {
  //     final keyContext = _keys[i].currentContext;
  //     if (keyContext != null) {
  //       final box = keyContext.findRenderObject() as RenderBox?;
  //       if (box != null) {
  //         final position = box.localToGlobal(Offset.zero);
  //         final distance = (position.dy - scrollOffset).abs();
  //         if (distance < minDistance) {
  //           minDistance = distance;
  //           closestIndex = i;
  //         }
  //       }
  //     }
  //   }
  //
  //   if (_tabController.index != closestIndex) {
  //     _tabController.animateTo(closestIndex);
  //   }
  // }

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
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _scrollController.removeListener(_onScroll);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Tab> _buildTabs(TPOApplicant tpoaplicants) {
    List<Tab> tabs = [];
    if (tpoaplicants.resumeUrl.isNotEmpty) tabs.add(const Tab(text: 'CV'));
    if (tpoaplicants.name != null && tpoaplicants.name!.isNotEmpty) tabs.add(const Tab(text: 'Details'));
    if (tpoaplicants.tpoeducationList.isNotEmpty || tpoaplicants.basiceducation.isNotEmpty) tabs.add(const Tab(text: 'College'));
    if (tpoaplicants.experience.isNotEmpty) tabs.add(const Tab(text: 'Experience'));
    if (tpoaplicants.project.isNotEmpty) tabs.add(const Tab(text: 'Project and Internship'));
    if (tpoaplicants.certifications?.isNotEmpty ?? false) tabs.add(const Tab(text: 'Certifications'));
    if (tpoaplicants.videoIntroduction.isNotEmpty) tabs.add(const Tab(text: 'Interview'));
    return tabs;
  }


  List<Widget> _buildTabViews(TPOApplicant applicantdata) {
    _keys.clear(); // Clear previous keys
    List<Widget> views = [];

    void addSection(Widget child) {
      final key = GlobalKey();
      _keys.add(key);
      views.add(Container(key: key, child: child));
    }

    if (applicantdata.resumeUrl.isNotEmpty) {
      addSection(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(26, 8, 0, 3),
            child: Text('CV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xff003840))),
          ),
          CvSection(applicant: applicantdata),
        ],
      ));
    }

    if (applicantdata.name != null && applicantdata.name!.isNotEmpty) {
      addSection(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xff003840))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CvdetailsCard(applicant: applicantdata),
          ),
        ],
      ));
    }

    if (applicantdata.tpoeducationList.isNotEmpty || applicantdata.basiceducation.isNotEmpty) {
      addSection(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('College', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xff003840))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TpoCvCardCollege(
              educationList: applicantdata.tpoeducationList,
              basicEducationList: applicantdata.basiceducation,
            ),
          ),
        ],
      ));
    }

    if (applicantdata.experience.isNotEmpty) {
      addSection(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xff003840))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TpoCvCardExpierence(experienceList: applicantdata.experience),
          ),
        ],
      ));
    }

    if (applicantdata.project.isNotEmpty) {
      addSection(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Project and Internship', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xff003840))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TpoCvCardProject(projectList: applicantdata.project),
          ),
        ],
      ));
    }

    if (applicantdata.certifications?.isNotEmpty ?? false) {
      addSection(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Certifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xff003840))),
          ),
           Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: TpoCvCardCertification(certifications: applicantdata.certifications,),
          ),
        ],
      ));
    }

    if (applicantdata.videoIntroduction.isNotEmpty) {
      addSection(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Interview Videos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xff003840))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InterviewVideos(videoList: applicantdata.videoIntroduction),
          ),
          const SizedBox(height: 30),
        ],
      ));
    }
    views.add(const SizedBox(height: 100)); // always at the end

    return views;
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicanDetailBloc, ApplicantState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ApplicantError) {
          print("❌ ApplicantError: ${state.message}");

          int? actualCode = state.code;

          // 🔹 Agar code null hai, try to extract from message (e.g. "Error 401")
          if (actualCode == null && state.message != null) {
            final match = RegExp(r'\b(\d{3})\b').firstMatch(state.message!);
            if (match != null) {
              actualCode = int.tryParse(match.group(1)!);
            }
          }

          // 🔴 401 → Force logout (multiple device login)
          if (actualCode == 401) {
            ForceLogout.run(
              context,
              message: 'You are currently logged in on another device. '
                  'Logging in here will log you out from the other device.',
            );
            return const SizedBox.shrink(); // UI skip karo
          }

          // 🔴 403 → Force logout (session expired)
          if (actualCode == 403) {
            ForceLogout.run(
              context,
              message: 'Session expired.',
            );
            return const SizedBox.shrink();
          }

          final failure = ApiHttpFailure(
            statusCode: state.code,
            body: state.message,
          );
          return OopsPage(failure: failure);
        }

        if (state.applicant == null) {
          return const Scaffold(
            body: Center(child: Text("No applicant data found")),
          );
        }

        final applicant = state.applicant!;
        final tabs = _buildTabs(applicant);
        final tabViews = _buildTabViews(applicant);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xffEBF6F7),
            title: Text('1 out of ${widget.job.applicants} Applicants',
                style: const TextStyle(fontSize: 18)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: const Color(0xFF003840),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              // Applicant Header
              Container(
                color: const Color(0xffFFFFFF),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                child: Row(
                  children: [
                    // ⬇️ Avatar logic
                    Builder(
                      builder: (_) {
                        final img = (applicant.imageUrl).toString().trim();
                        final g   = (applicant.gender ?? '').toString().trim().toLowerCase();
                        final isMale = g.startsWith('m'); // 'male'/'Male' दोनों चलेगा

                        const maleSvg =
                            'https://stage.skillsconnect.in/4Y9TF1DRMZjCeD5K6ABaCuKXQsjq0jA76g3iZw0IEIY/assets/frontend/images/v2/male-user.svg';
                        const femaleSvg =
                            'https://stage.skillsconnect.in/4Y9TF1DRMZjCeD5K6ABaCuKXQsjq0jA76g3iZw0IEIY/assets/frontend/images/v2/female-user.svg';

                        if (img.isNotEmpty) {
                          // user image available -> normal
                          return CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(img)
                          );
                        }

                        // no image -> gender based SVG
                        return CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: SvgPicture.network(
                              isMale ? maleSvg : femaleSvg,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Text(
                        applicant.name ?? 'Applicant Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff003840),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Container(
              //   color: const Color(0xffFFFFFF),
              //   padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              //   child: Row(
              //     children: [
              //       CircleAvatar(
              //         radius: 25,
              //         backgroundImage: applicant.imageUrl.isNotEmpty
              //             ? NetworkImage(applicant.imageUrl)
              //             : const AssetImage('assets/profile.png') as ImageProvider,
              //       ),
              //       const SizedBox(width: 16),
              //       Expanded(
              //         child: Text(
              //           applicant.name ?? 'Applicant Name',
              //           style: const TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.w500,
              //             color: Color(0xff003840),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // TabBar
              Material(
                color: const Color(0xffFFFFFF),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xff00D584),
                  indicatorWeight: 5,
                  labelColor: const Color(0xff003840),
                  unselectedLabelColor: const Color(0x80003840),
                  tabs: tabs,
                ),
              ),

              // Main Content
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification && !_isManualScroll) {
                      _onScroll();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: tabViews,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Bar
          // bottomSheet: Container(
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFEBF6F7),
          //     borderRadius: BorderRadius.circular(25),
          //   ),
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          //   child: Row(
          //     children: [
          //       const Text(
          //         'CV Shortlist to Move to:',
          //         style: TextStyle(
          //           fontFamily: "Inter",
          //           fontWeight: FontWeight.w600,
          //           color: Color(0xFF003840),
          //           fontSize: 14,
          //         ),
          //       ),
          //       const SizedBox(width: 6),
          //       GestureDetector(
          //         onTap: () {
          //           final dynamic popup = _popupKey.currentState;
          //           popup?.showButtonMenu();
          //         },
          //         child: Container(
          //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          //           decoration: BoxDecoration(
          //             color: const Color(0xff005E6A),
          //             borderRadius: BorderRadius.circular(40),
          //           ),
          //           child: Row(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Container(
          //                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          //                 decoration: BoxDecoration(
          //                   color: _getStatusColor(_selectedStatus),
          //                   borderRadius: BorderRadius.circular(40),
          //                 ),
          //                 child: Text(
          //                   _selectedStatus,
          //                   style: TextStyle(
          //                     fontSize: 12,
          //                     fontFamily: "Inter",
          //                     fontWeight: FontWeight.bold,
          //                     color: _getStatusTextColor(_selectedStatus),
          //                   ),
          //                 ),
          //               ),
          //               const SizedBox(width: 8),
          //               PopupMenuButton<String>(
          //                 key: _popupKey,
          //                 onSelected: (String selected) async {
          //                   setState(() {
          //                     _selectedStatus = selected;
          //                   });
          //
          //                   try {
          //                     final prefs = await SharedPreferences.getInstance();
          //                     final token = prefs.getString('auth_token');
          //
          //                     if (token == null) {
          //                       ScaffoldMessenger.of(context).showSnackBar(
          //                         const SnackBar(
          //                           content: Text("Authentication token not found"),
          //                           backgroundColor: Colors.red,
          //                         ),
          //                       );
          //                       return;
          //                     }
          //
          //                     final url = Uri.parse(
          //                       'https://api.skillsconnect.in/dcxqyqzqpdydfk/api/job/dashboard/update-application-status',
          //                     );
          //
          //                     final body = {
          //                       "job_id": widget.applicantModel.job_id,
          //                       "action": selected,
          //                       "application_id_list": [widget.applicantModel.application_id],
          //                       "process_id": ""
          //                     };
          //
          //                     final response = await http.post(
          //                       url,
          //                       headers: {
          //                         "Content-Type": "application/json",
          //                         "Authorization": "Bearer $token",
          //                       },
          //                       body: jsonEncode(body),
          //                     );
          //
          //                     final decoded = jsonDecode(response.body);
          //                     if (response.statusCode == 200 && decoded["status"] == true) {
          //                       ScaffoldMessenger.of(context).showSnackBar(
          //                         const SnackBar(
          //                           content: Text("Status updated successfully"),
          //                           backgroundColor: Colors.green,
          //                         ),
          //                       );
          //                     } else {
          //                       ScaffoldMessenger.of(context).showSnackBar(
          //                         SnackBar(
          //                           content: Text("Failed: ${decoded['message'] ?? 'Unknown error'}"),
          //                           backgroundColor: Colors.red,
          //                         ),
          //                       );
          //                     }
          //                   } catch (e) {
          //                     ScaffoldMessenger.of(context).showSnackBar(
          //                       SnackBar(
          //                         content: Text("Error: ${e.toString()}"),
          //                         backgroundColor: Colors.red,
          //                       ),
          //                     );
          //                   }
          //                 },
          //                 itemBuilder: (BuildContext context) {
          //                   return _statusOptions.map((status) {
          //                     return PopupMenuItem<String>(
          //                       value: status,
          //                       child: Container(
          //                         width: 160,
          //                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //                         decoration: BoxDecoration(
          //                           color: _getStatusColor(status),
          //                           borderRadius: BorderRadius.circular(30),
          //                         ),
          //                         child: Center(
          //                           child: Text(
          //                             status,
          //                             style: TextStyle(
          //                               fontSize: 12,
          //                               fontWeight: FontWeight.w600,
          //                               color: _getStatusTextColor(status),
          //                             ),
          //                           ),
          //                         ),
          //                       ),
          //                     );
          //                   }).toList();
          //                 },
          //                 padding: EdgeInsets.zero,
          //                 color: Colors.white,
          //                 offset: const Offset(0, 30),
          //                 shape: RoundedRectangleBorder(
          //                   borderRadius: BorderRadius.circular(12),
          //                 ),
          //                 child: const Icon(
          //                   Icons.keyboard_arrow_down,
          //                   color: Colors.white,
          //                   size: 18,
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        );
      },
    );
  }
}





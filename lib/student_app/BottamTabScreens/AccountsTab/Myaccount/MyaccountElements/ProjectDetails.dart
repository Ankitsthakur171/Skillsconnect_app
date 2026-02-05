import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../Model/Internship_Projects_Model.dart';
import 'SectionHeader.dart';
import 'ShimmerWidgets.dart';

bool _snackBarShown = false;

void _showSnackBarOnce(BuildContext context, String message,
    {int cooldownSeconds = 3}) {
  print('🟡 [SnackBar] Request to show: "$message"');

  if (_snackBarShown) {
    print('🟡 [SnackBar] Blocked (cooldown active)');
    return;
  }

  _snackBarShown = true;
  print('🟢 [SnackBar] Displayed');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(fontSize: 13.sp)),
      backgroundColor: Colors.red,
      duration: Duration(seconds: cooldownSeconds),
    ),
  );

  Future.delayed(Duration(seconds: cooldownSeconds), () {
    _snackBarShown = false;
    print('🟢 [SnackBar] Cooldown reset');
  });
}

class ProjectsSection extends StatelessWidget {
  final List<InternshipProjectModel> projects;
  final bool isLoading;
  final VoidCallback onAdd;
  final Function(InternshipProjectModel, int) onEdit;
  final Function(int) onDelete;

  const ProjectsSection({
    super.key,
    required this.projects,
    required this.isLoading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  Future<bool> _hasNetwork() async {
    if (kIsWeb) {
      print('🌐 [Network] Web platform – assuming online');
      return true;
    }

    try {
      print('🌐 [Network] Checking connectivity...');
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));

      final ok =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      print('🌐 [Network] Result = $ok');
      return ok;
    } catch (e) {
      print('❌ [Network] Failed: $e');
      return false;
    }
  }

  Future<void> _handleTap(
      BuildContext context, VoidCallback callback) async {
    print('🖱️ [Tap] Handling tap');

    final ok = await _hasNetwork();
    if (!ok) {
      print('❌ [Tap] Blocked – no internet');
      _showSnackBarOnce(context, "No internet available");
      return;
    }

    print('✅ [Tap] Network OK – executing callback');
    callback();
  }

  @override
  Widget build(BuildContext context) {
    print('🧱 [ProjectsSection] build()');
    print('🧱 isLoading=$isLoading, projects=${projects.length}');

    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Project/Internship Details",
          showAdd: true,
          onAdd: () {
            print('➕ [Add] Add button tapped');
            onAdd();
          },
        ),

        if (isLoading)
          Padding(
            padding: EdgeInsets.all(14.w),
            child: const ProjectShimmer(),
          )
        else if (projects.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            child: Text(
              "No Project/Internship Details available",
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          )
        else
          Column(
            children: List.generate(projects.length, (i) {
              final proj = projects[i];

              print('📦 [ProjectItem] index=$i, type=${proj.type}');

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(top: 8.h),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBCD8DB)),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(5.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF6F7),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            proj.type?.toLowerCase() == 'internship'
                                ? Icons.school
                                : Icons.folder_open,
                            size: 22.w,
                            color: const Color(0xFF005E6A),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proj.projectName ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF005E6A),
                                ),
                              ),
                              Text(
                                '${proj.type ?? 'N/A'} • ${proj.companyName ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Color(0xFF005E6A)),
                          iconSize: 16.w,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            print('✏️ [Edit] Tapped index=$i');
                            _handleTap(
                              context,
                              () => onEdit(proj, i),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          iconSize: 18.w,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            print('🗑️ [Delete] Tapped index=$i');

                            final ok = await _hasNetwork();
                            if (!ok) {
                              print('❌ [Delete] No internet');
                              _showSnackBarOnce(
                                  context, "No internet available");
                              return;
                            }

                            print('⚠️ [Delete] Showing confirmation dialog');

                            final shouldDelete =
                                await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                title:
                                    const Text('Confirm Delete'),
                                content: Text(
                                    'Are you sure you want to delete this ${proj.type}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      print(
                                          '❎ [Delete] Cancelled');
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      print(
                                          '✅ [Delete] Confirmed');
                                      Navigator.pop(context, true);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            print(
                                '🗑️ [Delete] shouldDelete=$shouldDelete');

                            if (shouldDelete == true) {
                              print(
                                  '🔥 [Delete] Executing onDelete($i)');
                              onDelete(i);
                            }
                          },
                        ),
                      ],
                    ),
                    if (proj.duration?.isNotEmpty ?? false)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          'Duration : ${proj.duration}',
                          style: TextStyle(
                            fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                          ),
                        ),
                      ),
                    if (proj.details?.isNotEmpty ?? false)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          'Details : ${proj.details}',
                          style: TextStyle(
                            fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

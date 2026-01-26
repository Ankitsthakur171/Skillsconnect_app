import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../Model/WorkExperience_Model.dart';
import 'SectionHeader.dart';

bool _snackBarShown = false;

void _showSnackBarOnce(BuildContext context, String message,
    {int cooldownSeconds = 3}) {
  if (_snackBarShown) return;
  _snackBarShown = true;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(fontSize: 13.sp)),
      backgroundColor: Colors.red,
      duration: Duration(seconds: cooldownSeconds),
    ),
  );
  Future.delayed(Duration(seconds: cooldownSeconds), () {
    _snackBarShown = false;
  });
}

class WorkExperienceSection extends StatelessWidget {
  final List<WorkExperienceModel> workExperiences;
  final bool isLoading;
  final VoidCallback onAdd;
  final Function(WorkExperienceModel, int) onEdit;
  final Function(int) onDelete;

  const WorkExperienceSection({
    super.key,
    required this.workExperiences,
    required this.isLoading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  Future<bool> _hasNetwork() async {
    if (kIsWeb) return true;
    try {
      final result =
      await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleTap(BuildContext context, VoidCallback callback) async {
    final ok = await _hasNetwork();
    if (!ok) {
      _showSnackBarOnce(context, "No internet available");
      return;
    }
    callback();
  }

  @override
  Widget build(BuildContext context) {
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
        title: "Work Experience",
        showAdd: true,
        onAdd: onAdd,
      ),

      if (isLoading)
        Padding(
          padding: EdgeInsets.all(14.w),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF005E6A)),
              strokeWidth: 3.w,
            ),
          ),
        )
      else if (workExperiences.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          child: Text(
            "No Work Experience available",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        )
      else
        for (int i = 0; i < workExperiences.length; i++)
          Container(
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
                        Icons.home_work,
                        size: 22.w,
                        color: const Color(0xFF005E6A),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        workExperiences[i].organization,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF005E6A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF005E6A)),
                      iconSize: 16.w,
                      onPressed: () => _handleTap(context, () => onEdit(workExperiences[i], i)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: 3.w),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      iconSize: 18.w,
                      onPressed: () async {
                        final ok = await _hasNetwork();
                        if (!ok) {
                         _showSnackBarOnce(context, "No internet available");
                          return;
                        }

                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Confirm Delete'),
                            content: const Text('Are you sure you want to delete this work experience?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          onDelete(i);
                        }
                      },
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'Project Name : ${workExperiences[i].jobTitle}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Duration : ${workExperiences[i].workFromDate} - ${workExperiences[i].workToDate}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Skills : ${workExperiences[i].skills}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Exp : ${workExperiences[i].totalExperienceYears} yrs ${workExperiences[i].totalExperienceMonths} months',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Salary : ${workExperiences[i].salaryInLakhs}.${workExperiences[i].salaryInThousands} LPA',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Details : ${workExperiences[i].jobDescription}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF003840),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

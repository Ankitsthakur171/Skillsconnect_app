import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../Model/BasicEducation_Model.dart';
import '../../../../Model/EducationDetail_Model.dart';
import 'SectionHeader.dart';
import 'ShimmerWidgets.dart';

String _formatMonthYear(String? month, String year) {
  if (year.isEmpty) return 'Not provided';
  if (month == null || month.isEmpty) return year;
  return '$month $year';
}

String _formatGradingDisplay(String? marks, int? gradingType) {
  if (marks == null || marks.isEmpty) return 'Not provided';
  
  if (gradingType == 1) {
    return '$marks';
  } else if (gradingType == 2) {
    return '$marks';
  } else if (gradingType == 3) {
    return '$marks%';
  }
  
  return marks;
}

String _getGradingLabel(int? gradingType) {
  if (gradingType == 1 || gradingType == 2) {
    return 'GPA';
  } else if (gradingType == 3) {
    return 'Percentage';
  }
  return 'Marks';
}

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

class EducationSection extends StatelessWidget {
  final List<EducationDetailModel> educationDetails;
  final List<BasicEducationModel> basicEducationDetails;
  final bool isLoading;
  final VoidCallback onAdd;
  final Function(EducationDetailModel, int) onEdit;
  final Function(int) onDelete;
  final Function(BasicEducationModel, int) onEditBasic;
  final Function(int) onDeleteBasic;

  const EducationSection({
    super.key,
    required this.educationDetails,
    required this.basicEducationDetails,
    required this.isLoading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onEditBasic,
    required this.onDeleteBasic,
  });

  Future<bool> _hasNetwork() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _handleTap(BuildContext context, VoidCallback callback) async {
    final ok = await _hasNetwork();
    if (!ok) {
      _showSnackBarOnce(context, "No internet available");
      return;
    }
    callback();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true);

    final borderColor = const Color(0xFFBCD8DB);
    final accent = const Color(0xFF005E6A);
    final textColor = const Color(0xFF003840);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: "Education Details", showAdd: true, onAdd: onAdd),
        SizedBox(height: 8.h),
        if (isLoading)
          Padding(
            padding: EdgeInsets.all(14.w),
            child: const EducationShimmer(),
          ),
        if (!isLoading && educationDetails.isNotEmpty)
          Column(
            children: educationDetails.asMap().entries.map((entry) {
              final index = entry.key;
              final edu = entry.value;
              return Container(
                margin: EdgeInsets.only(top: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF6F7),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.school_outlined,
                              size: 20.w, color: accent),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            edu.degreeName,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: accent,
                                fontSize: 15.sp),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Color(0xFF005E6A), size: 18,),
                          onPressed: () =>
                              _handleTap(context, () => onEdit(edu, index)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text('Degree: ${edu.courseName ?? 'Not provided'}',
                        style: TextStyle(fontSize: 13.sp, color: textColor)),
                    SizedBox(height: 6.h),
                    Text('Specialization: ${edu.specializationName ?? 'Not provided'}',
                        style: TextStyle(fontSize: 13.sp, color: textColor)),
                    SizedBox(height: 6.h),
                    Text('${_getGradingLabel(edu.gradingType)}: ${edu.marks.isNotEmpty ? _formatGradingDisplay(edu.marks, edu.gradingType) : 'Not provided'}',
                        style: TextStyle(fontSize: 13.sp, color: textColor)),
                    SizedBox(height: 8.h),
                    Text('College: ${edu.collegeMasterName ?? 'Not provided'}',
                        style: TextStyle(fontSize: 13.sp, color: textColor)),
                    SizedBox(height: 4.h),
                    Text(_formatMonthYear(edu.passingMonth, edu.passingYear),
                        style: TextStyle(
                            fontSize: 13.sp, color: textColor, height: 1.4)),
                  ],
                ),
              );
            }).toList(),
          ),
        ...basicEducationDetails.asMap().entries.map((entry) {
          final index = entry.key;
          final b = entry.value;

          final board = (b.boardName.isNotEmpty) ? b.boardName : 'Not provided';
          final marks = (b.marks.isNotEmpty) ? b.marks : 'Not provided';
          final year = _formatMonthYear(null, b.passingYear);

          return Container(
            margin: EdgeInsets.only(top: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF6F7),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                          Icons.school_outlined,
                          size: 20.w, color: accent),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        b.degreeName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: accent,
                            fontSize: 15.sp
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF005E6A), size: 18,),
                      onPressed: () =>
                          _handleTap(context, () => onEditBasic(b, index)),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '$board With $marks % In $year',
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: textColor,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
        if (!isLoading &&
            basicEducationDetails.isEmpty &&
            educationDetails.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 7.h),
            child: Text("No education details found.",
                style: TextStyle(fontSize: 13.sp, color: textColor)),
          ),
      ],
    );
  }
}

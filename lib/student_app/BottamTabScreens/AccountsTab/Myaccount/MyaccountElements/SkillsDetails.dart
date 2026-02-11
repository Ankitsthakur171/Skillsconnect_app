import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../Model/Skiils_Model.dart';
import 'SectionHeader.dart';
import 'ShimmerWidgets.dart';

class SkillsSection extends StatelessWidget {
  final List<SkillsModel> skillList;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onAdd;
  final Function(SkillsModel, String) onDeleteSkill;

  const SkillsSection({
    super.key,
    required this.skillList,
    required this.isLoading,
    required this.onEdit,
    required this.onAdd,
    required this.onDeleteSkill,
  });

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
          title: "Skills",
          showEdit: skillList.isNotEmpty,
          onEdit: onEdit,
          showAdd: skillList.isEmpty,
          onAdd: onAdd,
        ),
        if (isLoading)
          Padding(
            padding: EdgeInsets.all(14.w),
            child: const SkillsShimmer(),
          )
        else if (skillList.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            margin: EdgeInsets.only(top: 7.h),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFBCD8DB)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Wrap(
              spacing: 7.w,
              runSpacing: 7.h,
              children: skillList
                  .expand((skill) => skill.skills
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .map((singleSkill) => Chip(
                label: Text(
                  singleSkill,
                  style: TextStyle(fontSize: 12.sp),
                ),
                // onDeleted: () => onDeleteSkill(skill, singleSkill),
                // deleteIconColor: const Color(0xFF005E6A),
                backgroundColor: const Color(0xFFEBF6F7),
                labelStyle:
                const TextStyle(color: Color(0xFF003840)),
              )))
                  .toList(),
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            child: Text(
              "No Skills available",
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../Model/PersonalDetail_Model.dart';
import 'DetailRow.dart';
import 'SectionHeader.dart';
import 'ShimmerWidgets.dart';

class PersonalDetailsSection extends StatelessWidget {
  final PersonalDetailModel? personalDetail;
  final bool isLoading;
  final VoidCallback onEdit;

  const PersonalDetailsSection({
    super.key,
    required this.personalDetail,
    required this.isLoading,
    required this.onEdit,
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
          title: "Personal Details",
          showEdit: personalDetail != null,
          onEdit: onEdit,
        ),
        isLoading
            ? const PersonalDetailsShimmer()
            : personalDetail == null
            ? Text(
          'No personal details available.',
          style: TextStyle(fontSize: 12.sp),
        )
            : _buildCardBody(
          children: [
            DetailRow(
              icon: Icons.perm_identity_outlined,
              text: '${personalDetail!.firstName} ${personalDetail!.lastName}',
            ),
            DetailRow(icon: Icons.cake_outlined, text: personalDetail!.dateOfBirth),
            DetailRow(icon: Icons.phone_outlined, text: personalDetail!.mobile),
            DetailRow(icon: Icons.message_outlined, text: personalDetail!.whatsAppNumber),
            DetailRow(
              icon: Icons.location_on_outlined,
              text: personalDetail!.state.isEmpty
                  ? 'Not provided'
                  : '${personalDetail!.state}, ${personalDetail!.city}',
            ),
            DetailRow(
              icon: Icons.mark_email_read_outlined,
              text: personalDetail!.email,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardBody({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      margin: EdgeInsets.only(top: 7.h),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBCD8DB)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class DetailRowIconplus extends StatelessWidget {
  final IconData icon;
  final String text;

  const DetailRowIconplus({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Icon(icon, size: 15.w, color: const Color(0xFF005E6A)),
          SizedBox(width: 11.w),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}

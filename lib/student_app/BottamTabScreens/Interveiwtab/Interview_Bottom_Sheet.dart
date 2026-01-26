import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Model/InterviewScreen_Model.dart';

class InOfficeDetailSheet extends StatelessWidget {
  final InterviewModel model;

  final String? meetingMapLink;
  final String? meetingAddress;
  final String? contactPerson;

  const InOfficeDetailSheet({
    super.key,
    required this.model,
    this.meetingMapLink,
    this.meetingAddress,
    this.contactPerson,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF005E6A);

    Future<void> _openUrl(String? url) async {
      if (url == null || url.trim().isEmpty) return;
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    Widget _row(String title, String? value, {bool selectable = false}) {
      final text = (value == null || value.trim().isEmpty) ? '—' : value.trim();
      final labelStyle = TextStyle(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF003840),
        fontSize: 13.sp,
      );
      final valueStyle = TextStyle(color: Colors.black87, fontSize: 13.sp);
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: labelStyle),
            SizedBox(height: 4.h),
            selectable
                ? SelectableText(text, style: valueStyle)
                : Text(text, style: valueStyle),
          ],
        ),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.7,
      maxChildSize: 0.7,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
          ),
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 12.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12.h,
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                'Interview Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: accent,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF6F7),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFBCD8DB), width: 0.8.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Interview Name', model.jobTitle),
                    _row('Mode', model.meetingMode),
                    _row('Date', model.date),
                    _row('Time', '${model.startTime} - ${model.endTime}'),
                    _row('Meeting Address', meetingAddress, selectable: true),
                    _row('Contact Person', contactPerson, selectable: true),
                    SizedBox(height: 12.h),
                    if ((meetingMapLink ?? '').isNotEmpty)
                      Center(
                        child: SizedBox(
                          width: 160.h,
                          child: ElevatedButton.icon(
                            onPressed: () => _openUrl(meetingMapLink),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            icon: const Icon(Icons.map, color: Colors.white),
                            label: const Text(
                                'Open Map Link',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    SizedBox(width: 10.h,),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              Center(
                child: SizedBox(
                  width: 120.h,
                  height: 40.h,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

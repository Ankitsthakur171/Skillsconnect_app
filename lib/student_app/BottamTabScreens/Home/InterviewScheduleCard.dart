import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../Model/Dashboard_Model.dart';
import '../../Utilities/JoinInterviewApi.dart';

class InterviewScheduleCard extends StatefulWidget {
  final InterviewScheduleItem interview;
  final VoidCallback? onViewDetails;

  const InterviewScheduleCard({
    super.key,
    required this.interview,
    this.onViewDetails,
  });

  @override
  State<InterviewScheduleCard> createState() => _InterviewScheduleCardState();
}

class _InterviewScheduleCardState extends State<InterviewScheduleCard> {
  bool _isJoining = false;

  // Helper function to format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Helper function to format time to 12-hour format
  String _formatTime(String timeString) {
    try {
      final time = DateFormat('HH:mm').parse(timeString);
      return DateFormat('hh:mm a').format(time);
    } catch (e) {
      return timeString;
    }
  }

  void _joinMeeting() async {
    if (widget.interview.meetingLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting link not available')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final result = await JoinInterviewApi.joinInterview(
        meetingId: widget.interview.id.toString(),
      );

      final url = result.ok && result.url != null && result.url!.isNotEmpty
          ? result.url!
          : widget.interview.meetingLink;

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Cannot join meeting')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining meeting: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(right: 14.w, bottom: 10.h),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        width: 300.w,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: 52.w,
                    height: 52.h,
                    color: Colors.grey[200],
                    child: widget.interview.companyLogo.isNotEmpty
                        ? Image.network(
                            widget.interview.companyLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business,
                              size: 26.sp,
                              color: Colors.grey[600],
                            ),
                          )
                        : Icon(
                            Icons.business,
                            size: 26.sp,
                            color: Colors.grey[600],
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.interview.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF1A73E8),
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.interview.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            /// Interview name
            Text(
              widget.interview.interviewName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 5.h),

            /// Date & time
            Text(
              '${_formatDate(widget.interview.interviewDate)} , ${_formatTime(widget.interview.startTime)} - ${_formatTime(widget.interview.endTime)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[800],
              ),
            ),

            SizedBox(height: 6.h),
            Divider(thickness: 0.7, color: Colors.grey.withOpacity(0.3)),
            SizedBox(height: 6.h),

            /// Mode badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: widget.interview.meetingMode == 'online'
                    ? const Color(0xFF34A853).withOpacity(0.12)
                    : Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                widget.interview.meetingMode == 'online'
                    ? '🌐 Online'
                    : '📍 ${widget.interview.meetingMode}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.interview.meetingMode == 'online'
                      ? const Color(0xFF34A853)
                      : Colors.orange[700],
                ),
              ),
            ),

            SizedBox(height: 8.h),

            /// Buttons
            if (widget.interview.meetingMode == 'offline' || widget.interview.meetingMode == 'in-office')
              // Offline/In-office: Only View Details button in center
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onViewDetails,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    side: const BorderSide(
                      color: Color(0xFF1A73E8),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: const Color(0xFF1A73E8),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              )
            else
              // Online: Both View Details and Join buttons side by side
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onViewDetails,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        side: const BorderSide(
                          color: Color(0xFF1A73E8),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: const Color(0xFF1A73E8),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : _joinMeeting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        disabledBackgroundColor: Colors.grey[400],
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: _isJoining
                          ? SizedBox(
                              height: 16.h,
                              width: 16.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Join',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
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

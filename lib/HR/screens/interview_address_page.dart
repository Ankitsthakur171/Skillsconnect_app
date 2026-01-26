import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/interview_bottom.dart';

class MeetingDetailsPage extends StatelessWidget {
  final ScheduledMeeting meeting;

  const MeetingDetailsPage({super.key, required this.meeting});

  // 🔹 Map link open karne ke liye function
  Future<void> _openMapLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $url";
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // fixed label width for alignment
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF005E6A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "—",
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF005E6A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Meeting Details",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 Header (Logo + Name)
            Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (meeting.companyLogo != null &&
                      meeting.companyLogo!.isNotEmpty)
                      ? NetworkImage(meeting.companyLogo!)
                      : null,
                  child: (meeting.companyLogo == null ||
                      meeting.companyLogo!.isEmpty)
                      ? const Icon(Icons.business,
                      size: 45, color: Color(0xFF005E6A))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  meeting.companyName ?? "No Company",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003840),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 🔹 Details Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildInfoRow("Job Title", meeting.jobTitle),
                    _buildInfoRow("Interview Name", meeting.interviewName),
                    _buildInfoRow("Contact Person", meeting.contactPerson),
                    _buildInfoRow("Location", meeting.meetingAddress),
                    _buildInfoRow("Date", meeting.formattedInterviewDate),
                    _buildInfoRow("InterView Time", "${meeting.formattedStartTime} to ${meeting.formattedEndTime}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Full Width Map Button
            // if (meeting.meetingmaplink != null &&
            //     meeting.meetingmaplink!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openMapLink(meeting.meetingmaplink!),
                  icon: const Icon(Icons.location_on_outlined, color: Colors.white),
                  label: const Text(
                    "Open in Maps",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005E6A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

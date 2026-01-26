import 'package:flutter/material.dart';
import 'package:skillsconnect/TPO/Model/tpo_applicant_details_model.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this in pubspec.yaml

class InterViewScreen extends StatelessWidget {
  final List<TpoVideoIntroduction> videoList;

  const InterViewScreen({super.key, required this.videoList});

  @override
  Widget build(BuildContext context) {
    if (videoList.isEmpty) return const SizedBox.shrink();

    final videos = videoList.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFFEAF6F7),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildVideoTiles(videos),
        ),
      ),
    );
  }

  List<Widget> _buildVideoTiles(TpoVideoIntroduction video) {
    final List<Map<String, String?>> items = [
      {'title': 'About Yourself', 'url': video.aboutYourself},
      {'title': 'Organize Your Day', 'url': video.organizeYourDay},
      {'title': 'Your Strength', 'url': video.yourStrength},
      {'title': 'Taught Yourself Lately', 'url': video.taughtYourselfLately},
    ];

    return items
        .where((item) => item['url'] != null && item['url']!.isNotEmpty)
        .map(
          (item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/videocam.png', height: 16, width: 16),
                const SizedBox(width: 6),
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(item['url']!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                height: 161,
                width: 285,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Future enhancement: show video preview
                    Container(
                      color: const Color(0xFFCCCCCC),
                    ),
                    Image.asset(
                      'assets/play_button.png',
                      height: 40,
                      width: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .toList();
  }
}

import 'package:flutter/material.dart';

import '../Model/tpo_applicant_details_model.dart';

class TpoCvCardProject extends StatelessWidget {
  final List<TpoProject> projectList;

  const TpoCvCardProject({Key? key, required this.projectList}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffEBF6F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: projectList.map((project) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Internship / Project type with icon
                Row(
                  children: [
                    Image.asset(
                      "assets/project.png",
                      width: 18,
                      height: 18,
                      color: const Color(0xff003840),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      project.type.isNotEmpty ? project.type : "Internship",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff003840),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 🔹 Content block (Company, Project, Duration, Details, Skills)
                Padding(
                  padding: const EdgeInsets.only(left: 26), // icon ke niche indent
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow("Company Name:", project.company_name),
                      _buildRow("Project Name:", project.project_name),
                      _buildRow("Duration:", "${project.internship_duration} month"),
                      if (project.details.isNotEmpty)
                        _buildRow("Details:", project.details),
                      if (project.skills.isNotEmpty)
                        _buildRow("Skills:", project.skills),
                      const SizedBox(height: 6,)
                    ],
                  ),
                ),

              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xff003840),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 14,
                // fontWeight: FontWeight.w500,
                color: Color(0xff003840),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:skillsconnect/HR/model/applicant_details_model.dart';
//
// class CvCardProject extends StatelessWidget {
//   final List<Project> projectList;
//
//   const CvCardProject({Key? key, required this.projectList}) : super(key: key);
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: const Color(0xffEBF6F7),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(6),
//         child: Column(
//           children: projectList.map((project) {
//             return Column(
//               children: [
//                 _buildProjectRow(
//                   "assets/project.png",
//                   wrapAfterWords(project.project_name.isNotEmpty ? project.project_name : "Project Name" , 5),
//                   wrapAfterWords(project.skills,5),
//                 wrapAfterWords(project.company_name,5 ),
//                 ),
//
//                 const SizedBox(height: 16),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProjectRow(String iconPath, String title, String skills, String company_name, ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Checkbox
//           const SizedBox(width: 8),
//           // Icon and text column
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Image.asset(
//                       iconPath,
//                       width: 16,
//                       height: 16,
//                       color: const Color(0xff003840),
//                     ),
//                     const SizedBox(width: 10),
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xff003840),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 26), // Align with text above
//                   child: Text(
//                     '$skills by $company_name',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Color(0xff005E6A),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// String wrapAfterWords(String text, int wordLimit) {
//   final words = text.split(' ');
//   if (words.length <= wordLimit) return text;
//
//   final buffer = StringBuffer();
//   for (int i = 0; i < words.length; i++) {
//     buffer.write(words[i]);
//     buffer.write(' ');
//     if ((i + 1) % wordLimit == 0 && i != words.length - 1) {
//       buffer.write('\n'); // insert newline after 5 words
//     }
//   }
//   return buffer.toString().trim();
// }






import 'package:flutter/material.dart';
import 'package:skillsconnect/HR/model/applicant_details_model.dart';

class CvCardProject extends StatelessWidget {
  final List<Project> projectList;

  const CvCardProject({Key? key, required this.projectList}) : super(key: key);

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

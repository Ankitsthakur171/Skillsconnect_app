// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../model/applicant_details_model.dart';
//
// class CvCardExperience extends StatelessWidget {
//   final List<Experience> experienceList;
//
//   const CvCardExperience({super.key, required this.experienceList});
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
//           children: experienceList.map((exp) {
//             String duration = _calculateDuration(exp.fromDate, exp.toDate);
//             return Column(
//               children: [
//                 _buildEducationRow(
//                   "assets/bag.png",
//                   exp.jobTitle,
//                   exp.organization,
//                   "${exp.fromDate} – ${exp.toDate} $duration",
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
//
//   String _calculateDuration(String from, String to) {
//     try {
//       DateFormat format = DateFormat("MMM-yyyy"); // Expects: Mar-2022
//       DateTime fromDate = format.parse(from);
//       DateTime toDate = format.parse(to);
//
//       int years = toDate.year - fromDate.year;
//       int months = toDate.month - fromDate.month;
//
//       if (months < 0) {
//         years -= 1;
//         months += 12;
//       }
//
//       String yearStr = years > 0 ? "$years year${years > 1 ? 's' : ''}" : "";
//       String monthStr = months > 0 ? "$months month${months > 1 ? 's' : ''}" : "";
//
//       return "(${[yearStr, monthStr].where((e) => e.isNotEmpty).join(' ')})";
//     } catch (e) {
//       return "";
//     }
//   }
//
//   Widget _buildEducationRow(String iconPath, String title, String institute, String year) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(width: 8),
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
//                     Flexible(
//                       child: Text(
//                         title,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Color(0xff003840),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 6),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 26),
//                   child: Text(
//                     institute,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Color(0xff003840),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 26),
//                   child: Text(
//                     year,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Color(0xff003840),
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









import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/applicant_details_model.dart';

class CvCardExperience extends StatelessWidget {
  final List<Experience> experienceList;

  const CvCardExperience({super.key, required this.experienceList});

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
          children: experienceList.map((exp) {
            String duration = _calculateDuration(exp.fromDate, exp.toDate);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Company Name with 📌 icon
                Row(
                  children: [
                    Image.asset(
                      "assets/bag.png",
                      width: 18,
                      height: 18,
                      color: const Color(0xff003840),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "Company Name: ",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold, // Sirf ye bold hoga
                                color: Color(0xff003840),
                              ),
                            ),
                            TextSpan(
                              text: exp.organization, // API se data
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.normal, // Normal text
                                color: Color(0xff003840),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),


                const SizedBox(height: 6),
                _buildDetailRow("Role:", exp.jobTitle),
                _buildDetailRow("Duration:", "${exp.fromDate} – ${exp.toDate} $duration"),
                if (exp.jobdescription.isNotEmpty)
                  _buildDetailRow("Details:", exp.jobdescription),
                if (exp.skills.isNotEmpty)
                  _buildDetailRow("Skills:", exp.skills),

              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _calculateDuration(String from, String to) {
    try {
      DateFormat format = DateFormat("MMM-yyyy"); // Expects: Mar-2022
      DateTime fromDate = format.parse(from);
      DateTime toDate = format.parse(to);

      int years = toDate.year - fromDate.year;
      int months = toDate.month - fromDate.month;

      if (months < 0) {
        years -= 1;
        months += 12;
      }

      String yearStr = years > 0 ? "$years year${years > 1 ? 's' : ''}" : "";
      String monthStr = months > 0 ? "$months month${months > 1 ? 's' : ''}" : "";

      return "(${[yearStr, monthStr].where((e) => e.isNotEmpty).join(' ')})";
    } catch (e) {
      return "";
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, bottom: 4),
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
                fontWeight: FontWeight.w500,
                color: Color(0xff005E6A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

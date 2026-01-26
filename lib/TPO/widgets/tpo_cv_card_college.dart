
import 'package:flutter/material.dart';
import 'package:skillsconnect/TPO/Model/tpo_applicant_details_model.dart';

class TpoCvCardCollege extends StatelessWidget {
  final List<Education> educationList;
  final List<BasicEducation> basicEducationList;

  const TpoCvCardCollege({
    Key? key,
    required this.educationList,
    required this.basicEducationList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffEBF6F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            ...educationList.map(
                  (edu) => Column(
                children: [
                  _buildEducationRow(
                    "assets/institute.png",
                    edu, // pura object bhej rahe
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            ...basicEducationList.map(
                  (edu) => Column(
                children: [
                  _buildBasicEducationRow(
                    "assets/institute.png",
                    edu,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Degree + Course + Specialization (degree_name bold)
  Widget _buildEducationRow(String iconPath, Education edu) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      iconPath,
                      width: 16,
                      height: 16,
                      color: const Color(0xff003840),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            // 👇 Sirf degree_name bold
                            TextSpan(
                              text: edu.degreeOnly,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff003840),
                              ),
                            ),
                            TextSpan(
                              text:
                              " - ${edu.coursename} in ${edu.specializationName} | ${edu.marks} ${edu.grade}", // 👈 ye normal
                              style: const TextStyle(
                                fontSize: 14,
                                // fontWeight: FontWeight.w500,
                                color: Color(0xff003840),
                              ),
                            ),
                            const TextSpan(text: "\n"),
                            TextSpan(
                              text: edu.instituteName,
                              style: const TextStyle(
                                fontSize: 14,
                                // fontWeight: FontWeight.w500,
                                color: Color(0xff003840),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Basic education (degree_name bold)
  Widget _buildBasicEducationRow(String iconPath, BasicEducation edu) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      iconPath,
                      width: 16,
                      height: 16,
                      color: const Color(0xff003840),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: edu.degreeName, // bold sirf degree
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff003840),
                              ),
                            ),
                            const TextSpan(text: "\n"),
                            TextSpan(
                              text: edu.boardName,
                              style: const TextStyle(
                                fontSize: 14,
                                // fontWeight: FontWeight.w500,
                                color: Color(0xff003840),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

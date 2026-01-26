import 'package:flutter/material.dart';
import '../model/applicant_details_model.dart';

class CvCardCertification extends StatelessWidget {
  final List<Certifications> certifications;

  const CvCardCertification({
    Key? key,
    required this.certifications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (certifications.isEmpty) {
      return const SizedBox.shrink(); // nothing to show
    }

    return Card(
      color: const Color(0xffEBF6F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: List.generate(certifications.length, (index) {
            final cert = certifications[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row(
                //   children: [
                //     Image.asset(
                //       "assets/note.png",
                //       width: 18,
                //       height: 18,
                //       color: const Color(0xff003840),
                //     ),
                //     const SizedBox(width: 8),
                //     RichText(
                //       text: TextSpan(
                //         text: "Certificate Name: ",
                //         style: const TextStyle(
                //           fontSize: 14,
                //           fontWeight: FontWeight.w600, // ✅ label bold
                //           color: Color(0xff003840),
                //         ),
                //         children: [
                //           TextSpan(
                //             text: cert.certificateName,
                //             style: const TextStyle(
                //               fontWeight: FontWeight.normal, // ✅ value normal
                //               color: Color(0xff003840),
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // helps align multi-line nicely
                  children: [
                    Image.asset(
                      "assets/note.png",
                      width: 18,
                      height: 18,
                      color: const Color(0xff003840),
                    ),
                    const SizedBox(width: 8),

                    // ⬇️ WRAP IN Expanded so long text can wrap to next line(s)
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "Certificate Name: ",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff003840),
                          ),
                          children: [
                            TextSpan(
                              text: cert.certificateName,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Color(0xff003840),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.left,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: "Organization Name: ",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600, // ✅ label bold
                            color: Color(0xff003840),
                          ),
                          children: [
                            TextSpan(
                              text: cert.issuedOrgName,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal, // ✅ value normal
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          text: "Date: ",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600, // ✅ label bold
                            color: Color(0xff003840),
                          ),
                          children: [
                            TextSpan(
                              text: "${cert.issueDate} – ${cert.expireDate}",
                              style: const TextStyle(
                                fontWeight: FontWeight.normal, // ✅ value normal
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cert.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            text: "Description: ",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600, // ✅ label bold
                              color: Color(0xff003840),
                            ),
                            children: [
                              TextSpan(
                                text: cert.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal, // ✅ value normal
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // gap between multiple certificates
                if (index != certifications.length - 1)
                  const SizedBox(height: 8),
              ],
            );
          }),
        ),
      ),
    );
  }
}

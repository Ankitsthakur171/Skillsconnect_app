import 'package:flutter/material.dart';

import '../Model/tpo_applicant_details_model.dart';


class CvdetailsCard extends StatelessWidget {
  final TPOApplicant applicant;

  const CvdetailsCard({Key? key, required this.applicant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xffEBF6F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(

          children: [
            if (applicant.dob.isNotEmpty)
              _buildRow('assets/cake.png', applicant.dob),
            if (applicant.tpoeducationList.first.coursename.isNotEmpty)
              _buildRow('assets/bag.png', applicant.tpoeducationList.first.coursename),
            if (applicant.email.isNotEmpty)
              _buildRow('assets/mail.png', applicant.email),
            if (applicant.appliedate.isNotEmpty)
              _buildRow('assets/appliedate.png'," ${applicant.appliedate} (applied date)"),
            // if (applicant.phone.isNotEmpty)
            //   _buildRow('assets/phone1.png', applicant.phone),
            if ((applicant.cityname?.isNotEmpty ?? false) || (applicant.statename?.isNotEmpty ?? false))
              _buildRow(
                'assets/location.png',
                '${applicant.cityname ?? ''} ${applicant.statename ?? ''}'.trim(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String iconPath, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // aligns top for multiline
        children: [
          Image.asset(
            iconPath,
            width: 16,
            height: 16,
            color: const Color(0xff003840),
          ),
          const SizedBox(width: 10),
          Expanded( // Makes the text wrap
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xff003840),
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

}

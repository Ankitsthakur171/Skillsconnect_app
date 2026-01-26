import 'package:flutter/material.dart';

import '../model/applicant_details_model.dart';


class DetailSection extends StatelessWidget {
  final Applicant applicant;
  const DetailSection({required this.applicant});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(leading: const Icon(Icons.work), title: Text(applicant.designation)),
        ListTile(leading: const Icon(Icons.email), title: Text(applicant.email)),
        ListTile(leading: const Icon(Icons.phone), title: Text(applicant.phone)),
        ListTile(leading: const Icon(Icons.location_on), title: Text('${applicant.cityname}, ${applicant.statename}'),
        ),
      ],
    );
  }
}

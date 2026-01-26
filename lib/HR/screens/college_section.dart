import 'package:flutter/material.dart';

class CollegeSection extends StatelessWidget {
  final List<String> education;
  const CollegeSection({required this.education});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('College', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...education.map((e) => ListTile(leading: const Icon(Icons.school), title: Text(e))),
      ],
    );
  }
}

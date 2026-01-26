import 'package:flutter/material.dart';

import '../model/c_innerpage_model.dart';


class CollegeCard extends StatelessWidget {
  final CollegeInfo info;

  const CollegeCard({Key? key, required this.info}) : super(key: key);

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
            _buildRow('assets/institute.png', 'Institute Type', info.instituteType,),
            _buildRow('assets/bag.png', 'NAACs Grades', info.naacGrade),
            _buildRow('assets/year.png', 'Year of establishment', info.establishmentYear),
            _buildRow('assets/person.png', 'Ownership', info.ownership),
            _buildRow('assets/location.png', 'Address', info.address),
          ],
        ),
      ),
    );
  }


  Widget _buildRow(String iconPath, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                iconPath,
                width: 16,
                height: 16,
                color: Color(0xff003840),
              ),              
              SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xff003840)),
              ),
            ],
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, color: Color(0xff003840)),
            ),
          ),
        ],
      ),
    );
  }

}

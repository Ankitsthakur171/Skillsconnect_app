   import 'package:flutter/material.dart';
import '../model/summary_card_model.dart';

class SummaryCard extends StatelessWidget {
  final SummaryCardModel data;
  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Color(0xffe5ebeb),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.asset(data.imageAsset, height: 75, width: 75),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003840),
                  ),
                ),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF003840),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}



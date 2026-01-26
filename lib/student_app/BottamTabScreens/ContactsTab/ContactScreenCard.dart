import 'package:flutter/material.dart';

class ContactscreenCard extends StatelessWidget {
  final String ProfileImageUrl;
  final String title;
  final String College;
  final String location;
  final String time;

  const ContactscreenCard({
    super.key,
    required this.ProfileImageUrl,
    required this.title,
    required this.College,
    required this.location,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = size.width / 360;
    final fontScale = widthScale.clamp(0.9, 1.1);
    final iconSize = 30.0 * fontScale;
    final padding = 16.0 * widthScale;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.0 * fontScale),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(left: padding),
              width: 54 * fontScale,
              height: 54 * fontScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF005E6A), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  ProfileImageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12 * widthScale),

            // Text column
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17 * fontScale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF003840),
                      ),
                    ),
                    SizedBox(height: 2 * widthScale),
                    Text(
                      College,
                      style: TextStyle(
                        fontSize: 15 * fontScale,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF005E6A),
                      ),
                    ),
                    SizedBox(height: 4 * widthScale),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            size: 14 * fontScale,
                            color: const Color(0xFF6A8E92)),
                        SizedBox(width: 4 * widthScale),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 14 * fontScale,
                              color: const Color(0xFF003840),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4 * widthScale),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 13 * fontScale,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6A8E92),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Call icon
            Padding(
              padding: EdgeInsets.only(right: padding),
              child: GestureDetector(
                onTap: () {},
                child: Icon(
                  Icons.call_outlined,
                  color: const Color(0xFF007B84),
                  size: iconSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

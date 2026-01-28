import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../AccountsTab/Myaccount/MyAccount.dart';

class ProfileCompletionCard extends StatelessWidget {
  final int completionPercentage;

  const ProfileCompletionCard({
    super.key,
    required this.completionPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = completionPercentage >= 100;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.6.w),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Subtitle
              Text(
                isComplete ? 'Profile looks complete' : 'Complete your profile',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF003840),
                ),
              ),
              SizedBox(height: 8.h),
              
              // Description
              if (!isComplete)
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                    children: [
                      const TextSpan(text: 'Your profile is '),
                      TextSpan(
                        text: '$completionPercentage%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        ),
                      ),
                      const TextSpan(text: ' complete. Complete it to improve matching and eligibility.'),
                    ],
                  ),
                )
              else
                Text(
                  'Great! Your profile information is all set.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              
              if (!isComplete) ...[
                SizedBox(height: 12.h),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: completionPercentage / 100,
                    minHeight: 6.h,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF34A853),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                
                // Progress percentage
                Text(
                  '$completionPercentage% complete',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF34A853),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              
              SizedBox(height: 14.h),
              
              // Button
              SizedBox(
                width: double.infinity,
                height: 42.h,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyAccount(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    side: const BorderSide(
                      color: Color(0xFF0D9488),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    isComplete ? 'View Profile' : 'Complete Profile',
                    style: TextStyle(
                      color: const Color(0xFF0D9488),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

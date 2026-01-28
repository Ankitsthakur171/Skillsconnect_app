import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../Model/Dashboard_Model.dart';

class DashboardHeaderSection extends StatelessWidget {
  final ProfileInfo profile;
  final DashboardStats stats;
  final ApplicationItem? latestApplication;
  final VoidCallback? onViewLatestApplication;

  const DashboardHeaderSection({
    super.key,
    required this.profile,
    required this.stats,
    this.latestApplication,
    this.onViewLatestApplication,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome and Profile Section
          _buildWelcomeSection(),
          SizedBox(height: 24.h),

          // Stats Cards Row
          _buildStatsCards(),
          SizedBox(height: 24.h),

          // Latest Application Card
          if (latestApplication != null) _buildLatestApplicationCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Welcome text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back ',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                profile.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color.fromARGB(255, 11, 144, 133),
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6.h),
              Text(
                '${profile.stream} • ${profile.year}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),

        // Right side: Profile Completion
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Profile Completion',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: 130.w,
              height: 10.h,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5.r),
                child: LinearProgressIndicator(
                  value: profile.completion / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF22C55E), // Green
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${profile.completion}% complete',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final statsData = [
      {
        'label': 'Open Opportunities',
        'value': stats.applications, // Using as total for now
        'color': const Color(0xFF0D9488), // Teal
      },
      {
        'label': 'My Applications',
        'value': stats.applications,
        'color': const Color(0xFF0D9488), // Teal
      },
      {
        'label': 'Interviews This Week',
        'value': stats.interviewsThisWeek,
        'color': const Color(0xFF0D9488), // Teal
      },
      {
        'label': 'Assessments\nAssigned',
        'value': stats.assessmentsTaken,
        'color': const Color(0xFF0D9488), // Teal
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        final stat = statsData[index];
        return _buildStatCard(
          label: stat['label'] as String,
          value: stat['value'] as int,
          color: stat['color'] as Color,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[800],
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestApplicationCard() {
    final app = latestApplication!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF0D9488), // Teal
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Application',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: const Color(0xFF0D9488),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    app.company.isNotEmpty
                        ? '${app.company} • ${app.role}'
                        : app.role,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF003840),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Status: ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: app.status,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF003840),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' • ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                        TextSpan(
                          text: 'Next: ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: 'Your CV passed the initial screening.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF0D9488),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            GestureDetector(
              onTap: onViewLatestApplication,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFF0D9488),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

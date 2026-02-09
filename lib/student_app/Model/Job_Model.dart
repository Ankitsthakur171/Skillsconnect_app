

import 'package:intl/intl.dart';

class JobModelsd {
  final String jobToken;
  final String jobTitle;
  final String jobType;
  final String company;
  final String location;
  final String salary;
  final String postTime;
  final String expiry;
  final String? endDate;  // end_date from API for calculating days left
  final String? applyType;
  final List<String> tags;
  final String? logoUrl;
  final int recordId;
  final int jobId;
  final String slug;
  final String? applyUrl;

  JobModelsd({
    required this.jobToken,
    required this.jobTitle,
    required this.jobType,
    required this.company,
    required this.location,
    required this.salary,
    required this.postTime,
    required this.expiry,
    required this.tags,
    this.logoUrl,
    required this.recordId,
    required this.jobId,
    required this.slug,
    this.applyUrl,
    this.endDate,
    this.applyType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is JobModelsd &&
              runtimeType == other.runtimeType &&
              jobToken == other.jobToken &&
              jobId == other.jobId;

  @override
  int get hashCode => Object.hash(jobToken, jobId);

  factory JobModelsd.fromJson(Map<String, dynamic> json) {
    final endDate = json['end_date'] as String?;
    if (endDate != null) {
      print('[JobModel.fromJson] Parsed endDate: $endDate for ${json['title'] ?? 'Unknown'}');
    }
    return JobModelsd(
      jobToken: json['job_invitation_token'] ?? json['jobToken'] ?? '',
      jobTitle: json['title'] ?? json['jobTitle'] ?? 'Untitled',
      jobType: json['job_type'] ?? 'TBD',
      company: json['company_name'] ?? json['company'] ?? 'Company N/A',
      location: json['three_cities_name'] ?? json['location'] ?? 'Location N/A',
      salary: json['cost_to_company']?.toString() ?? json['salary'] ?? 'N/A',
      postTime: json['posted_on'] ?? json['created_on'] ?? json['postTime'] ?? 'N/A',
      expiry: json['expiry'] ?? 'N/A',
      tags: (json['skills'] != null && json['skills'] is String)
          ? (json['skills'] as String).split(',').map((e) => e.trim()).toList()
          : List<String>.from(json['tags'] ?? []),
      logoUrl: json['company_logo'] ?? json['logoUrl'],
      recordId: json['id'] ?? 0,
      jobId: json['job_id'] ?? 0,
      slug: (json['job_slug'] as String?) ?? '',
      applyUrl: json['applyUrl'] as String?,
      endDate: endDate,
      applyType: json['apply_type']?.toString() ?? json['applyType']?.toString(),
    );
  }

  bool get isApplied => (applyType ?? '').toLowerCase() == 'applied';

  /// Get formatted end date in "dd MMM yyyy" format, or "Expired" if already passed
  String getTimeLeft() {
    if (endDate == null || endDate!.isEmpty) {
      print('[JobModel] No endDate for job: $jobTitle, endDate: $endDate');
      return 'N/A';
    }
    try {
      final expireTime = DateTime.parse(endDate!);
      final now = DateTime.now();
      if (expireTime.isBefore(now)) {
        return 'Expired';
      }
      // Format as "dd MMM yyyy" (e.g., "15 Jan 2026")
      return DateFormat('dd MMM yyyy').format(expireTime);
    } catch (e) {
      print('[JobModel] Error parsing endDate "$endDate" for job $jobTitle: $e');
      return 'N/A';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'jobToken': jobToken,
      'jobTitle': jobTitle,
      'job_type' : jobType,
      'company': company,
      'location': location,
      'salary': salary,
      'postTime': postTime,
      'expiry': expiry,
      'tags': tags,
      'logoUrl': logoUrl,
      'id': recordId,
      'job_id': jobId,
      'end_date': endDate,
    };
  }
}


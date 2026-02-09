class AppliedJobModel {
  final String token;
  final String title;
  final String companyName;
  final String jobType;
  final String companyLogo;
  final List<String> tags;
  final String postTime;
  final String location;
  final String salary;
  final String expiry;
  final String? endDate;
  final int jobId;

  AppliedJobModel({
    required this.jobId,
    required this.token,
    required this.title,
    required this.companyName,
    required this.jobType,
    required this.companyLogo,
    required this.tags,
    required this.postTime,
    required this.location,
    required this.salary,
    required this.expiry,
    this.endDate,
  });

  factory AppliedJobModel.fromJson(Map<String, dynamic> json) {
    final postTime = (json['posted_on'] ??
        json['created_on'] ??
        json['postTime'] ??
        json['createdAt'] ??
        json['postedOn'] ??
        '')
      .toString();
    final endDate = (json['end_date'] ??
        json['endDate'] ??
        json['expiry_date'] ??
        json['deadline'] ??
        '')
      .toString();
    final expiryRaw =
      (json['expiry'] ?? json['end_date'] ?? json['endDate'] ?? '').toString();

    return AppliedJobModel(
      jobId: json['job_id'] ?? '',
      token: json['job_invitation_token'] ?? '',
      title: json['title'] ?? '',
      companyName: json['company_name'] ?? '',
      jobType: json['job_type'] ?? '',
      companyLogo: json['company_logo'] ?? '',
      tags: (json['skills'] as String?)?.split(',') ?? [],
      postTime: postTime,
      location: json['three_cities_name'] ?? '',
      salary: json['cost_to_company']?.toString() ?? '',
      expiry: expiryRaw,
      endDate: endDate.isNotEmpty ? endDate : null,
    );
  }
}

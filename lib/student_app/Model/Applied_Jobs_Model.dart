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
  });

  factory AppliedJobModel.fromJson(Map<String, dynamic> json) {
    final createdOn = DateTime.tryParse(json['created_on'] ?? '') ?? DateTime.now();
    final now = DateTime.now();
    final diff = now.difference(createdOn);
    final postTime = diff.inMinutes < 60
        ? '${diff.inMinutes} mins ago'
        : diff.inHours < 24
        ? '${diff.inHours} hr ago'
        : '${diff.inDays} days ago';

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
      expiry: json['expiry'] ?? '',
    );
  }
}

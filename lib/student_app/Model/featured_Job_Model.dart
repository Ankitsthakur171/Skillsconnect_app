class FeaturedJob {
  final int jobId;
  final String jobName;
  final String companyName;
  final int salaryMin;
  final int salaryMax;
  final String companyLogo;
  final String postedOn;

  FeaturedJob({
    required this.jobId,
    required this.jobName,
    required this.companyName,
    required this.salaryMin,
    required this.salaryMax,
    required this.companyLogo,
    required this.postedOn,
  });

  factory FeaturedJob.fromJson(Map<String, dynamic> json) {
    return FeaturedJob(
      jobId: json['job_id'] ?? 0,
      jobName: json['job_name'] ?? 'Unknown Job',
      companyName: json['company_name'] ?? 'Unknown Company',
      salaryMin: json['salary_min'] ?? 0,
      salaryMax: json['salary_max'] ?? 0,
      companyLogo: json['company_logo'] ?? '',
      postedOn: json['posted_on'] ?? '',
    );
  }
}

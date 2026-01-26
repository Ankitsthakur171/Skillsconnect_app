class PopularJob {
  final int jobId;
  final String jobName;
  final String companyName;
  final int salaryMin;
  final int salaryMax;
  final String companyLogo;
  final String postedOn;

  PopularJob({
    required this.jobId,
    required this.jobName,
    required this.companyName,
    required this.salaryMin,
    required this.salaryMax,
    required this.companyLogo,
    required this.postedOn,
  });

  factory PopularJob.fromJson(Map<String, dynamic> json) {
    return PopularJob(
      jobId: json['job_id'],
      jobName: json['job_name'],
      companyName: json['company_name'],
      salaryMin: json['salary_min'],
      salaryMax: json['salary_max'],
      companyLogo: json['company_logo'],
      postedOn: json['posted_on'],
    );
  }
}

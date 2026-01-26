

class JobModelsd {
  final String jobToken;
  final String jobTitle;
  final String jobType;
  final String company;
  final String location;
  final String salary;
  final String postTime;
  final String expiry;
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
    return JobModelsd(
      jobToken: json['job_invitation_token'] ?? json['jobToken'] ?? '',
      jobTitle: json['title'] ?? json['jobTitle'] ?? 'Untitled',
      jobType: json['job_type'] ?? 'TBD',
      company: json['company_name'] ?? json['company'] ?? 'Company N/A',
      location: json['three_cities_name'] ?? json['location'] ?? 'Location N/A',
      salary: json['cost_to_company']?.toString() ?? json['salary'] ?? 'N/A',
      postTime: json['created_on'] ?? json['postTime'] ?? 'N/A',
      expiry: json['expiry'] ?? 'N/A',
      tags: (json['skills'] != null && json['skills'] is String)
          ? (json['skills'] as String).split(',').map((e) => e.trim()).toList()
          : List<String>.from(json['tags'] ?? []),
      logoUrl: json['company_logo'] ?? json['logoUrl'],
      recordId: json['id'] ?? 0,
      jobId: json['job_id'] ?? 0,
      slug: (json['job_slug'] as String?) ?? '',
      applyUrl: json['applyUrl'] as String?,
    );
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
    };
  }
}


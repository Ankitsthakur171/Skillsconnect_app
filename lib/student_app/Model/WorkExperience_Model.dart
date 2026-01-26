class WorkExperienceModel {
  final String? workExperienceId;
  final String jobTitle;
  final String organization;
  final String skills;
  final String workFromDate;
  final String workToDate;
  final String totalExperienceYears;
  final String totalExperienceMonths;
  final String salaryInLakhs;
  final String salaryInThousands;
  final String jobDescription;
  final String exStartMonth;
  final String exStartYear;
  final String exEndMonth;
  final String exEndYear;

  WorkExperienceModel({
    this.workExperienceId,
    required this.jobTitle,
    required this.organization,
    required this.skills,
    required this.workFromDate,
    required this.workToDate,
    required this.totalExperienceYears,
    required this.totalExperienceMonths,
    required this.salaryInLakhs,
    required this.salaryInThousands,
    required this.jobDescription,
    required this.exStartMonth,
    required this.exStartYear,
    required this.exEndMonth,
    required this.exEndYear,
  });

  factory WorkExperienceModel.fromJson(Map<String, dynamic> json) {
    return WorkExperienceModel(
      workExperienceId: json['id']?.toString(),
      jobTitle: json['job_title'] ?? '',
      organization: json['organization'] ?? '',
      skills: json['skills'] ?? '',
      workFromDate: json['work_from_date'] ?? '',
      workToDate: json['work_to_date'] ?? '',
      totalExperienceYears: json['total_experience_year'] ?? '',
      totalExperienceMonths: json['total_experience_months'] ?? '',
      salaryInLakhs: json['salary_in_lacs'] ?? '',
      salaryInThousands: json['salary_in_thousands'] ?? '',
      jobDescription: json['job_description'] ?? '',
      exStartMonth: json['exStartMonth'] ?? '',
      exStartYear: json['exStartYear'] ?? '',
      exEndMonth: json['exEndMonth'] ?? '',
      exEndYear: json['exEndYear'] ?? '',
    );
  }

  Map<String, dynamic> toJson({bool isNew = false}) {
    final Map<String, dynamic> data = {
      if (!isNew && workExperienceId != null)
        'workExperienceId': workExperienceId,
      'organization': organization,
      'job_title': jobTitle,
      'skills': skills,
      'salary_in_lacs': salaryInLakhs,
      'salary_in_thousands': salaryInThousands,
      'exStartMonth': exStartMonth,
      'exStartYear': exStartYear,
      'exEndMonth': exEndMonth,
      'exEndYear': exEndYear,
      'total_experience_year': totalExperienceYears,
      'total_experience_months': totalExperienceMonths,
      'job_description': jobDescription,
      "work_from_date" : workFromDate,
      "work_to_date" : workToDate
    };
    return data;
  }
}

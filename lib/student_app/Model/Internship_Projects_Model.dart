class InternshipProjectModel {
  final String? internshipId;
  final String? userId;
  final String type;
  final String projectName;
  final String companyName;
  final String skills;
  final String duration;
  final String durationPeriod;
  final String details;

  InternshipProjectModel({
    this.internshipId,
    this.userId,
    required this.type,
    required this.projectName,
    required this.companyName,
    required this.skills,
    required this.duration,
    required this.durationPeriod,
    required this.details,
  });

  factory InternshipProjectModel.fromJson(Map<String, dynamic> json) {
    return InternshipProjectModel(
      internshipId: json['project_internship_id']?.toString(),
      userId: json['user_id']?.toString(),
      type: json['type'] ?? '',
      projectName: json['project_name'] ?? '',
      companyName: json['company_name'] ?? '',
      skills: json['skills'] ?? '',
      duration: json['duration']?.toString() ?? '0',
      durationPeriod: json['duration_period'] ?? '',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      if (internshipId != null) 'internship_id': internshipId,
      'type': type,
      'project_name': projectName,
      'company_name': companyName,
      'skills': skills,
      'duration': duration,
      'duration_period': durationPeriod,
      'details': details,
    };
    if (userId != null && userId!.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
  }
}
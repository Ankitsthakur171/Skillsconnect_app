class ResumeModel {
  final String resume;
  final String resumeName;

  ResumeModel({
    required this.resume,
    required this.resumeName,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      resume: json['resume'] ?? '',
      resumeName: json['resume_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resume_url': resume,
      'resume_name': resumeName,
    };
  }
}

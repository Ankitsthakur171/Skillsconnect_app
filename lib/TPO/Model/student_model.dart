class StudentModel {
  final String name;
  final String university;
  final String degree;
  final String grade;
  final String status;
  final String year;
  final String grade_type;
  final int application_id;
  final String application_status;
  final String application_status_textname;
  final String application_status_colorname;
  final int job_id;
  final int user_id;

  StudentModel({
    required this.name,
    required this.university,
    required this.degree,
    required this.grade,
    required this.status,
    required this.year,
    required this.grade_type,
    required this.application_id,
    required this.application_status,
    required this.application_status_textname,
    required this.application_status_colorname,
    required this.job_id,
    required this.user_id,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      name: json['full_name'] ?? '',
      university: json['college_name'] ?? '',
      degree: json['current_degree'] ?? '',
      grade: json['current_marks'] ?? '',
      status: json['application_status_name'] ?? '',
      year: json['current_passing_year'] ?? '',
      grade_type: json['grade_type'] ?? '',
      application_id: json['application_id'] ?? 0,
      application_status: json['application_status_name'] ?? '',
      // CLEAN COLOR VALUES HERE
      application_status_textname:
      (json['application_status_text_color'] ?? '').toString().replaceAll(' !important', ''),
      application_status_colorname:
      (json['application_status_name_color'] ?? '').toString().replaceAll(' !important', ''),
      job_id: json['job_id'] ?? 0,
      user_id: json['user_id'] ?? 0,
    );
  }
}




class ProcessModel {
  final String name;
  final int id;
  final String type;

  ProcessModel({
    required this.name,
    required this.id,
    required this.type,
  });

  factory ProcessModel.fromJson(Map<String, dynamic> json) {
    return ProcessModel(
      name: json['name'] ?? '',
      id: json['id'],
      type: json['type'] ?? '',
    );
  }
}



class CollegeModel {
  final int id;
  final String name;

  CollegeModel({required this.id, required this.name});

  factory CollegeModel.fromJson(Map<String, dynamic> json) {
    return CollegeModel(
      id: json['id'],
      name: json['text'] ?? '',
    );
  }

  @override
  String toString() => name;
}



class ApplicationStage {
  final String name;
  final int id;

  ApplicationStage({required this.name, required this.id});

  factory ApplicationStage.fromJson(Map<String, dynamic> json) {
    return ApplicationStage(
      name: json['name'],
      id: json['application_status_id'],
    );
  }
}

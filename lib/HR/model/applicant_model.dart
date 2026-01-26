
class ApplicantModel {
  final String name;
  final String university;
  final String degree;
  final String grade;
  final String year;
  final String grade_type;
  final int application_id;
  final int job_id;
  final int user_id;
  final String current_course_name;
  late final String application_status;

  ApplicantModel({
    required this.name,
    required this.university,
    required this.degree,
    required this.grade,
    required this.year,
    required this.grade_type,
    required this.application_id,
    required this.job_id,
    required this.user_id,
    required this.current_course_name,
    required this.application_status,
  });

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    return ApplicantModel(
      name: json['full_name'] ?? '',
      university: json['college_name'] ?? '',
      degree: json['current_degree'] ?? '',
      grade: json['current_marks'] ?? '',
      year: json['current_passing_year'] ?? '',
      grade_type: json['grade_type'] ?? '',
      application_id: json['application_id'],
      job_id: json['job_id'],
      user_id: json['user_id'],
      current_course_name: json['current_course_name'] ?? '',
      application_status: json['application_status_name'] ?? '',
    );
  }

  ApplicantModel copyWith({
    String? name,
    String? university,
    String? degree,
    String? grade,
    String? year,
    String? grade_type,
    int? application_id,
    int? job_id,
    int? user_id,
    String? current_course_name,
    String? application_status,
  }) {
    return ApplicantModel(
      name: name ?? this.name,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      grade: grade ?? this.grade,
      year: year ?? this.year,
      grade_type: grade_type ?? this.grade_type,
      application_id: application_id ?? this.application_id,
      job_id: job_id ?? this.job_id,
      user_id: user_id ?? this.user_id,
      current_course_name: current_course_name ?? this.current_course_name,
      application_status: application_status ?? this.application_status,
    );
  }
}

class TotalCv {
  final List<ApplicantModel> applicants;
  final int totalCv;

  TotalCv({
    required this.applicants,
    required this.totalCv,
  });

  factory TotalCv.fromJson(Map<String, dynamic> json) {
    // "data" can be a list or a map depending on backend, adjust accordingly
    final dataList = json['data'] is List ? json['data'] as List : [];

    return TotalCv(
      applicants: dataList.map((e) => ApplicantModel.fromJson(e)).toList(),
      totalCv: (json['totalCv'] != null && json['totalCv'].isNotEmpty)
          ? json['totalCv'][0]['total_cv'] ?? 0
          : 0,
    );
  }
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



class DegreeModel {
  final int id;
  final String name;

  DegreeModel({required this.id, required this.name});

  factory DegreeModel.fromJson(Map<String, dynamic> json) {
    return DegreeModel(
      id: json['id'],
      name: json['degree_name'] ?? '',
    );
  }

  @override
  String toString() => name;
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




class CourseModel {
  final int id;
  final String courseName;

  CourseModel({
    required this.id,
    required this.courseName,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? 0,
      courseName: json['course_name'] ?? '',  // 👈 key API se match ho
    );
  }

  @override
  String toString() => courseName;
}

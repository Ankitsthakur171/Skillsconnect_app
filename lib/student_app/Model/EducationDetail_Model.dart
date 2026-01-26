class EducationDetailModel {
  final int? userId;
  final String marks;
  final int? gradingType;
  final String? passingMonth;
  final String passingYear;
  final int? educationId;
  final String? customCollegeName;
  final String degreeName;
  final String? courseName;
  final String? gradeName;
  final String? grade;
  final String? specializationName;
  final String? collegeMasterName;
  final int? boardType;
  final int? boardId;
  final int? basicEducationId;
  final String? boardName;
  final String? mediumName;
  final String? courseType;

  EducationDetailModel({
    this.userId,
    this.marks = '',
    this.gradingType,
    this.passingMonth,
    required this.passingYear,
    this.educationId,
    this.customCollegeName,
    required this.degreeName,
    this.courseName,
    this.gradeName,
    this.grade,
    this.specializationName,
    this.collegeMasterName,
    this.boardType,
    this.boardId,
    this.basicEducationId,
    this.boardName,
    this.mediumName,
    this.courseType,
  });

  factory EducationDetailModel.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      final s = v.toString();
      return int.tryParse(s);
    }

    return EducationDetailModel(
      userId: parseNullableInt(json['user_id']),
      marks: (json['marks'] ?? '').toString(),
      gradingType: parseNullableInt(json['grading_type'] ?? json['gradingType']),
      passingMonth: json['passing_month']?.toString() ?? json['passingMonth']?.toString(),
      passingYear: (json['passing_year'] ?? json['passingYear'] ?? '').toString(),
      educationId: parseNullableInt(json['educationid'] ?? json['educationId']),
      customCollegeName: json['custom_college_name']?.toString() ?? json['customCollegeName']?.toString(),
      degreeName: (json['degree_name'] ?? json['degreeName'] ?? '').toString(),
      courseName: json['course_name']?.toString() ?? json['course']?.toString(),
      gradeName: json['grade_name']?.toString() ?? json['gradeName']?.toString(),
      grade: json['grade']?.toString(),
      specializationName: (json['specilization_name'] ?? json['specialization_name'] ?? json['specialization'])?.toString(),
      collegeMasterName: (json['clgmastername'] ?? json['college_master_name'] ?? json['collegeName'])?.toString(),
      boardType: parseNullableInt(json['board_type']),
      boardId: parseNullableInt(json['board_id']),
      basicEducationId: parseNullableInt(json['basic_education_id'] ?? json['basicEducationId']),
      boardName: json['board_name']?.toString() ?? json['boardName']?.toString(),
      mediumName: json['medium_name']?.toString() ?? json['mediumName']?.toString(),
      courseType: json['course_type']?.toString() ?? json['courseType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'marks': marks,
      'passing_year': passingYear,
      'degree_name': degreeName,
    };

    if (userId != null) map['user_id'] = userId;
    if (gradingType != null) map['grading_type'] = gradingType;
    if (passingMonth != null) map['passing_month'] = passingMonth;
    if (educationId != null) map['educationid'] = educationId;
    if (customCollegeName != null) map['custom_college_name'] = customCollegeName;
    if (courseName != null) map['course_name'] = courseName;
    if (gradeName != null) map['grade_name'] = gradeName;
    if (grade != null) map['grade'] = grade;
    if (specializationName != null) map['specilization_name'] = specializationName;
    if (collegeMasterName != null) map['clgmastername'] = collegeMasterName;
    if (boardType != null) map['board_type'] = boardType;
    if (boardId != null) map['board_id'] = boardId;
    if (basicEducationId != null) map['basic_education_id'] = basicEducationId;
    if (boardName != null) map['board_name'] = boardName;
    if (mediumName != null) map['medium_name'] = mediumName;
    if (courseType != null) map['course_type'] = courseType;

    return map;
  }
}

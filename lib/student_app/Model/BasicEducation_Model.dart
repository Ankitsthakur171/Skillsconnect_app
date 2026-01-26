class BasicEducationModel {
  final int? userId;
  final String marks;
  final String passingYear;
  final int? boardType;
  final int? boardId;
  final int? basicEducationId;
  final String degreeName;
  final String boardName;
  final String mediumName;

  BasicEducationModel({
    this.userId,
    this.marks = '',
    this.passingYear = '',
    this.boardType,
    this.boardId,
    this.basicEducationId,
    this.degreeName = '',
    this.boardName = '',
    this.mediumName = '',
  });

  factory BasicEducationModel.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      final s = v.toString();
      return int.tryParse(s);
    }

    return BasicEducationModel(
      userId: parseNullableInt(json['user_id']),
      marks: (json['marks'] ?? '').toString(),
      passingYear: (json['passing_year'] ?? '').toString(),
      boardType: parseNullableInt(json['board_type']),
      boardId: parseNullableInt(json['board_id']),
      basicEducationId: parseNullableInt(json['basic_education_id']),
      degreeName: (json['degree_name'] ?? '').toString(),
      boardName: (json['board_name'] ?? '').toString(),
      mediumName: (json['medium_name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'marks': marks,
      'passing_year': passingYear,
      'degree_name': degreeName,
      'board_name': boardName,
      'medium_name': mediumName,
    };

    if (userId != null) map['user_id'] = userId;
    if (boardType != null) map['board_type'] = boardType;
    if (boardId != null) map['board_id'] = boardId;
    if (basicEducationId != null) map['basic_education_id'] = basicEducationId;
    return map;
  }
}

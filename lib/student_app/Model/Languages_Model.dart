class LanguagesModel {
  final int? id;
  final int languageId;
  final String languageName;
  final String proficiency;

  LanguagesModel({
    this.id,
    required this.languageId,
    required this.languageName,
    required this.proficiency,
  });

  factory LanguagesModel.fromJson(Map<String, dynamic> json) {
    return LanguagesModel(
      id: json['id'] as int?,
      languageId: json['language_id'] ?? 0,
      languageName: json['language_name'] ?? '',
      proficiency: json['proficiency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languages': languageId.toString(),
      'language_name': languageName,
      'proficiency': proficiency,
      if (id != null) 'id': id,
    };
  }
}
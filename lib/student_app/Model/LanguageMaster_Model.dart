class LanguageMasterModel {
  final int languageId;
  final String languageName;

  LanguageMasterModel({
    required this.languageId,
    required this.languageName,
  });

  factory LanguageMasterModel.fromJson(Map<String, dynamic> json) {
    print("🔍 Parsing JSON: $json");
    final id = json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()) ?? 0;
    if (id == 0) {
      print("⚠️ Warning: Parsed languageId is 0 for ${json['language_name']}");
    }
    return LanguageMasterModel(
      languageId: id,
      languageName: json['language_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': languageId,
      'language_name': languageName,
    };
  }
}
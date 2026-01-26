class SkillsModel {
  late final String skills;

  SkillsModel({
   required this.skills,
});


  factory SkillsModel.fromJson(Map<String, dynamic> json){
    return SkillsModel(skills: json['skills']);
  }
}

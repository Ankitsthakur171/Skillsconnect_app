
class VideoIntroModel {
  final String aboutYourself;
  final String organizeYourDay;
  final String yourStrength;
  final String taughtYourselfLately;
  final String id;
  final String userId;

  VideoIntroModel({
    required this.id,
    required this.userId,
    required this.aboutYourself,
    required this.organizeYourDay,
    required this.yourStrength,
    required this.taughtYourselfLately,
  });

  factory VideoIntroModel.fromJson(Map<String, dynamic> json) {
    return VideoIntroModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      aboutYourself: json['about_yourself'] ?? '',
      organizeYourDay: json['organize_your_day'] ?? '',
      yourStrength: json['your_strength'] ?? '',
      taughtYourselfLately: json['taught_yourself_tately'] ?? '',
    );
  }
  //
  // Map<String, dynamic> toJson() {
  //   return {
  //       'about_yourself': aboutYourself,
  //       'organize_your_day': organizeYourDay,
  //       'your_strength': yourStrength,
  //       'taught_yourself_tately': taughtYourselfLately
  //   };
  // }
}
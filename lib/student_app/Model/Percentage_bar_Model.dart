class ProfileCompletionModel {
  final String setupPercentage;

  ProfileCompletionModel({required this.setupPercentage});

  factory ProfileCompletionModel.fromJson(Map<String, dynamic> json) {
    try {
      final personalDetails = json['personalDetails'];
      String percentage = '0';

      if (personalDetails is List && personalDetails.isNotEmpty) {
        final firstEntry = personalDetails.first;

        if (firstEntry is Map<String, dynamic>) {
          final setup = firstEntry['setup_percentage'];

          if (setup is int) {
            percentage = setup.toString();
          } else if (setup is String) {
            percentage = setup;
          }
        }
      }

      print("📥 Assigned percentage = $percentage");
      return ProfileCompletionModel(setupPercentage: percentage);
    } catch (e) {
      print("❌ Error parsing ProfileCompletionModel: $e");
      return ProfileCompletionModel(setupPercentage: '0');
    }
  }
}

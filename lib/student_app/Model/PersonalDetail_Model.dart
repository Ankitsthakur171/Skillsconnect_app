class PersonalDetailModel {
  final String firstName;
  final String lastName;
  final String mobile;
  final String whatsAppNumber;
  final String dateOfBirth;
  final String email;
  final String state;
  final String city;

  PersonalDetailModel({
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.whatsAppNumber,
    required this.dateOfBirth,
    required this.email,
    required this.state,
    required this.city,
  });

  factory PersonalDetailModel.fromJson(Map<String, dynamic> json) {
    String rawDate = json['date_of_birth'] ?? '';
    String formattedDate = '';
    if (rawDate.contains('T')) {
      formattedDate = rawDate.split('T')[0];
    } else {
      formattedDate = rawDate;
    }

    return PersonalDetailModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      mobile: json['mobile'] ?? '',
      whatsAppNumber: json['whatsapp_number'] ?? '',
      dateOfBirth: formattedDate,
      email: json['email'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
    );
  }
}
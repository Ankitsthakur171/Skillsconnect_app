class PersonalDetailUpdateRequest {
  final String firstName;
  final String lastName;
  final String mobile;
  final String whatsAppNumber;
  final String dateOfBirth;
  final String email;
  final String state;
  final String city;

  PersonalDetailUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.state,
    required this.city,
  })  : mobile = "0000000000",
        whatsAppNumber = "0000000000",
        email = "placeholder@example.com";

  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "last_name": lastName,
      "mobile": mobile,
      "whatsapp_number": whatsAppNumber,
      "date_of_birth": dateOfBirth,
      "email": email,
      "state": state,
      "city": city,
    };
  }
}

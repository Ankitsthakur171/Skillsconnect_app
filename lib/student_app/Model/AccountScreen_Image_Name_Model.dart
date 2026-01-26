class AcountScreenImageModel {
  final String? userImage;
  final String? firstName;
  final String? lastName;
  final String? age;

  AcountScreenImageModel({
    this.userImage,
    this.firstName,
    this.lastName,
    this.age,
  });

  factory AcountScreenImageModel.fromJson(Map<String, dynamic> json) {
    return AcountScreenImageModel(
      userImage: json['user_image'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      age: json['date_of_birth'],
    );
  }
}

  class ImageUpdateModel {
    final String? userImage;
    final String? firstName;
    final String? lastName;

    ImageUpdateModel({
      this.userImage,
      this.firstName,
      this.lastName
    });

    factory ImageUpdateModel.fromJson(Map<String, dynamic> json) {
      return ImageUpdateModel(
        userImage: json['user_image'],
        firstName: json['first_name'],
        lastName: json['last_name'],
      );
    }
  }

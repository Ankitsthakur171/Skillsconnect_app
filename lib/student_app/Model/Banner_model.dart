class BannerModel {
  final String image;
  final String link;

  BannerModel({
    required this.image,
    required this.link,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      image: json['image'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

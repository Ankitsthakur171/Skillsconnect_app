
class BookmarkModel {
  final String module;
  final int moduleId;
  final bool isBookmarked;

  BookmarkModel({
    required this.module,
    required this.moduleId,
    required this.isBookmarked,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      module: json['module'] ?? '',
      moduleId: json['module_id'] ?? 0,
      isBookmarked: json['is_bookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module': module,
      'module_id': moduleId,
    };
  }
}

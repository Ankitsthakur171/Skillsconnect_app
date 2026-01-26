class AppNotification {
  final int id;
  final String title;
  final String body;
  final String readStatus;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.readStatus,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id'] ?? 0}') ?? 0,
      title: (json['title'] ?? '') as String,
      body: (json['short_description'] ?? '') as String,
      readStatus: (json['read_status'] ?? 'No') as String,
      createdAt: DateTime.tryParse(json['created_on'] ?? '') ?? DateTime.now(),
    );
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? body,
    String? readStatus,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      readStatus: readStatus ?? this.readStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'short_description': body,
      'read_status': readStatus,
      'created_on': createdAt.toIso8601String(),
    };
  }
}

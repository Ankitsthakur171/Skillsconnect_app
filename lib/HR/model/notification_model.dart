class NotificationModel {
  final int id;
  final int fromUserId;
  final int toUserId;
  final String title;
  final String readStatus;
  final String description;
  final String timeAgo;

  NotificationModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.title,
    required this.readStatus,
    required this.description,
    required this.timeAgo,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdTime = DateTime.tryParse(json['created_on'] ?? '')?.toLocal();

    return NotificationModel(
      id: json['id'] ?? 0,
      fromUserId: json['from_user_id'] ?? 0,
      toUserId: json['to_user_id'] ?? 0,
      title: json['title'] ?? '',
      readStatus: json['read_status'] ?? '',
      description: _stripHtmlTags(json['short_description'] ?? ''),
      timeAgo: _formatTime(createdTime),
    );
  }

  // thi method remove html tags from the description and return the cleaned text-------------------------
  static String _stripHtmlTags(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'&nbsp;?', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'&[^;\s]+;', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }


  // this method convert time into days-----------------

  static String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Some time ago';

    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  NotificationModel copyWith({String? readStatus}) {
    return NotificationModel(
        id: id,
        title: title,
        description: description,
        timeAgo: timeAgo,
        readStatus: readStatus ?? this.readStatus,
        fromUserId: fromUserId,
        toUserId: toUserId);
  }
}

class Student {
  final String name;
  final String college;
  final bool isJoined;
  final String shortlistStatus;
  final String id;
  bool isSelected;
  final int sendNotificationCount;
  final int? meeting_id;
  final int? user_id;


  Student({
    required this.name,
    required this.college,
    required this.isJoined,
    required this.shortlistStatus,
    required this.id,
    this.isSelected = false,
    this.sendNotificationCount = 0,
    this.meeting_id,
    this.user_id,

  });

  Student copyWith({
    String? shortlistStatus,
    int? sendNotificationCount,
    int? meeting_id,
    int? user_id,
  }) {
    return Student(
      name: name,
      college: college,
      isJoined: isJoined,
      shortlistStatus: shortlistStatus ?? this.shortlistStatus,
      id: id,
      isSelected: isSelected ?? this.isSelected,
      sendNotificationCount: sendNotificationCount ?? this.sendNotificationCount,
      meeting_id: meeting_id ?? this.meeting_id,
      user_id: user_id ?? this.user_id,

    );
  }
}

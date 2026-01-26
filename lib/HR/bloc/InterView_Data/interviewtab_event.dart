import 'package:equatable/equatable.dart';

abstract class DiscussionEvent extends Equatable {
  const DiscussionEvent();
  @override
  List<Object?> get props => [];
}

class LoadDiscussions extends DiscussionEvent {
  final String? jobId; // 👈 optional, pass when you have it
  const LoadDiscussions({this.jobId});

  @override
  List<Object?> get props => [jobId];
}

class TabDeleteMeetingEvent extends DiscussionEvent {
  final String meetingId;
  final String reason;
  const TabDeleteMeetingEvent({required this.meetingId, required this.reason});

  @override
  List<Object?> get props => [meetingId, reason];
}

class DeleteAttendeeEvent extends DiscussionEvent {
  final String meetingId;
  final int userId;
  final String reason;
  const DeleteAttendeeEvent({
    required this.meetingId,
    required this.userId,
    required this.reason,
  });

  @override
  List<Object?> get props => [meetingId, userId, reason];
}

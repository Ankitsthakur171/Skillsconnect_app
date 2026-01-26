import '../../model/interview_bottom.dart';
import 'package:equatable/equatable.dart';

abstract class DiscussionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDiscussions extends DiscussionEvent {}

class DeleteMeetingEvent extends DiscussionEvent {
  final String meetingId;
  final String reason;
  DeleteMeetingEvent({required this.meetingId, required this.reason});

  @override
  List<Object?> get props => [meetingId, reason];
}


class DeleteAttendeeEvent extends DiscussionEvent {
  final String meetingId;
  final int userId;
  final String reason;
  DeleteAttendeeEvent({
    required this.meetingId,
    required this.userId,
    required this.reason,
  });

  @override
  List<Object?> get props => [meetingId, userId, reason];
}
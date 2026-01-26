import '../../model/interview_bottom.dart';
import 'package:equatable/equatable.dart';

abstract class DiscussionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiscussionInitial extends DiscussionState {}
class DiscussionLoading extends DiscussionState {}
class DiscussionLoaded extends DiscussionState {
  final List<ScheduledMeeting> discussions;
  DiscussionLoaded(this.discussions);

  @override
  List<Object?> get props => [discussions];
}
class DiscussionError extends DiscussionState {
  final String message;
  DiscussionError(this.message);

  @override
  List<Object?> get props => [message];
}

class MeetingDeleting extends DiscussionState {}
class MeetingDeleted extends DiscussionState {
  final String message;
  MeetingDeleted(this.message);
  @override
  List<Object?> get props => [message];
}


class AttendeeDeleting extends DiscussionState {}
class AttendeeDeleted extends DiscussionState {
  final String message;
  AttendeeDeleted(this.message);
  @override
  List<Object?> get props => [message];
}
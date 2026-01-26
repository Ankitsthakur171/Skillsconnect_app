
import '../../HR/model/interview_bottom.dart';

abstract class DiscussionState {}

class DiscussionInitial extends DiscussionState {}

class DiscussionLoading extends DiscussionState {}

class DiscussionLoaded extends DiscussionState {
  final List<ScheduledMeeting> meetings;
  DiscussionLoaded(this.meetings);
}

class DiscussionError extends DiscussionState {
  final String message;
  DiscussionError(this.message);
}

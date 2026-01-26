import 'package:equatable/equatable.dart';
import '../../Model/Job_Model.dart';

abstract class BookmarkEvent extends Equatable {
  const BookmarkEvent();

  @override
  List<Object> get props => [];
}

class AddBookmarkEvent extends BookmarkEvent {
  final JobModelsd job;

  const AddBookmarkEvent(this.job);

  @override
  List<Object> get props => [job];
}

class RemoveBookmarkEvent extends BookmarkEvent {
  final String jobToken;

  const RemoveBookmarkEvent(this.jobToken);

  @override
  List<Object> get props => [jobToken];
}

class ResetBookmarksEvent extends BookmarkEvent {}


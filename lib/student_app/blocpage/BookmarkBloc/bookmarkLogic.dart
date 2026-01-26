import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Model/Job_Model.dart';
import 'bookmarkEvent.dart';
import 'bookmarkState.dart';

class BookmarkBloc extends Bloc<BookmarkEvent, BookmarkState> {
  BookmarkBloc() : super(const BookmarkState()) {
    on<AddBookmarkEvent>((event, emit) {
      final updatedList = List<JobModelsd>.from(state.bookmarkedJobs)
        ..add(event.job);
      emit(BookmarkState(bookmarkedJobs: updatedList));
    });

    on<RemoveBookmarkEvent>((event, emit) {
      final updatedList = state.bookmarkedJobs
          .where((job) => job.jobToken != event.jobToken)
          .toList();
      emit(BookmarkState(bookmarkedJobs: updatedList));
    });

    on<ResetBookmarksEvent>((event, emit) {
      emit(const BookmarkState());
    });
  }
}

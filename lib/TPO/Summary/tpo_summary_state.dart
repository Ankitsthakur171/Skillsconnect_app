// bloc/summary_state.dart
abstract class SummaryState {}

class SummaryInitial extends SummaryState {}

class SummaryLoading extends SummaryState {}

class SummaryLoaded extends SummaryState {
  final String jobs;
  final String selected_candidates;
  final String registered_users;

  SummaryLoaded({
    required this.jobs,
    required this.selected_candidates,
    required this.registered_users,
  });
}

class SummaryError extends SummaryState {
  final String message;
  SummaryError(this.message);
}

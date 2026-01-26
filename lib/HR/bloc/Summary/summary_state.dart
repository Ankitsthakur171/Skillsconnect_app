abstract class SummaryState {}

class SummaryInitial extends SummaryState {}

class SummaryLoading extends SummaryState {}

class SummaryLoaded extends SummaryState {
  final int applications;
  final int invited;
  final int selected;
  final int rejected;

  SummaryLoaded({
    required this.applications,
    required this.invited,
    required this.selected,
    required this.rejected,
  });
}

class SummaryError extends SummaryState {
  final String message;
  final int? statusCode;
  SummaryError(this.message,[this.statusCode]);
}

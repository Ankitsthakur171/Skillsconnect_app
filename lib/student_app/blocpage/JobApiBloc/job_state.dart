abstract class JobState {}

class JobInitial extends JobState {}

class JobLoading extends JobState {}

class JobLoaded extends JobState {
  final List<Map<String, dynamic>> jobs;
  JobLoaded(this.jobs);
}

class JobError extends JobState {
  final String error;
  JobError(this.error);
}

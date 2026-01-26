
// -------------------- STATES --------------------
import '../../model/job_model.dart';

abstract class JobState {}

class JobInitial extends JobState {}

class JobLoading extends JobState {}

class JobLoaded extends JobState {
  final List<JobModel> jobs;
  final bool hasMore;

  JobLoaded({required this.jobs, required this.hasMore});
}

class JobError extends JobState {
  final String message;
  final int? statusCode;           // 👈 add this

  JobError(this.message,[this.statusCode]);
}

class FilteredJobLoaded extends JobState {
  final List<JobModel> filteredJobs;

  FilteredJobLoaded(this.filteredJobs);
}


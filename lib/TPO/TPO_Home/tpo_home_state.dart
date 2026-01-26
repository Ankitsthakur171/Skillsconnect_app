import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';

abstract class TpoHomeState {}

class JobInitial extends TpoHomeState {}

class TPOJobLoading extends TpoHomeState {}


class TpoJobLoaded extends TpoHomeState {
  final List<TpoHomeJobModel> jobs;
  final bool hasMore;

  TpoJobLoaded({required this.jobs, required this.hasMore});
}

class TpoJobError extends TpoHomeState {
  final String message;
  TpoJobError(this.message);
}
class FilteredJobLoaded extends TpoHomeState {
  final List<TpoHomeJobModel> filteredJobs;

  FilteredJobLoaded(this.filteredJobs);
}


// -------------------- EVENTS --------------------
import '../../model/job_model.dart';

abstract class JobEvent {}

class LoadJobsEvent extends JobEvent {}

class SearchJobsEvent extends JobEvent {
  final String query;
  SearchJobsEvent(this.query);
}

class FetchJobsEvent extends JobEvent {
  final int page;
  final int limit;

  FetchJobsEvent({required this.page, required this.limit});
}

class ApplyFilterEvent extends JobEvent {
  final List<JobModel> filteredJobs;

  ApplyFilterEvent(this.filteredJobs);
}


import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';

abstract class TpoHomeEvent {}

class LoadTpoJobsEvent extends TpoHomeEvent {
  LoadTpoJobsEvent();
}


class LoadMoreTpoJobsEvent extends TpoHomeEvent {
  /// call this when user scrolls near bottom
  LoadMoreTpoJobsEvent();
}


class SearchTpoJobs extends TpoHomeEvent {
  final String query;
  SearchTpoJobs(this.query);
}

class ApplyFilterEvent extends TpoHomeEvent {
  final List<TpoHomeJobModel> filteredJobs;

  ApplyFilterEvent(this.filteredJobs);
}



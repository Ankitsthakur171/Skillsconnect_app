import 'package:equatable/equatable.dart';
import '../../model/job_model.dart';

//  Renamed abstract class
abstract class ApplicantDataEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadDataApplicants extends ApplicantDataEvent {
  final JobModel job;

  LoadDataApplicants(this.job);

  @override
  List<Object> get props => [job];

  @override
  String toString() => 'LoadApplicants(job: $job)';
}



class SearchApplicantEvent extends ApplicantDataEvent {
  final JobModel job;
  final String query;
  final int page;


  SearchApplicantEvent({required this.job, required this.query,this.page= 1});
}


class LoadMoreApplicants extends ApplicantDataEvent {
  final JobModel job;
  final String query;

  LoadMoreApplicants({required this.job, this.query = ''});
}


class LoadAllApplicantsCount extends ApplicantDataEvent {
  final int jobId;
  final Map<String, String>? filters;
  final String? searchQuery;

  LoadAllApplicantsCount({
    required this.jobId,
    this.filters,
    this.searchQuery,
  });
}


class ApplyApplicantFilter extends ApplicantDataEvent {
  final int jobId;
  final Map<String, String> filters;
  final int page;


  ApplyApplicantFilter({required this.jobId, required this.filters,this.page = 1});
}

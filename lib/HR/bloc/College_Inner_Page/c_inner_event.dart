import 'package:equatable/equatable.dart';

abstract class CollegeEvent extends Equatable {
  const CollegeEvent();
  @override
  List<Object?> get props => [];
}

class FetchCollegeDetails extends CollegeEvent {
  final int collegeId;
  final int jobId;

  const FetchCollegeDetails({required this.collegeId, required this.jobId});

  @override
  List<Object?> get props => [collegeId, jobId];
}

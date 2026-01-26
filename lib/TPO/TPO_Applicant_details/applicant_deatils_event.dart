abstract class ApplicantEvent {}

class LoadApplicant extends ApplicantEvent {
  final int applicationId;
  final int jobId;
  final int userId;
  final String applicationStatus;

  LoadApplicant({
    required this.applicationId,
    required this.jobId,
    required this.userId,
    required this.applicationStatus,
  });

  @override
  List<Object> get props => [applicationId, jobId, userId,applicationStatus];
}



class UpdateApplicationStatus extends ApplicantEvent {
  final int jobId;
  final int applicationId;
  final String newStatus;

  UpdateApplicationStatus({
    required this.jobId,
    required this.applicationId,
    required this.newStatus,
  });

  @override
  List<Object> get props => [jobId, applicationId, newStatus];
}
abstract class Tpointerinnerevent {}

class TpoInterviewLoadApplicant extends Tpointerinnerevent {
  final int applicationId;
  final int jobId;
  final int userId;
  final String applicationStatus;

  TpoInterviewLoadApplicant({
    required this.applicationId,
    required this.jobId,
    required this.userId,
    required this.applicationStatus,
  });

  @override
  List<Object> get props => [applicationId, jobId, userId,applicationStatus];
}



class UpdateApplicationStatus extends Tpointerinnerevent {
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
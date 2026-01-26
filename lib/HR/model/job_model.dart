

class JobModel {
  final String title;
  final String location;
  final String type;
  final String salary;
  final String status;
  final int enddate;
  final int applicants;
  final int jobId;
  final int Id;
  final String opportunityType;
  final String stipendType;




  JobModel({
    required this.title,
    required this.location,
    required this.type,
    required this.salary,
    required this.status,
    required this.enddate,
    required this.applicants,
    required this.jobId,
    required this.Id,
    required this.opportunityType,
    required this.stipendType,

  });

  factory JobModel.fromJson(Map<String, dynamic> json) {

    // end_date ko parse karte hain
    DateTime? endDate;
    int remainingDays = 0;

    if (json['end_date'] != null && json['end_date'].toString().isNotEmpty) {
      try {
        endDate = DateTime.parse(json['end_date']);
        final now = DateTime.now();
        remainingDays = endDate.difference(now).inDays;
        if (remainingDays < 0) remainingDays = 0; // agar expire ho gaya to 0
      } catch (e) {
        remainingDays = 0;
      }
    }

    return JobModel(
      title: json['title'] ?? '',
      location: json['city_names'] ?? '',
      type: json['job_type'] ?? '',
      salary: json['job_ctc_display']?.toString() ?? '',
      status: json['job_status'] ?? '',
      enddate:remainingDays,// Not present? Use ''
      applicants: json['cv_received'] ?? '',
      jobId: json['job_id'] is int ? json['job_id'] : int.tryParse(json['job_id'].toString()) ?? 0, // ✅ Safely parse int
      Id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0, // ✅ Safely parse int
      opportunityType: json['opportunity_type'] ?? '',
      stipendType: json['stipend_type']?.toString() ?? '',


    );
  }
}

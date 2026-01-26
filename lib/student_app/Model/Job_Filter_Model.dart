class JobFilterModel {
  final String? jobType;
  final String? courseId;
  final String? specializationId;
  final String? state;
  final String? city;

  const JobFilterModel({
    this.jobType,
    this.courseId,
    this.specializationId,
    this.state,
    this.city,
  });

  bool get hasAnyFilter =>
      (jobType != null && jobType!.isNotEmpty) ||
          (courseId != null && courseId!.isNotEmpty) ||
          (specializationId != null && specializationId!.isNotEmpty) ||
          (state != null && state!.isNotEmpty) ||
          (city != null && city!.isNotEmpty);

  Map<String, dynamic> toApiParams() {
    return {
      "jobType": jobType ?? "",
      "courseId": courseId ?? "",
      "specializationId": specializationId ?? "",
      "state": state ?? "",
      "city": city ?? "",
    };
  }

  static JobFilterModel empty() => const JobFilterModel();
}

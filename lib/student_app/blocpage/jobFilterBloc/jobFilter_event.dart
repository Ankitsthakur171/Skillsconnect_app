abstract class JobFilterEvent {}

class ShowJobFilterSheet extends JobFilterEvent {}

class ApplyJobFilters extends JobFilterEvent {
  final Map<String, dynamic> filterData;

  ApplyJobFilters(this.filterData);
}

class ResetJobFilters extends JobFilterEvent {}


abstract class JobFilterState {}

class JobFilterInitial extends JobFilterState {}

class JobFilterSheetVisible extends JobFilterState {}

class JobFilterApplied extends JobFilterState {
  final Map<String, dynamic> filterData;
  JobFilterApplied(this.filterData);
}

import 'package:flutter_bloc/flutter_bloc.dart';

import 'jobFilter_event.dart';
import 'jobFilter_state.dart';


class JobFilterBloc extends Bloc<JobFilterEvent, JobFilterState> {
  JobFilterBloc() : super(JobFilterInitial()) {
    on<ShowJobFilterSheet>((event, emit) {
      emit(JobFilterSheetVisible());
    });

    on<ApplyJobFilters>((event, emit) {
      emit(JobFilterApplied(event.filterData));
    });

    on<ResetJobFilters>((event, emit) {
      emit(JobFilterInitial());
    });
  }
}

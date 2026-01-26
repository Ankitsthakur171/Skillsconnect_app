import 'package:flutter_bloc/flutter_bloc.dart';
import 'job_event.dart';
import 'job_state.dart';
import '../../Utilities/JobList_Api.dart';

class JobBloc extends Bloc<JobEvent, JobState> {
  JobBloc() : super(JobInitial()) {
    on<FetchJobsEvent>(_onFetchJobs);
  }

  Future<void> _onFetchJobs(
      FetchJobsEvent event,
      Emitter<JobState> emit,
      ) async {
    emit(JobLoading());

    try {
      final fetchedJobs = await JobApi.fetchJobs();

      final jobs = fetchedJobs.map<Map<String, dynamic>>((job) {
        final location = (job['location'] as String?)?.isNotEmpty ?? false
            ? job['location']
            : (job['job_location_detail'] as List<dynamic>?)?.isNotEmpty ?? false
            ? (job['job_location_detail'] as List<dynamic>)
            .map((loc) => loc['city_name'] as String? ?? 'Unknown')
            .join(' • ')
            : 'N/A';

        return {
          'title': job['title'] ?? 'Untitled',
          'company': job['company'] ?? 'Unknown Company',
          'location': location,
          'salary': job['salary'] ?? 'N/A',
          'postTime': job['postTime'] ?? 'N/A',
          'expiry': job['expiry'] ?? 'N/A',
          'tags': List<String>.from(job['tags'] ?? []),
          'logoUrl': job['logoUrl'],
          'jobToken': job['jobToken'],
        };
      }).toList();

      emit(JobLoaded(jobs));
    } catch (e) {
      emit(JobError('Failed to load jobs: $e'));
    }
  }
}

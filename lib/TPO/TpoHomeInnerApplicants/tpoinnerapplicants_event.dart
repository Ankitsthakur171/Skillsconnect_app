

// lib/TPO/Students/tpoinnerapplicants_event.dart
import 'package:equatable/equatable.dart';

import 'package:equatable/equatable.dart';

class StudentQuery extends Equatable {
  final String search;       // generic search (student name, email, etc.)
  final int? processId;      // from process dropdown
  final int? statusId;       // from application status dropdown
  final int? collegeId;      // from college dropdown
  final int? stateId;        // from state dropdown
  final int? cityId;         // from city dropdown

  const StudentQuery({
    this.search = "",
    this.processId,
    this.statusId,
    this.collegeId,
    this.stateId,
    this.cityId,
  });

  StudentQuery copyWith({
    String? search,
    int? processId,
    int? statusId,
    int? collegeId,
    int? stateId,
    int? cityId,
  }) {
    return StudentQuery(
      search: search ?? this.search,
      processId: processId ?? this.processId,
      statusId: statusId ?? this.statusId,
      collegeId: collegeId ?? this.collegeId,
      stateId: stateId ?? this.stateId,
      cityId: cityId ?? this.cityId,
    );
  }

  @override
  List<Object?> get props => [
    search,
    processId,
    statusId,
    collegeId,
    stateId,
    cityId,
  ];
}

abstract class StudentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StudentLoadApplicants extends StudentEvent {
  final int jobId;
  final int limit;
  final StudentQuery query;
  StudentLoadApplicants(this.jobId, {this.limit = 5, this.query = const StudentQuery()});
  @override
  List<Object?> get props => [jobId, limit, query];
}

class StudentSearchEvent extends StudentEvent {
  final int jobId;
  final String search;
  StudentSearchEvent(this.jobId, this.search);
  @override
  List<Object?> get props => [jobId, search];
}

class StudentApplyFilterEvent extends StudentEvent {
  final int jobId;
  final StudentQuery query;
  StudentApplyFilterEvent(this.jobId, this.query);
  @override
  List<Object?> get props => [jobId, query];
}

class StudentLoadMoreEvent extends StudentEvent {
  final int jobId;
  StudentLoadMoreEvent(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

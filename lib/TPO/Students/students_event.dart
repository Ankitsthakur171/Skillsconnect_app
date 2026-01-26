// students_event.dart

/// Base class for all Institute events.
/// Keep this immutable and with a const constructor for perf.
abstract class InstituteEvent {
  const InstituteEvent();
}

/// Backward-compat event (old code path).
/// NOTE: page/limit/offset are Strings (as older API callers sent them as strings).
class LoadInstitutes extends InstituteEvent {
  final String collegeName;
  final String courseId;
  final String passoutYear;
  final String studentName;
  final String status;

  /// Items per page (string for legacy callers)
  final String limit;

  /// Offset (string for legacy callers)
  final String offset;

  /// 1-based page index (string for legacy callers)
  final String page;

  const LoadInstitutes({
    this.collegeName = '',
    this.courseId = '',
    this.passoutYear = '',
    this.studentName = '',
    this.status = '',
    this.limit = '5',
    this.offset = '0',
    this.page = '1',
  }) : super();
}

/// Reset pagination & filters, then start fresh from page=0.
class ResetInstitutes extends InstituteEvent {
  final String collegeName;
  final String courseId;
  final String passoutYear;
  final String studentName;
  final String status;

  const ResetInstitutes({
    this.collegeName = '',
    this.courseId = '',
    this.passoutYear = '',
    this.studentName = '',
    this.status = '',
  }) : super();
}

/// Paginated fetch using zero-based page & int limit (new path).
class FetchInstitutes extends InstituteEvent {
  final String collegeName;
  final String courseId;
  final String passoutYear;
  final String studentName;
  final String status;

  /// Zero-based page index (0,1,2…)
  final int page;

  /// Items per page
  final int limit;

  const FetchInstitutes({
    this.collegeName = '',
    this.courseId = '',
    this.passoutYear = '',
    this.studentName = '',
    this.status = '',
    this.page = 0,
    this.limit = 5,
  }) : super();
}

class InstituteSearchEvent extends InstituteEvent {
  final String search;

  const InstituteSearchEvent({required this.search});
}
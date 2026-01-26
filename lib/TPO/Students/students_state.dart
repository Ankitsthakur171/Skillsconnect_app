// import '../Model/c_model.dart';
// import 'students_bloc.dart';
//
// abstract class InstituteState {}
//
// class InstituteInitial extends InstituteState {}
//
// class InstituteLoading extends InstituteState {}
//
// class InstituteLoaded extends InstituteState {
//   final List<InstituteModel> institutes;
//   final InstituteMeta meta;
//   InstituteLoaded(this.institutes, this.meta);
// }
//
// class InstituteError extends InstituteState {
//   final String message;
//   InstituteError(this.message);
// }


// students_state.dart
import '../Model/c_model.dart';

abstract class InstituteState {
  const InstituteState();
}

class InstituteInitial extends InstituteState {
  const InstituteInitial();
}

class InstituteLoading extends InstituteState {
  const InstituteLoading();
}

class InstituteLoaded extends InstituteState {
  /// Aggregated (page 0..n append)
  final List<InstituteModel> institutes;

  /// Server meta (agar tumhari response me ho)
  final InstituteMeta? meta;

  /// True => more pages available
  final bool hasMore;

  /// True => ek aur page fetch ho raha hai (UI bottom loader ke liye)
  final bool isFetchingMore;

  const InstituteLoaded({
    required this.institutes,
    this.meta,
    required this.hasMore,
    this.isFetchingMore = false,
  });

  InstituteLoaded copyWith({
    List<InstituteModel>? institutes,
    InstituteMeta? meta,
    bool? hasMore,
    bool? isFetchingMore,
  }) {
    return InstituteLoaded(
      institutes: institutes ?? this.institutes,
      meta: meta ?? this.meta,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class InstituteError extends InstituteState {
  final String message;
  const InstituteError(this.message);
}

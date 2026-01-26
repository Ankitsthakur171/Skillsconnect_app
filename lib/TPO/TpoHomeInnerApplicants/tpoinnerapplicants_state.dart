// // import 'package:equatable/equatable.dart';
// // import 'package:skillsconnect/TPO/Model/student_model.dart';
// //
// // abstract class StudentState extends Equatable {
// //   @override
// //   List<Object> get props => [];
// // }
// //
// // class StudentInitial extends StudentState {}
// //
// // class StudentLoading extends StudentState {}
// //
// // class StudentLoaded extends StudentState {
// //   final List<StudentModel> student;
// //   StudentLoaded(this.student);
// //
// //   @override
// //   List<Object> get props => [student];
// // }
// //
// // class StudentError extends StudentState {
// //   final String message;
// //   StudentError(this.message,);
// //
// //   @override
// //   List<Object> get props => [message];
// // }
//
//
//
//
//
//
//
//
//
// // lib/TPO/Students/tpoinnerapplicants_state.dart
// import 'package:equatable/equatable.dart';
// import 'package:skillsconnect/TPO/Model/student_model.dart';
// import 'tpoinnerapplicants_event.dart';
//
// abstract class StudentState extends Equatable {
//   @override
//   List<Object?> get props => [];
// }
//
// class StudentInitial extends StudentState {}
//
// class StudentLoading extends StudentState {}
//
// class StudentLoaded extends StudentState {
//   final List<StudentModel> student;
//   final int limit; // current limit
//   final bool hasMore; // optimistic (true if last fetch returned == limit)
//   final StudentQuery query;
//
//   StudentLoaded({
//     required this.student,
//     required this.limit,
//     required this.hasMore,
//     required this.query,
//   });
//
//   StudentLoaded copyWith({
//     List<StudentModel>? student,
//     int? limit,
//     bool? hasMore,
//     StudentQuery? query,
//   }) =>
//       StudentLoaded(
//         student: student ?? this.student,
//         limit: limit ?? this.limit,
//         hasMore: hasMore ?? this.hasMore,
//         query: query ?? this.query,
//       );
//
//   @override
//   List<Object?> get props => [student, limit, hasMore, query];
// }
//
// class StudentError extends StudentState {
//   final String message;
//   StudentError(this.message);
//   @override
//   List<Object?> get props => [message];
// }



// tpoinnerapplicants_state.dart (ya jahan StudentState define hai)

import 'package:equatable/equatable.dart';
import 'package:skillsconnect/TPO/Model/student_model.dart';
import 'tpoinnerapplicants_event.dart';

class StudentState extends Equatable {
  const StudentState();
  @override
  List<Object?> get props => [];
}

class StudentInitial extends StudentState {}

class StudentLoading extends StudentState {}

class StudentLoaded extends StudentState {
  final List<StudentModel> student; // current cumulative list
  final int limit;                   // server ko bheja gaya limit (5,10,15..)
  final bool hasMore;                // aur data possible?
  final StudentQuery query;          // current filters/search
  final bool isLoadingMore;          //  guard to stop rapid calls

  const StudentLoaded({
    required this.student,
    required this.limit,
    required this.hasMore,
    required this.query,
    this.isLoadingMore = false,      // default false
  });

  StudentLoaded copyWith({
    List<StudentModel>? student,
    int? limit,
    bool? hasMore,
    StudentQuery? query,
    bool? isLoadingMore,
  }) =>
      StudentLoaded(
        student: student ?? this.student,
        limit: limit ?? this.limit,
        hasMore: hasMore ?? this.hasMore,
        query: query ?? this.query,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [student, limit, hasMore, query, isLoadingMore];
}

class StudentError extends StudentState {
  final String message;
  const StudentError(this.message);
  @override
  List<Object?> get props => [message];
}


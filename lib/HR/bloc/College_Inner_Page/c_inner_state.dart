import 'package:equatable/equatable.dart';
import '../../model/c_innerpage_model.dart';

abstract class CollegeState extends Equatable {
  const CollegeState();
  @override
  List<Object?> get props => [];
}

class CollegeInitial extends CollegeState {}

class CollegeLoading extends CollegeState {}

class CollegeLoaded extends CollegeState {
  final CollegeInfo college;
  final List<CourseInfo> courses; // 👈 added

  const CollegeLoaded(this.college, this.courses);

  @override
  List<Object?> get props => [college, courses];
}

class CollegeError extends CollegeState {
  final String error;
  const CollegeError(this.error);
  @override
  List<Object?> get props => [error];
}

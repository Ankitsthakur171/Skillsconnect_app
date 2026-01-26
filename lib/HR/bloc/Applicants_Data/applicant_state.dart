//
// import '../../model/applicant_model.dart';
// import 'package:equatable/equatable.dart';
//
// abstract class ApplicantState extends Equatable {
//   final List<ApplicantModel> applicants;
//
//   const ApplicantState({required this.applicants});
//
//   @override
//   List<Object?> get props => [applicants];
// }
//
// class ApplicantInitial extends ApplicantState {
//   const ApplicantInitial() : super(applicants: const []);
// }
//
// class ApplicantLoading extends ApplicantState {
//   const ApplicantLoading({required super.applicants});
// }
//
// class ApplicantLoaded extends ApplicantState {
//   final bool hasReachedMax;
//   final int currentPage;
//   final List<ApplicationStage> applicationStages;
//   final bool isLoadingMore;
//   final String? searchQuery;
//   final String? errorMessage;
//   final List<ProcessModel> processList;
//   final int totalCount;
//
//
//   const ApplicantLoaded({
//     required super.applicants,
//     required this.hasReachedMax,
//     required this.currentPage,
//     this.applicationStages =  const <ApplicationStage>[],  // ✅ default empty
//     this.processList = const <ProcessModel>[],        // ✅ default empty
//     this.isLoadingMore = false,
//     this.searchQuery,
//     this.errorMessage,
//     this.totalCount = 0, // 👈 added
//
//   });
//
//   @override
//   List<Object?> get props => [
//     ...super.props,
//     hasReachedMax,
//     currentPage,
//     applicationStages,
//     processList,   // ✅ include in Equatable
//     isLoadingMore,
//     searchQuery,
//     errorMessage,
//     totalCount
//   ];
//
//   ApplicantLoaded copyWith({
//     List<ApplicantModel>? applicants,
//     bool? hasReachedMax,
//     int? currentPage,
//     List<ApplicationStage>? applicationStages,
//     List<ProcessModel>? processList,
//     bool? isLoadingMore,
//     String? searchQuery,
//     String? errorMessage,
//     int? totalCount, // 👈 add this
//
//   }) {
//     return ApplicantLoaded(
//       applicants: applicants ?? this.applicants,
//       hasReachedMax: hasReachedMax ?? this.hasReachedMax,
//       currentPage: currentPage ?? this.currentPage,
//       applicationStages: applicationStages ?? this.applicationStages,
//       processList: processList ?? this.processList,
//       isLoadingMore: isLoadingMore ?? this.isLoadingMore,
//       searchQuery: searchQuery ?? this.searchQuery,
//       errorMessage: errorMessage ?? this.errorMessage,
//       totalCount: totalCount ?? this.totalCount, // 👈
//
//     );
//   }
// }
//
// class ApplicantError extends ApplicantState {
//   final String message;
//   final int? statusCode;           // 👈 add this
//   const ApplicantError(this.message, {required super.applicants,this.statusCode,   // 👈 optional
//   });
//
//   @override
//   List<Object?> get props => [message, ...super.props];
// }



import '../../model/applicant_model.dart';
import 'package:equatable/equatable.dart';

abstract class ApplicantState extends Equatable {
  final List<ApplicantModel> applicants;

  const ApplicantState({required this.applicants});

  @override
  List<Object?> get props => [applicants];
}

class ApplicantInitial extends ApplicantState {
  const ApplicantInitial() : super(applicants: const []);
}

class ApplicantLoading extends ApplicantState {
  const ApplicantLoading({required super.applicants});
}

class ApplicantLoaded extends ApplicantState {
  final bool hasReachedMax;
  final int currentPage; // 0-based page index
  final List<ApplicationStage> applicationStages;
  final bool isLoadingMore;
  final String? searchQuery;
  final String? errorMessage;
  final List<ProcessModel> processList;
  final int totalCount;
  final int totalCvCount;


  const ApplicantLoaded({
    required super.applicants,
    required this.hasReachedMax,
    required this.currentPage,
    this.applicationStages = const <ApplicationStage>[],
    this.processList = const <ProcessModel>[],
    this.isLoadingMore = false,
    this.searchQuery,
    this.errorMessage,
    this.totalCount = 0,
    this.totalCvCount = 0,

  });

  @override
  List<Object?> get props => [
    ...super.props,
    hasReachedMax,
    currentPage,
    applicationStages,
    processList,
    isLoadingMore,
    searchQuery,
    errorMessage,
    totalCount,
  ];

  ApplicantLoaded copyWith({
    List<ApplicantModel>? applicants,
    bool? hasReachedMax,
    int? currentPage,
    List<ApplicationStage>? applicationStages,
    List<ProcessModel>? processList,
    bool? isLoadingMore,
    String? searchQuery,
    String? errorMessage,
    int? totalCount,
    int? totalCvCount, // ⬅️ NEW

  }) {
    return ApplicantLoaded(
      applicants: applicants ?? this.applicants,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      applicationStages: applicationStages ?? this.applicationStages,
      processList: processList ?? this.processList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      totalCount: totalCount ?? this.totalCount,
      totalCvCount: totalCvCount ?? this.totalCvCount,

    );
  }
}

class ApplicantError extends ApplicantState {
  final String message;
  final int? statusCode;

  const ApplicantError(
      this.message, {
        required super.applicants,
        this.statusCode,
      });

  @override
  List<Object?> get props => [message, ...super.props];
}

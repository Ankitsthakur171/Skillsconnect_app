
import '../../HR/model/applicant_model.dart';
import '../Model/tpo_applicant_details_model.dart';

class ApplicantState {
  final TPOApplicant? applicant;
  final bool isLoading;
  final List<ApplicationStage> applicationStages;

  const ApplicantState({
    this.applicant,
    required this.applicationStages,
    this.isLoading = false,
  });

  // Initial/default state
  factory ApplicantState.initial() {
    return const ApplicantState(
      applicant: null,
      isLoading: false,
      applicationStages: [],
    );
  }

  // Create a new state from the current state with updated values
  ApplicantState copyWith({
    TPOApplicant? applicant,
    bool? isLoading,
    List<ApplicationStage>? applicationStages,
  }) {
    return ApplicantState(
      applicant: applicant ?? this.applicant,
      isLoading: isLoading ?? this.isLoading,
      applicationStages: applicationStages ?? this.applicationStages,
    );
  }
}


class ApplicantError extends ApplicantState {
  final int? code;        // e.g. 404 / 500
  final String message;   // error message

  ApplicantError({this.code, required this.message, required super.applicationStages});
}
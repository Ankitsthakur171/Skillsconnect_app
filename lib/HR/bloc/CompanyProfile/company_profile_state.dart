import '../../model/company_profile_model.dart';

class CompanyProfileState {
  final CompanyProfileModel profile;
  final bool isSubmitting;
  final bool isSuccess;
  final bool isFailure;

  CompanyProfileState({
    required this.profile,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.isFailure = false,
  });

  factory CompanyProfileState.initial() {
    return CompanyProfileState(profile: CompanyProfileModel());
  }

  CompanyProfileState copyWith({
    CompanyProfileModel? profile,
    bool? isSubmitting,
    bool? isSuccess,
    bool? isFailure,
  }) {
    return CompanyProfileState(
      profile: profile ?? this.profile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      isFailure: isFailure ?? this.isFailure,
    );
  }
}

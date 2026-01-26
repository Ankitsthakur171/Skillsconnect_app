class UpdatePasswordState {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final bool isSubmitting;
  final bool isSuccess;
  final bool isFailure;
  final String errorMessage;

  UpdatePasswordState({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.isSubmitting,
    required this.isSuccess,
    required this.isFailure,
    required this.errorMessage,
  });

  factory UpdatePasswordState.initial() => UpdatePasswordState(
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
    isSubmitting: false,
    isSuccess: false,
    isFailure: false,
    errorMessage: '',
  );

  UpdatePasswordState copyWith({
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    bool? isSubmitting,
    bool? isSuccess,
    bool? isFailure,
    String? errorMessage,
  }) {
    return UpdatePasswordState(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      isFailure: isFailure ?? this.isFailure,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

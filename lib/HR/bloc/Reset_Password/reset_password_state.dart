class ResetPasswordState {
  final String email;
  final bool isLoading;
  final String errorMessage;
  final String successMessage;

  ResetPasswordState({
    this.email = '',
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
  });

  /// You can add this getter to validate the email
  bool get isValid => email.contains('@');

  ResetPasswordState copyWith({
    String? email,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return ResetPasswordState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

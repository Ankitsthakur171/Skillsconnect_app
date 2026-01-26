class EnterOtpState {
  final String otp;
  final String password;
  final bool isLoading;
  final String errorMessage;
  final String successMessage;
  final bool? otpVerified;


  EnterOtpState({
    this.otp = '',
    this.password = '',
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
    this.otpVerified,
  });

  bool get isValid => otp.length == 6 && password.length >= 6;

  EnterOtpState copyWith({
    String? otp,
    String? password,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? otpVerified,

  }) {
    return EnterOtpState(
      otp: otp ?? this.otp,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      otpVerified: otpVerified ?? this.otpVerified,

    );
  }
}


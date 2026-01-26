// enum OtpLoginStep { enterEmail, enterOtp }
//
// class OtpLoginState {
//   final String email;
//   final String otp;
//   final bool isLoading;
//   final String successMessage;
//   final String errorMessage;
//   final OtpLoginStep step;
//
//   const OtpLoginState({
//     required this.email,
//     required this.otp,
//     required this.isLoading,
//     required this.successMessage,
//     required this.errorMessage,
//     required this.step,
//   });
//
//   factory OtpLoginState.initial() => const OtpLoginState(
//     email: '',
//     otp: '',
//     isLoading: false,
//     successMessage: '',
//     errorMessage: '',
//     step: OtpLoginStep.enterEmail,
//   );
//
//   OtpLoginState copyWith({
//     String? email,
//     String? otp,
//     bool? isLoading,
//     String? successMessage,
//     String? errorMessage,
//     OtpLoginStep? step,
//   }) {
//     return OtpLoginState(
//       email: email ?? this.email,
//       otp: otp ?? this.otp,
//       isLoading: isLoading ?? this.isLoading,
//       successMessage: successMessage ?? this.successMessage,
//       errorMessage: errorMessage ?? this.errorMessage,
//       step: step ?? this.step,
//     );
//   }
// }


enum OtpLoginStep { enterEmail, enterOtp }

class OtpLoginState {
  final String email;
  final String otp;
  final bool isLoading;
  final String successMessage;
  final String errorMessage;
  final OtpLoginStep step;

  // ⬇️ NEW: resend cooldown (seconds left)
  final int resendSecondsLeft;

  const OtpLoginState({
    required this.email,
    required this.otp,
    required this.isLoading,
    required this.successMessage,
    required this.errorMessage,
    required this.step,
    this.resendSecondsLeft = 0,     // ⬅️ default
  });

  factory OtpLoginState.initial() => const OtpLoginState(
    email: '',
    otp: '',
    isLoading: false,
    successMessage: '',
    errorMessage: '',
    step: OtpLoginStep.enterEmail,
    resendSecondsLeft: 0,        // ⬅️ default
  );

  OtpLoginState copyWith({
    String? email,
    String? otp,
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    OtpLoginStep? step,
    int? resendSecondsLeft,         // ⬅️ NEW
  }) {
    return OtpLoginState(
      email: email ?? this.email,
      otp: otp ?? this.otp,
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage ?? this.successMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      step: step ?? this.step,
      resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
    );
  }
}

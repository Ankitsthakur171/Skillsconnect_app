abstract class EnterOtpEvent {}

class OtpChanged extends EnterOtpEvent {
  final String otp;
  OtpChanged(this.otp);
}

class PasswordChanged extends EnterOtpEvent {
  final String password;
  PasswordChanged(this.password);
}

class SubmitOtp extends EnterOtpEvent {
  final String email;
  SubmitOtp(this.email);
}



class ResendOtp extends EnterOtpEvent {
  final String email;
  ResendOtp(this.email);
}

// ✅ Yeh add karo
class VerifyOtp extends EnterOtpEvent {
  final String email;
  final String otp;
  VerifyOtp(this.email, this.otp);
}
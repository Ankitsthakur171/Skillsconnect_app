abstract class ResetPasswordEvent {}

class EmailChanged extends ResetPasswordEvent {
  final String email;
  EmailChanged(this.email);
}

class SubmitReset extends ResetPasswordEvent {}

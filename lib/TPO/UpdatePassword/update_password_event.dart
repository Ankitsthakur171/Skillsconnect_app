abstract class UpdatePasswordEvent {}

class CurrentPasswordChanged extends UpdatePasswordEvent {
  final String currentPassword;
  CurrentPasswordChanged(this.currentPassword);
}

class NewPasswordChanged extends UpdatePasswordEvent {
  final String newPassword;
  NewPasswordChanged(this.newPassword);
}

class ConfirmPasswordChanged extends UpdatePasswordEvent {
  final String confirmPassword;
  ConfirmPasswordChanged(this.confirmPassword);
}

class SubmitPasswordUpdate extends UpdatePasswordEvent {}

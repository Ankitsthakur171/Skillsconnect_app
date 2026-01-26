
// lib/bloc/contact_state.dart
abstract class ContactUsState {}

class ContactInitial extends ContactUsState {}

class ContactLoading extends ContactUsState {}

class ContactUsSuccess extends ContactUsState {
  final String message;
  ContactUsSuccess(this.message);
}

class ContactUsFailure extends ContactUsState {
  final String error;
  ContactUsFailure(this.error);
}

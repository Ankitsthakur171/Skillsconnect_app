// lib/bloc/contact_event.dart
abstract class ContactUsEvent {}

class SubmitContactForm extends ContactUsEvent {
  final String name;
  final String phone;
  final String email;
  final String subject;
  final String message;

  SubmitContactForm({
    required this.name,
    required this.phone,
    required this.email,
    required this.subject,
    required this.message,
  });
}

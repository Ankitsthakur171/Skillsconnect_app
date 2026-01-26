// contact_event.dart
abstract class ContactEvent {}

class LoadContacts extends ContactEvent {
  final int page;
  final int limit;

  LoadContacts({required this.page, this.limit = 10});
}

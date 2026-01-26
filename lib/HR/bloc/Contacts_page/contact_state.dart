// contact_state.dart
import '../../model/contact_model.dart';

abstract class ContactState {}

class ContactInitial extends ContactState {}

class ContactLoading extends ContactState {}

class ContactLoaded extends ContactState {
  final List<Contact> contacts;
  final bool hasMore;

  ContactLoaded(this.contacts, {this.hasMore = true});
}

class ContactError extends ContactState {
  final String message;
  final int? statusCode;
  ContactError(this.message,[this.statusCode]);
}

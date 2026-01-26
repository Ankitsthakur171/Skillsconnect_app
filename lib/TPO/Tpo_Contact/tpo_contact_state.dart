
import 'package:skillsconnect/TPO/Model/tpo_contact_model.dart';

abstract class TpoContactState {}

class ContactInitial extends TpoContactState {}

class ContactLoading extends TpoContactState {}

class ContactLoaded extends TpoContactState {
  final List<TpoContactModel> contacts;
  final bool hasMore;


  ContactLoaded(this.contacts,{this.hasMore = true});
}

class ContactError extends TpoContactState {
  final String message;

  ContactError(this.message);
}
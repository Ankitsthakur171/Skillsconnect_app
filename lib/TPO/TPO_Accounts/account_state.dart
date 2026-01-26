import 'package:skillsconnect/TPO/Model/acc_model.dart';

abstract class AccountState {}

class AccountInitial extends AccountState {}

class AccountLoaded extends AccountState {
  final AccModel user;

  AccountLoaded(this.user);
}


class AccountError extends AccountState {
  final int? code;        // e.g. 404 / 500
  final String message;   // error message

  AccountError({this.code, required this.message});
}
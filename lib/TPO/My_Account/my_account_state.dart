import 'package:skillsconnect/TPO/Model/my_account_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileModel user;
  ProfileLoaded(this.user);
}


class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}
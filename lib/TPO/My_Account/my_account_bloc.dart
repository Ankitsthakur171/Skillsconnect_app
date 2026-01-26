import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/TPO/Model/my_account_model.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_event.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/TPO/Model/my_account_model.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_event.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_state.dart';

import 'api_services.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final Tpoprofile repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfile>((event, emit) async {
      try {
        emit(ProfileLoading());
        final user = await repository.fetchProfile();
        emit(ProfileLoaded(user));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });
  }
}


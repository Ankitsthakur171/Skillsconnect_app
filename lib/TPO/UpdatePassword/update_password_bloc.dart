import 'package:flutter_bloc/flutter_bloc.dart';
import 'update_password_event.dart';
import 'update_password_state.dart';

class UpdatePasswordBloc extends Bloc<UpdatePasswordEvent, UpdatePasswordState> {
  UpdatePasswordBloc() : super(UpdatePasswordState.initial()) {
    on<CurrentPasswordChanged>((event, emit) {
      emit(state.copyWith(currentPassword: event.currentPassword));
    });

    on<NewPasswordChanged>((event, emit) {
      emit(state.copyWith(newPassword: event.newPassword));
    });

    on<ConfirmPasswordChanged>((event, emit) {
      emit(state.copyWith(confirmPassword: event.confirmPassword));
    });

    on<SubmitPasswordUpdate>((event, emit) async {
      emit(state.copyWith(isSubmitting: true, isFailure: false, isSuccess: false, errorMessage: ''));

      await Future.delayed(Duration(seconds: 1)); // Simulate API call

      if (state.newPassword != state.confirmPassword) {
        emit(state.copyWith(
            isSubmitting: false, isFailure: true, errorMessage: "Passwords do not match"));
        return;
      }

      // You can add more validation here (e.g. old password check)
      emit(state.copyWith(isSubmitting: false, isSuccess: true));
    });
  }
}

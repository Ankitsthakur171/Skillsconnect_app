import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/HR/bloc/Account/account_event.dart';
import 'package:skillsconnect/HR/bloc/Account/account_state.dart';
import 'package:skillsconnect/TPO/Model/acc_model.dart';
import '../../model/acccount_model.dart';

class AccountBloc extends Bloc<HrAccountEvent, AccountState> {
  AccountBloc() : super(AccountInitial()) {
    on<HrAccountEvent>((event, emit) {
      // Replace with actual data fetch logic
      final user = UserModel(
        name: 'Sawmi Vivek Aanad',
        companyName: 'Company Name',
        imageUrl: 'assets/user.png',
      );
      emit(AccountLoaded(user));
    });
  }
}

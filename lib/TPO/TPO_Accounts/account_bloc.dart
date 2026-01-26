import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/TPO/Model/acc_model.dart';
import 'package:skillsconnect/TPO/TPO_Accounts/account_event.dart';
import 'package:skillsconnect/TPO/TPO_Accounts/account_state.dart';

class TpoAccountBloc extends Bloc<AccountEvent, AccountState> {
  TpoAccountBloc() : super(AccountInitial()) {
    on<LoadAccountEvent>((event, emit) {
      // Simulate fetching account data (can be replaced with API or DB call)
      final user = AccModel(
        name: 'Swami Vivekananda',
        companyName: 'College TPO',
        imageUrl: 'assets/user.png', // Make sure this asset exists in pubspec.yaml
      );

      emit(AccountLoaded(user));
    });
  }
}

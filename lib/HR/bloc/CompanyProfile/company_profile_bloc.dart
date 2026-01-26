import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/company_profile_model.dart';
import 'company_profile_event.dart';
import 'company_profile_state.dart';

class CompanyProfileBloc extends Bloc<CompanyProfileEvent, CompanyProfileState> {
  CompanyProfileBloc() : super(CompanyProfileState.initial()) {
    on<UpdateCompanyField>((event, emit) {
      final updatedProfile = _updateField(state.profile, event.field, event.value);
      emit(state.copyWith(profile: updatedProfile));
    });

    on<SubmitCompanyProfile>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));
      await Future.delayed(const Duration(seconds: 1)); // simulate save
      emit(state.copyWith(isSubmitting: false, isSuccess: true));
    });
  }

  CompanyProfileModel _updateField(CompanyProfileModel model, String field, String value) {
    switch (field) {
      case 'Company Name':
        return model.copyWith(companyName: value);
      case 'Executive Name':
        return model.copyWith(executiveName: value);
      case 'Email':
        return model.copyWith(email: value);
      case 'Mobile':
        return model.copyWith(mobile: value);
      case 'Company Website':
        return model.copyWith(website: value);
      case 'Company Size':
        return model.copyWith(companySize: value);
      case 'Founder/CEO':
        return model.copyWith(founder: value);
      case 'Established In':
        return model.copyWith(establishedIn: value);
      case 'Headquarter':
        return model.copyWith(headquarter: value);
      case 'Industry':
        return model.copyWith(industry: value);
      case 'Key People':
        return model.copyWith(keyPeople: value);
      case 'Financial Revenue':
        return model.copyWith(financialRevenue: value);
      case 'Banner Type':
        return model.copyWith(bannerType: value);
      case 'Address':
        return model.copyWith(address: value);
      case 'State':
        return model.copyWith(state: value);
      case 'City':
        return model.copyWith(city: value);
      case 'Postal Code':
        return model.copyWith(postalCode: value);
      default:
        return model;
    }
  }
}

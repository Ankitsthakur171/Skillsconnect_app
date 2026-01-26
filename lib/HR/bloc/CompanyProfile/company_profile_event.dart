import '../../model/company_profile_model.dart';

abstract class CompanyProfileEvent {}

class UpdateCompanyField extends CompanyProfileEvent {
  final String field;
  final String value;

  UpdateCompanyField(this.field, this.value);
}

class SubmitCompanyProfile extends CompanyProfileEvent {}

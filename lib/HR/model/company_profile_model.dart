class CompanyProfileModel {
  String companylogo;
  String companyProfile;
  String companyName;
  String executiveName;
  String email;
  String mobile;
  String website;
  String companySize;
  String founder;
  String establishedIn;
  String headquarter;
  String industry;
  String keyPeople;
  String financialRevenue;
  String bannerType;
  String address;
  String state;
  String city;
  String postalCode;

  CompanyProfileModel({
    this.companylogo ='',
    this.companyProfile ='',
    this.companyName = '',
    this.executiveName = '',
    this.email = '',
    this.mobile = '',
    this.website = '',
    this.companySize = '',
    this.founder = '',
    this.establishedIn = '',
    this.headquarter = '',
    this.industry = '',
    this.keyPeople = '',
    this.financialRevenue = '',
    this.bannerType = '',
    this.address = '',
    this.state = '',
    this.city = '',
    this.postalCode = '',
  });

  CompanyProfileModel copyWith({
    String? companylogo,
    String? companyName,
    String? executiveName,
    String? email,
    String? mobile,
    String? website,
    String? companySize,
    String? founder,
    String? establishedIn,
    String? headquarter,
    String? industry,
    String? keyPeople,
    String? financialRevenue,
    String? bannerType,
    String? address,
    String? state,
    String? city,
    String? postalCode,
  }) {
    return CompanyProfileModel(
      companylogo: companylogo ?? this.companylogo,
      companyProfile: companyProfile ?? this.companyProfile,
      companyName: companyName ?? this.companyName,
      executiveName: executiveName ?? this.executiveName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      website: website ?? this.website,
      companySize: companySize ?? this.companySize,
      founder: founder ?? this.founder,
      establishedIn: establishedIn ?? this.establishedIn,
      headquarter: headquarter ?? this.headquarter,
      industry: industry ?? this.industry,
      keyPeople: keyPeople ?? this.keyPeople,
      financialRevenue: financialRevenue ?? this.financialRevenue,
      bannerType: bannerType ?? this.bannerType,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
    );
  }
}

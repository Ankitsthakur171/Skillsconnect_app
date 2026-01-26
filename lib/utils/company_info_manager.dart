import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyInfoManager extends ChangeNotifier {
  static final CompanyInfoManager _instance = CompanyInfoManager._internal();
  factory CompanyInfoManager() => _instance;
  CompanyInfoManager._internal();

  String _companyName = '';
  String _companyLogo = '';

  String get companyName => _companyName;
  String get companyLogo => _companyLogo;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _companyName = prefs.getString('company_name') ?? '';
    _companyLogo = prefs.getString('company_logo') ?? '';
    notifyListeners(); // 🔴 UI ko update karne ke liye
  }

  Future<void> setCompanyData(String name, String logo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', name);
    await prefs.setString('company_logo', logo);

    _companyName = name;
    _companyLogo = logo;
    notifyListeners(); // 🔴 jaise hi set hoga, AppBar update ho jayega
  }
}




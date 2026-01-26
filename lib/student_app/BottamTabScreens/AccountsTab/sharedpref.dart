import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static const String _fullnameKey = 'fullname';
  static const String _dobKey = 'dob';
  static const String _phoneKey = 'phone';
  static const String _whatsappKey = 'whatsapp';
  static const String _emailKey = 'email';
  static const String _stateKey = 'state';
  static const String _cityKey = 'city';
  static const String _countryKey = 'country';
  static const String _educationDetailKey = 'educationDetail';
  static const String _degreeTypeKey = 'degreeType';
  static const String _courseNameKey = 'courseName';
  static const String _collegeKey = 'college';
  static const String _specilizationKey = 'specilization';
  static const String _courseTypeKey = 'courseType';
  static const String _gradingSystemKey = 'gradingSystem';
  static const String _percentageKey = 'percentage';
  static const String _passingYearKey = 'passingYear';
  static const String _skillsKey = 'skills';
  static const String _projectsKey = 'projects';
  static const String _certificatesKey = 'certificates';
  static const String _workExperiencesKey = 'workExperiences';
  static const String _profileImagePathKey = 'profileImagePath';

  static Future<void> saveData({
    required String fullname,
    required String dob,
    required String phone,
    required String whatsapp,
    required String email,
    required String state,
    required String city,
    required String country,
    String? educationDetail,
    required String degreeType,
    required String courseName,
    required String college,
    required String specilization,
    required String courseType,
    required String gradingSystem,
    required String percentage,
    required String passingYear,
    required List<String> skills,
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> certificates,
    required List<Map<String, dynamic>> workExperiences,
    File? profileImage,
    required List<Map<String, dynamic>> languages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    print(
      'Saving data: fullname=$fullname, dob=$dob, phone=$phone, skills=$skills',
    );
    print('Saving projects: ${projects.map((p) => jsonEncode(p)).toList()}');
    print(
      'Saving certificates: ${certificates.map((c) => jsonEncode(c)).toList()}',
    );
    print(
      'Saving workExperiences: ${workExperiences.map((w) => jsonEncode(w)).toList()}',
    );

    await prefs.setString(_fullnameKey, fullname);
    await prefs.setString(_dobKey, dob);
    await prefs.setString(_phoneKey, phone);
    await prefs.setString(_whatsappKey, whatsapp);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_stateKey, state);
    await prefs.setString(_cityKey, city);
    await prefs.setString(_countryKey, country);
    await prefs.setString(_educationDetailKey, educationDetail ?? '');
    await prefs.setString(_degreeTypeKey, degreeType);
    await prefs.setString(_courseNameKey, courseName);
    await prefs.setString(_collegeKey, college);
    await prefs.setString(_specilizationKey, specilization);
    await prefs.setString(_courseTypeKey, courseType);
    await prefs.setString(_gradingSystemKey, gradingSystem);
    await prefs.setString(_percentageKey, percentage);
    await prefs.setString(_passingYearKey, passingYear);
    await prefs.setStringList(_skillsKey, skills);
    await prefs.setStringList(
      _projectsKey,
      projects.map((p) => jsonEncode(p)).toList(),
    );
    await prefs.setStringList(
      _certificatesKey,
      certificates.map((c) => jsonEncode(c)).toList(),
    );
    await prefs.setStringList(
      _workExperiencesKey,
      workExperiences.map((w) => jsonEncode(w)).toList(),
    );
    if (profileImage != null) {
      await prefs.setString(_profileImagePathKey, profileImage.path);
      print('Saving profile image path: ${profileImage.path}');
    } else {
      await prefs.remove(_profileImagePathKey);
      print('Removing profile image path');
    }
    print('Data save completed');
  }

  static Future<Map<String, dynamic>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedData = {
      'fullname': prefs.getString(_fullnameKey) ?? "John",
      'dob': prefs.getString(_dobKey) ?? "16, May 2004",
      'phone': prefs.getString(_phoneKey) ?? "9892552373",
      'whatsapp': prefs.getString(_whatsappKey) ?? "9892552373",
      'email': prefs.getString(_emailKey) ?? "akhilesh.skillsconnect@gmail.com",
      'state': prefs.getString(_stateKey) ?? "Maharashtra",
      'city': prefs.getString(_cityKey) ?? "Mumbai",
      'country': prefs.getString(_countryKey) ?? "India",
      'educationDetail': prefs.getString(_educationDetailKey),
      'degreeType': prefs.getString(_degreeTypeKey) ?? "Undergrad",
      'courseName': prefs.getString(_courseNameKey) ?? "Bsc IT",
      'college': prefs.getString(_collegeKey) ?? "Birla College kalyan",
      'specilization': prefs.getString(_specilizationKey) ?? "Flutter",
      'courseType': prefs.getString(_courseTypeKey) ?? "Full-time",
      'gradingSystem': prefs.getString(_gradingSystemKey) ?? "CGPa",
      'percentage': prefs.getString(_percentageKey) ?? "86.5",
      'passingYear': prefs.getString(_passingYearKey) ?? "2025",
      'skills': prefs.getStringList(_skillsKey) ?? [],
      'projects': _decodeListMap(prefs.getStringList(_projectsKey) ?? []),
      'certificates': _decodeListMap(
        prefs.getStringList(_certificatesKey) ?? [],
      ),
      'workExperiences': _decodeListMap(
        prefs.getStringList(_workExperiencesKey) ?? [],
      ),
      'profileImage': prefs.getString(_profileImagePathKey) != null
          ? File(prefs.getString(_profileImagePathKey)!)
          : null,
    };
    print(
      'Loaded data: fullname=${loadedData['fullname']}, skills=${loadedData['skills']}, projects=${loadedData['projects']}',
    );
    return loadedData;
  }

  static List<Map<String, dynamic>> _decodeListMap(List<String> jsonList) {
    return jsonList
        .map((json) {
          if (json.isNotEmpty) {
            try {
              final decoded = jsonDecode(json);
              if (decoded is Map) {
                return decoded.map(
                  (key, value) => MapEntry(key.toString(), value),
                );
              }
            } catch (e) {
              print('Error decoding JSON: $e, json: $json');
            }
          }
          return <String, dynamic>{};
        })
        .toList()
        .cast<Map<String, dynamic>>();
  }
}

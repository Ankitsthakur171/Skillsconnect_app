import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../BottamTabScreens/AccountsTab/sharedpref.dart';
import 'ProfileEvent.dart';
import 'ProfileState.dart';

class ProfileBloc extends Bloc<ProfileEventsd, ProfileStatesd> {
  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfileData>(_onLoadProfileData);
    on<UpdateProfileData>(_onUpdateProfileData);
    on<ResetProfileData>(_onResetProfileData);
  }

  Future<void> _onLoadProfileData(
    LoadProfileData event,
    Emitter<ProfileStatesd> emit,
  ) async {
    emit(ProfileLoading());

    final data = await SharedPrefHelper.loadData();
    final name = data['fullname'] ?? '';
    final dobString = data['dob'] ?? '';
    final age = _calculateAge(dobString);
    final image = data['profileImage'] as File?;

    emit(
      ProfileDataLoaded(
        fullname: name,
        age: age,
        dob: dobString,
        profileImage: image,
      ),
    );
  }

  Future<void> _onUpdateProfileData(
    UpdateProfileData event,
    Emitter<ProfileStatesd> emit,
  ) async {
    emit(ProfileLoading());

    final existingData = await SharedPrefHelper.loadData();

    await SharedPrefHelper.saveData(
      fullname: event.fullname,
      dob: event.dob,
      phone: existingData['phone'],
      whatsapp: existingData['whatsapp'],
      email: existingData['email'],
      state: existingData['state'],
      city: existingData['city'],
      country: existingData['country'],
      educationDetail: existingData['educationDetail'],
      degreeType: existingData['degreeType'],
      courseName: existingData['courseName'],
      college: existingData['college'],
      specilization: existingData['specilization'],
      courseType: existingData['courseType'],
      gradingSystem: existingData['gradingSystem'],
      percentage: existingData['percentage'],
      passingYear: existingData['passingYear'],
      skills: List<String>.from(existingData['skills'] ?? []),
      projects: List<Map<String, dynamic>>.from(existingData['projects'] ?? []),
      certificates: List<Map<String, dynamic>>.from(
        existingData['certificates'] ?? [],
      ),
      workExperiences: List<Map<String, dynamic>>.from(
        existingData['workExperiences'] ?? [],
      ),
      profileImage: event.profileImage,
      languages: List<Map<String, dynamic>>.from(
        existingData['languages'] ?? [],
      ),
    );

    final age = _calculateAge(event.dob);

    emit(
      ProfileDataLoaded(
        fullname: event.fullname,
        age: age,
        dob: event.dob,
        profileImage: event.profileImage,
      ),
    );
  }

  int _calculateAge(String dob) {
    try {
      final date = DateFormat('dd, MMM yyyy').parse(dob);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _onResetProfileData(
    ResetProfileData event,
    Emitter<ProfileStatesd> emit,
  ) async {
    emit(ProfileInitial());
  }
}

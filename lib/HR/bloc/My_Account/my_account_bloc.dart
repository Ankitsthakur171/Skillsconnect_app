import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/Services/api_services.dart';
import 'package:skillsconnect/HR/bloc/My_Account/my_account_event.dart';
import 'package:skillsconnect/HR/bloc/My_Account/my_account_state.dart';
import 'package:skillsconnect/HR/model/service_api_model.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final HrProfile repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());

    try {
      final result = await HrProfile.fetchProfile();

      if (result['status'] == true && result['data'] != null) {
        final data = result['data'];

        final hr = (data['hrDetails'] != null && data['hrDetails'].isNotEmpty)
            ? data['hrDetails'][0]
            : null;

        final hrlinkedInDetails = (data['hrlinkedin'] != null && data['hrlinkedin'].isNotEmpty)
            ? data['hrlinkedin'][0]
            : null;
        // 🔹 NEW: read role from role_name[]
        final roleList = (data['role_name'] is List && (data['role_name'] as List).isNotEmpty)
            ? (data['role_name'] as List)
            : const [];
        final String roleName = roleList.isNotEmpty
            ? (roleList.first['role_name']?.toString() ?? 'HR ')
            : 'HR';


        if (hr != null) {
          final user = ProfileModel(
            fullname: hr['full_name'] ?? '',
            firstname: hr['first_name'] ?? '',
            lastname: hr['last_name'] ?? '',
            role: roleName,
            gender: hr['gender'] ?? 'Male', // agar API gender bhejti hai to use karo, warna default 'Male'
            phone: hr['mobile'] ?? '',
            whatsapp: hr['whatsapp_number'] ?? '',
            email: hr['email'] ?? '',
            location: hr['location'] ?? 'Mumbai, Maharashtra', // default if null
            linkedin: hrlinkedInDetails?['linkedin'] ?? '', // ✅ null ko empty string bana diya
            imageUrl: (hr['user_image'] != null && hr['user_image'].toString().isNotEmpty)
                ? hr['user_image']
                : '',
            profileCompletion: hr['profile_completion'] is int
                ? hr['profile_completion']
                : 90, // default if API na de
          );

          emit(ProfileLoaded(user));
        } else {
          emit(ProfileError("HR details not found"));
        }
      } else {
        emit(ProfileError("No data found"));
      }
    } catch (e) {
      emit(ProfileError("An error occurred: $e"));
    }
  }
}

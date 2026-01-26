import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEventsd extends Equatable {
  const ProfileEventsd();

  @override
  List<Object?> get props => [];
}

class LoadProfileData extends ProfileEventsd  {}

class UpdateProfileData extends ProfileEventsd {
  final String fullname;
  final String dob;
  final File? profileImage;

  const UpdateProfileData({
    required this.fullname,
    required this.dob,
    this.profileImage,
  });

  @override
  List<Object?> get props => [fullname, dob, profileImage];
}

class ResetProfileData extends ProfileEventsd {}


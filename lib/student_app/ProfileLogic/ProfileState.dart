import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileStatesd extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileStatesd {}

class ProfileLoading extends ProfileStatesd {}

class ProfileDataLoaded extends ProfileStatesd {
  final String fullname;
  final String dob;
  final int age;
  final File? profileImage;

  ProfileDataLoaded({
    required this.fullname,
    required this.dob,
    required this.age,
    required this.profileImage,
  });
}


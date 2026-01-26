import '../../../TPO/Model/tpo_home_job_model.dart';

abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashLoaded extends SplashState {}

class AuthenticatedTPO extends SplashState {

}

class AuthenticatedJob extends SplashState {}

class AuthenticatedStudent extends SplashState {}

class Unauthenticated extends SplashState {}

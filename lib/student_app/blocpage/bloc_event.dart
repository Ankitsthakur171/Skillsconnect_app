import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class GoToForgotPassword extends NavigationEvent {}

class SplashToLogin extends NavigationEvent {}

class GobackToLoginPage extends NavigationEvent {}

class GotoHomeScreen extends NavigationEvent {}

class GoHomeToLogin extends NavigationEvent {}

class GoToApplicationPage extends NavigationEvent {}

class GoToCollegeInnerScreen extends NavigationEvent {}

class GoTOStudentApplicationDetailScreen extends NavigationEvent {}

class GotoHomeScreen2 extends NavigationEvent {}

class GotoJobScreen2 extends NavigationEvent {}

class GoToInterviewScreen2 extends NavigationEvent {}

class GoToContactsScreen2 extends NavigationEvent {}

class GoToAccountScreen2 extends NavigationEvent {}

class GoToJobDetailScreenBT extends NavigationEvent {
  final String jobToken;
  final int jobId;

  const GoToJobDetailScreenBT({required this.jobToken, required this.jobId});

  @override
  List<Object> get props => [jobToken, jobId];
}

class GoToMyAccountScreen extends NavigationEvent {}

class GoToMyInterviewVideosScreen extends NavigationEvent {}

class LogintoHomeatab extends NavigationEvent {}

class GoToJobListFilters extends NavigationEvent {}

class GoToMyJobs extends NavigationEvent {}

class ResetNavigation extends NavigationEvent {}


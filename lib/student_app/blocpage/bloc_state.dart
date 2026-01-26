// abstract class NavigationState {}
//
// class initalState extends NavigationState {}
//
// class NavigatetoForgotPassword extends NavigationState {}
// class NavigateBacktoLoginin extends NavigationState {}
// class NavigateToLoginPage extends NavigationState {}
// class NavigateToHomeScreen extends NavigationState {}
// class NavigateHometoLogin extends NavigationState {}
// class NavigatetoApplicationPage extends NavigationState {}
// class NavigateToCollegeInnerScreen extends NavigationState {}
// class NavigateToStudentApplicationDetailScreen extends NavigationState {}
// class NavigateToHomeScreen2 extends NavigationState {}
// class NavigateToJobSecreen2 extends NavigationState {}
// class NavigateToInterviewScreen extends NavigationState {}
// class NavigateToContactsScreen extends NavigationState {}
// class NavigateToAccountScreen extends NavigationState {}
//
//
import 'package:equatable/equatable.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();
  @override
  List<Object> get props => [];
}
class NavigationIdle extends NavigationState {}

class initalState extends NavigationState {
  const initalState();
  @override
  List<Object> get props => ['initalState'];
}

class NavigatetoForgotPassword extends NavigationState {

  const NavigatetoForgotPassword();
  @override
  List<Object> get props => ['NavigatetoForgotPassword' ];
}

class NavigateBacktoLoginin extends NavigationState {
  const NavigateBacktoLoginin();
  @override
  List<Object> get props => ['NavigateBacktoLoginin'];
}

class NavigateToLoginPage extends NavigationState {
  const NavigateToLoginPage();
  @override
  List<Object> get props => ['NavigateToLoginPage'];
}

class NavigateToHomeScreen extends NavigationState {
  const NavigateToHomeScreen();
  @override
  List<Object> get props => ['NavigateToHomeScreen'];
}

class NavigateHometoLogin extends NavigationState {
  const NavigateHometoLogin();
  @override
  List<Object> get props => ['NavigateHometoLogin'];
}

class NavigatetoApplicationPage extends NavigationState {
  const NavigatetoApplicationPage();
  @override
  List<Object> get props => ['NavigatetoApplicationPage'];
}

class NavigateToCollegeInnerScreen extends NavigationState {
  const NavigateToCollegeInnerScreen();
  @override
  List<Object> get props => ['NavigateToCollegeInnerScreen'];
}

class NavigateToStudentApplicationDetailScreen extends NavigationState {
  const NavigateToStudentApplicationDetailScreen();
  @override
  List<Object> get props => ['NavigateToStudentApplicationDetailScreen'];
}

class NavigateToHomeScreen2 extends NavigationState {
  const NavigateToHomeScreen2();
  @override
  List<Object> get props => ['NavigateToHomeScreen2'];
}

class NavigateToJobSecreen2 extends NavigationState {
  const NavigateToJobSecreen2();
  @override
  List<Object> get props => ['NavigateToJobSecreen2'];
}

class NavigateToInterviewScreen extends NavigationState {
  const NavigateToInterviewScreen();
  @override
  List<Object> get props => ['NavigateToInterviewScreen'];
}

class NavigateToContactsScreen extends NavigationState {
  const NavigateToContactsScreen();
  @override
  List<Object> get props => ['NavigateToContactsScreen'];
}

class NavigateToAccountScreen extends NavigationState {
  const NavigateToAccountScreen();
  @override
  List<Object> get props => ['NavigateToAccountScreen'];
}

class NavigateTOJobDetailBT extends NavigationState {
  final String jobToken;
  final int jobId;

  const NavigateTOJobDetailBT({
    required this.jobToken,
    required this.jobId,
  });

  @override
  List<Object> get props => [jobToken, jobId];
}

class NavigateToMyAccount extends NavigationState {
  const NavigateToMyAccount();
  @override
  List<Object> get props => ['NavigateToMyAccount'];
}

class NavigateToMyInterviewVideos extends NavigationState {
  const NavigateToMyInterviewVideos();
  @override
  List<Object> get props => ['NavigateToMyInterviewVideos'];
}

class NavigateToJobListFilters extends NavigationState {
  const NavigateToJobListFilters();
  @override
  List<Object> get props => ['NavigateToJobListFilters'];
}

class NavigateToMyJob extends NavigationState {
  const NavigateToMyJob();
  @override
  List<Object> get props => ['NavigateToMyJob'];
}

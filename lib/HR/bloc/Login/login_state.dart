

class LoginState {
  final String email;
  final String password;
  final bool isValid;
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    required this.email,
    required this.password,
    required this.isValid,
    required this.isLoading,
    this.errorMessage,
  });

  //  Initial state
  factory LoginState.initial() {
    return const LoginState(
      email: '',
      password: '',
      isValid: false,
      isLoading: false,
      errorMessage: null,
    );
  }

  //  Copy with method
  LoginState copyWith({
    String? email,
    String? password,
    bool? isValid,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Success & Failure states (optional)
class LoginSuccess extends LoginState {
  LoginSuccess(LoginState previous)
      : super(
    email: previous.email,
    password: previous.password,
    isValid: true,
    isLoading: false,
  );
}

class LoginFailure extends LoginState {
  LoginFailure(LoginState previous, String errorMessage)
      : super(
    email: previous.email,
    password: previous.password,
    isValid: false,
    isLoading: false,
    errorMessage: errorMessage,
  );
}

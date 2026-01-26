import 'package:flutter/material.dart';
import '../Pages/forgotPasswordPage.dart';
import '../BottamTabScreens/Home/homeScreen.dart';
import '../BottamTabScreens/JobTab/JobScreenBT.dart';
import '../BottamTabScreens/Interveiwtab/InterviewScreen.dart';
import '../BottamTabScreens/ContactsTab/ContactsScreen.dart';
import '../BottamTabScreens/AccountsTab/AccountScreen.dart';
import 'package:skillsconnect/HR/screens/splash_screen.dart';
import 'package:skillsconnect/HR/screens/reset_password_screen.dart';

class StudentRoutes {
  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen2());
      case '/jobs':
        return MaterialPageRoute(builder: (_) => const Jobscreenbt());
      case '/interviews':
        return MaterialPageRoute(builder: (_) => const InterviewScreen());
      case '/contacts':
        return MaterialPageRoute(builder: (_) => const Contactsscreen());
      case '/account':
        return MaterialPageRoute(builder: (_) => const AccountScreen());
      case '/forgot':
        return MaterialPageRoute(builder: (_) => ResetPasswordScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'BottamTabScreens/AccountsTab/AccountScreen.dart';
import 'BottamTabScreens/ContactsTab/ContactsScreen.dart';
import 'BottamTabScreens/Home/homeScreen.dart';
import 'BottamTabScreens/Interveiwtab/InterviewScreen.dart';
import 'BottamTabScreens/JobTab/JobScreenBT.dart';
import 'blocpage/bloc_logic.dart';
import 'blocpage/bloc_state.dart';
import 'ProfileLogic/ProfileLogic.dart';
import 'ProfileLogic/ProfileEvent.dart';
import 'blocpage/BookmarkBloc/bookmarkLogic.dart';
import 'blocpage/jobFilterBloc/jobFilter_logic.dart';

class StudentRoot extends StatelessWidget {
  const StudentRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      child: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          if (state is NavigateToHomeScreen2) {
            return const HomeScreen2();
          } else if (state is NavigateToJobSecreen2) {
            return const Jobscreenbt();
          } else if (state is NavigateToInterviewScreen) {
            return const InterviewScreen();
          } else if (state is NavigateToContactsScreen) {
            return const Contactsscreen();
          } else if (state is NavigateToAccountScreen) {
            return const AccountScreen();
          }
          return const HomeScreen2();
        },
      ),
    );
  }
}
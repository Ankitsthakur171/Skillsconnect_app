
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/HR/screens/job_screen.dart';
import 'package:skillsconnect/HR/screens/interview_bottom_nav.dart';

import '../bloc/Contacts_page/contact_bloc.dart';
import '../bloc/Contacts_page/contact_event.dart';
import 'account_screen.dart';
import 'contacts_screen.dart';


class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  List<Widget> _pages(BuildContext context) => [
    const JobScreen(), // Main job screen
     InterviewBottomNav(meetings: [],), // Interview page
    BlocProvider(
      create: (_) => ContactBloc()..add(LoadContacts(page: 1)),
      child: const ContactScreen(),
    ),
    const HrAccountScreen(),
  ];

  Future<bool> _onWillPop() async {
    // agar Home par nahi ho -> pehle Home par lao
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false; // pop mat karo (app exit nahi)
    }
    // already Home par ho -> ab system ko pop/exit karne do
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope( onWillPop: _onWillPop,
      child:  Scaffold(
      body: _pages(context)[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        showUnselectedLabels: true,
        items: [
          _buildNavItem(assetPath: 'assets/home.png', label: 'Home', index: 0),
          _buildNavItem(assetPath: 'assets/interviews.png', label: 'Interviews', index: 1),
          _buildNavItem(assetPath: 'assets/phone.png', label: 'Calls', index: 2),
          _buildNavItem(assetPath: 'assets/account.png', label: 'Account', index: 3),
        ],
      ),
    ),);
  }

  BottomNavigationBarItem _buildNavItem({
    required String assetPath,
    required String label,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff005E6A) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              height: 24,
              width: 24,
              color: isSelected ? Colors.white : const Color(0xff005E6A),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      label: '',
    );
  }
}

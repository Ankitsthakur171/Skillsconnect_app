import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../Pages/bottombar.dart';
import 'ContactScreenCard.dart';
import 'ContactsAppbar.dart';

class Contactsscreen extends StatefulWidget {
  const Contactsscreen({super.key});

  @override
  State<Contactsscreen> createState() => _ContactsscreenState();
}

class _ContactsscreenState extends State<Contactsscreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  final List<Map<String, dynamic>> CardData = [
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Abhinav Verma",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
    {
      "ProfileImageUrl": "assets/portrait.png",
      "title": "TPO",
      "College": "Swami Vivekananda College",
      "Location": "Mumbai, India",
      "time": "12:00 PM",
    },
  ];
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double widthScale = size.width / 360;
    final double sizeScale = widthScale.clamp(0.95, 1.05);
    return Scaffold(
      appBar: ContactsScreenAppbar(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 0.5 * sizeScale, vertical: 5 * sizeScale),
          child: Column(
            children: CardData.map((item) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * sizeScale, vertical: 15 * sizeScale),
                child: ContactscreenCard(
                  ProfileImageUrl: item["ProfileImageUrl"],
                  title: item["title"],
                  College: item["College"],
                  location: item["Location"],
                  time: item["time"],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
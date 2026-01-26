import 'package:flutter/material.dart';

class ContactsScreenAppbar extends StatelessWidget implements PreferredSizeWidget {
  const ContactsScreenAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.4),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: Colors.black),
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  iconCircleButton(Icons.notifications_outlined),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }
  Widget iconCircleButton(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withOpacity(0.4)
        ),
        color: Colors.transparent,
      ),
      child: Icon(icon, size: 22, color: Colors.black),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(75); // Adjusted height
}
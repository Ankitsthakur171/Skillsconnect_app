import 'package:flutter/material.dart';

class AccountOptionTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  const AccountOptionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Color(0xFF005E6A);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: IconTheme(
          data: IconThemeData(color: selected ? Colors.white : Colors.black),
          child: icon,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Color(0xff445458),
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:barter_system/home.dart';
import 'package:barter_system/chats.dart';
import 'package:barter_system/skillpopup.dart';
import 'package:barter_system/community.dart';
import 'package:barter_system/studyroom.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MyHomePage(title: 'App name'),
    const Chats(),
    const SkillMatchApp(),
    const Community(),
    StudyRoom(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Always navigate to SkillMatchApp (skillpopup.dart) as a new page
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SkillMatchApp()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF123b53),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final List<IconData> icons = [
              Icons.home,
              Icons.chat_bubble_rounded,
              Icons.add_circle_outlined,
              Icons.groups_rounded,
              Icons.menu_book_rounded,
            ];
            final List<String> labels = [
              'Home',
              'Chats',
              'ADD',
              'Community',
              'Study Room'
            ];
            final isSelected = index == _selectedIndex;

            return GestureDetector(
              onTap: () => _onItemTapped(index),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 12 : 0, vertical: 8),
                decoration: isSelected
                    ? BoxDecoration(
                        color: Color.fromARGB(255, 178, 211, 240),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Row(
                  children: [
                    Icon(icons[index],
                        color: isSelected ? const Color.fromARGB(255, 67, 65, 65) : Colors.white),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(labels[index],
                            style: TextStyle(color: Colors.black)),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

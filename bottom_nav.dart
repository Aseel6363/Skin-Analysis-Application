import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../screens/home/home_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/routine/routine_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 1; // Default to Home (Index 1)

  final List<Widget> _pages = [
    const ProgressScreen(), // Index 0
    const HomeScreen(), // Index 1
    const RoutineScreen(), // Index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart), // Or your Progress icon SVG
            label: 'Progress',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa), // Or your Routine icon SVG
            label: 'My Routine',
          ),
        ],
      ),
    );
  }
}

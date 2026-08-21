import 'package:flutter/material.dart';

import 'alarm_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>{
  late final PageController _pageController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavItemSelected(int index) {
    if (_currentIndex == index) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              HomeScreen(),
              AlarmScreen(),
              ProfileScreen(),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HydrateBottomNavBar(
              currentIndex: _currentIndex,
              onItemSelected: _onNavItemSelected,
            ),
          ),
        ],
      ),
    );
  }
}
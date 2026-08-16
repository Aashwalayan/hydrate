import 'package:flutter/material.dart';

import 'alarm_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../../services/server_wake_service.dart';
import '../../widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late final PageController _pageController;
  final ServerWakeService _serverWakeService = ServerWakeService();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addObserver(this);
    // MainScreen only mounts once the user is authenticated and past
    // onboarding, i.e. exactly when the app is "actively open" in the
    // sense the keep-alive requirement means. Start immediately; it will
    // be paused and resumed by lifecycle changes from here on.
    _serverWakeService.startKeepAlive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _serverWakeService.startKeepAlive();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _serverWakeService.stopKeepAlive();
        break;
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _serverWakeService.dispose();
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
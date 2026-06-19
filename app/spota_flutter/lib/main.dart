import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/parking_lots_list_screen.dart';
import 'screens/operator_dashboard_screen.dart';

void main() {
  runApp(const SpotaApp());
}

class SpotaApp extends StatelessWidget {
  const SpotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spota',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const _RootNav(),
    );
  }
}

class _RootNav extends StatefulWidget {
  const _RootNav();

  @override
  State<_RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<_RootNav> {
  int _index = 0;

  static const _screens = [
    ParkingLotsListScreen(),
    OperatorDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.surface,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_parking_outlined),
              selectedIcon: Icon(Icons.local_parking_rounded, color: AppColors.primary),
              label: 'Find Parking',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'My Lots',
            ),
          ],
        ),
      ),
    );
  }
}

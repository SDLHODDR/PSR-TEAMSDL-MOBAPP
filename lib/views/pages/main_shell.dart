import 'package:flutter/material.dart';

import 'home_page.dart';
import 'route_page.dart';
import 'price_list_page.dart';
import 'pob_sob_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  static const List<NavigationDestination> _mobileDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: 'Route',
    ),
    NavigationDestination(
      icon: Icon(Icons.sell_outlined),
      selectedIcon: Icon(Icons.sell),
      label: 'Price List',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      selectedIcon: Icon(Icons.shopping_bag),
      label: 'POB/SOB',
    ),
  ];

  static const List<NavigationRailDestination> _tabletDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: Text('Route'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.sell_outlined),
      selectedIcon: Icon(Icons.sell),
      label: Text('Price List'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      selectedIcon: Icon(Icons.shopping_bag),
      label: Text('POB/SOB'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    // Use the shortest side so phones remain on bottom navigation even in
    // landscape, while only real tablets in landscape get a navigation rail.
    final isTablet = width >= 600 && height >= 600;
    final isLandscapeTablet = isTablet && width > height;

    // Keep each page alive when switching between navigation items.
    final pages = [
      const HomePage(),
      RoutePage(),
      const PriceListPage(),
      const PobSobPage(),
    ];

    if (isLandscapeTablet) {
      // Tablet landscape layout: persistent navigation on the left.
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: (value) {
                  setState(() => index = value);
                },
                extended: width >= 900,
                labelType: width >= 900 ? null : NavigationRailLabelType.all,
                minWidth: 76,
                minExtendedWidth: 190,
                groupAlignment: -0.75,
                backgroundColor: const Color(0xFFF7F9FC),
                selectedIconTheme: const IconThemeData(
                  color: Color(0xFF003250),
                  size: 27,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: Colors.blueGrey,
                  size: 24,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF003250),
                  fontWeight: FontWeight.w600,
                ),
                destinations: _tabletDestinations,
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE2E7ED),
              ),
              Expanded(
                child: IndexedStack(
                  index: index,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile layout: keep the existing bottom navigation.
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: _mobileDestinations,
      ),
    );
  }
}

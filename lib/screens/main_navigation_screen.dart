import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'competitions_screen.dart';
import 'all_matches_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

// الحاوية الرئيسية بعد تسجيل الدخول - تحتوي شريط تنقل سفلي (BottomNavigationBar)
// يربط بين 5 شاشات: الرئيسية، البطولات، كل المباريات، المفضلة، الملف الشخصي
class MainNavigationScreen extends StatefulWidget {
  final UserModel currentUser;

  const MainNavigationScreen({super.key, required this.currentUser});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // IndexedStack يحافظ على حالة كل شاشة عند التنقل بينها بدل إعادة بنائها من الصفر
    final screens = [
      HomeScreen(currentUser: widget.currentUser),
      CompetitionsScreen(currentUser: widget.currentUser),
      AllMatchesScreen(currentUser: widget.currentUser),
      FavoritesScreen(currentUser: widget.currentUser),
      ProfileScreen(currentUser: widget.currentUser),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'البطولات'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'المباريات'),
          NavigationDestination(icon: Icon(Icons.star_outline), selectedIcon: Icon(Icons.star), label: 'المفضلة'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

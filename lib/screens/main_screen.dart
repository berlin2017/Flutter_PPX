import 'package:flutter/material.dart';
import 'package:video_app/screens/my_page.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastTapTime;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeScreenKey),
      const Center(child: Text('发现')),
      const Center(child: Text('消息')),
      const MyPageScreen(),
    ];
  }

  void _handleNavTap(int index) {
    if (index == 0 && index == _currentIndex) {
      // 当点击首页tab且当前已在首页时
      final now = DateTime.now();
      if (_lastTapTime != null && 
          now.difference(_lastTapTime!) <= const Duration(milliseconds: 300)) {
        // 双击检测 - 300ms内的两次点击
        _homeScreenKey.currentState?.scrollToTopAndRefresh();
        _lastTapTime = null;
      } else {
        _lastTapTime = now;
      }
    } else {
      _lastTapTime = null;
    }
    
    setState(() {
      _currentIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _handleNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: '发现',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  static const String _themeModeKey = 'themeMode'; // 用于 SharedPreferences 的键

  ThemeMode _themeMode;

  ThemeNotifier(this._themeMode); // 构造函数现在接收初始值

  ThemeMode get themeMode => _themeMode;

  static ThemeMode getSystemThemeMode() {
    var brightness = SchedulerBinding.instance.window.platformBrightness;
    return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

  // 加载用户偏好的主题模式
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeModeIndex = prefs.getInt(_themeModeKey);

    if (savedThemeModeIndex != null) {
      _themeMode = ThemeMode.values[savedThemeModeIndex];
    } else {
      // 如果没有保存的偏好，则默认为系统主题
      _themeMode = ThemeMode.system;
    }
    // 注意：这里不需要 notifyListeners()，因为 ThemeNotifier 的实例在 main 函数中创建，
    // MaterialApp 的 themeMode 会在首次构建时读取这个 _themeMode。
  }

  // 设置并保存主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners(); // 通知 UI 更新

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index); // 保存 ThemeMode 的索引
  }

  // 静态方法，用于在应用启动时创建 ThemeNotifier 实例
  static Future<ThemeNotifier> create() async {
    final notifier = ThemeNotifier(ThemeMode.system); // 先给一个默认值
    await notifier._loadThemeMode(); // 然后加载保存的偏好
    return notifier;
  }
}
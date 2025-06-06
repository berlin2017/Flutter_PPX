import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_app/theme/app_themes.dart';
import 'package:video_app/theme/theme_notifier.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // 确保 Flutter 小部件绑定已初始化，这对于异步的 main 函数是必需的
  WidgetsFlutterBinding.ensureInitialized();

  // 创建并初始化 ThemeNotifier
  final themeNotifier = await ThemeNotifier.create();

  runApp(
    ChangeNotifierProvider.value( // 使用 .value 构造函数，因为它接收已创建的 notifier
      value: themeNotifier,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 从 Provider 获取 ThemeNotifier 的实例
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: '视频应用', // 你的应用标题
      theme: AppThemes.lightTheme,     // 你的浅色主题
      darkTheme: AppThemes.darkTheme,  // 你的深色主题
      themeMode: themeNotifier.themeMode, // 由 ThemeNotifier 控制
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

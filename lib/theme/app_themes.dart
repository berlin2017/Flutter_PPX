import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple, // 选择你的种子颜色
      brightness: Brightness.light,
    ),
    // 你可以进一步自定义其他主题属性:
    // appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
    // elevatedButtonTheme: ElevatedButtonThemeData(...)
    // textTheme: TextTheme(...) // 为浅色主题定义文本样式
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple, // 保持种子颜色一致，或根据需要更改
      brightness: Brightness.dark,
    ),
    // 自定义深色主题特有的属性:
    // appBarTheme: AppBarTheme(backgroundColor: Colors.grey[850]),
    // scaffoldBackgroundColor: Colors.black,
    // textTheme: TextTheme(...) // 为深色主题定义文本样式
  );
}
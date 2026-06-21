import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';

/// 应用入口文件
/// 配置 MaterialApp、全局主题、路由定义
/// 主色调：红色（primarySwatch），背景色：浅灰白
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JieLongApp());
}

/// 成语接龙应用根组件
class JieLongApp extends StatelessWidget {
  const JieLongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '成语接龙',
      debugShowCheckedModeBanner: false,
      // 全局主题配置
      theme: ThemeData(
        // 主色调：红色
        primarySwatch: _buildMaterialColor(Constants.PRIMARY_RED),
        // 页面背景色：浅灰白
        scaffoldBackgroundColor: Constants.BACKGROUND,
        // AppBar 主题
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          iconTheme: IconThemeData(color: Constants.TEXT_PRIMARY),
          titleTextStyle: TextStyle(
            color: Constants.TEXT_PRIMARY,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 底部导航栏主题
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Constants.PRIMARY_RED,
          unselectedItemColor: Constants.TEXT_SECONDARY,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.BORDER_RADIUS_SMALL),
            borderSide: const BorderSide(color: Constants.DIVIDER),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.BORDER_RADIUS_SMALL),
            borderSide: const BorderSide(color: Constants.DIVIDER),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.BORDER_RADIUS_SMALL),
            borderSide:
                const BorderSide(color: Constants.PRIMARY_RED, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Constants.BORDER_RADIUS_SMALL),
            borderSide:
                const BorderSide(color: Constants.PRIMARY_RED, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Constants.PRIMARY_RED,
            elevation: 2,
            shadowColor: Constants.PRIMARY_RED.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Constants.BORDER_RADIUS),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        // 文本按钮主题
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Constants.PRIMARY_RED,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(Constants.BORDER_RADIUS_SMALL),
            ),
          ),
        ),
        // 卡片主题
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: Constants.CARD_ELEVATION,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.BORDER_RADIUS),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        // 分隔线主题
        dividerTheme: const DividerThemeData(
          color: Constants.DIVIDER,
          thickness: 1,
          space: 1,
        ),
        // SnackBar 主题
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentTextStyle: const TextStyle(fontSize: 14),
        ),
        // 对话框主题
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Constants.TEXT_PRIMARY),
          displayMedium: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Constants.TEXT_PRIMARY),
          displaySmall: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Constants.TEXT_PRIMARY),
          headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Constants.TEXT_PRIMARY),
          headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Constants.TEXT_PRIMARY),
          headlineSmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Constants.TEXT_PRIMARY),
          titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Constants.TEXT_PRIMARY),
          titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Constants.TEXT_PRIMARY),
          titleSmall: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Constants.TEXT_PRIMARY),
          bodyLarge: TextStyle(
              fontSize: 16, color: Constants.TEXT_PRIMARY, height: 1.5),
          bodyMedium: TextStyle(
              fontSize: 14, color: Constants.TEXT_PRIMARY, height: 1.5),
          bodySmall: TextStyle(
              fontSize: 12, color: Constants.TEXT_SECONDARY, height: 1.4),
          labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Constants.TEXT_PRIMARY),
          labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Constants.TEXT_SECONDARY),
          labelSmall: TextStyle(fontSize: 11, color: Constants.TEXT_HINT),
        ),
      ),
      // 应用启动页面
      home: const SplashScreen(),
    );
  }

  /// 从单一颜色构建 MaterialColor（用于 primarySwatch）
  MaterialColor _buildMaterialColor(Color color) {
    const List<double> strengths = <double>[
      .05,
      .1,
      .2,
      .3,
      .4,
      .5,
      .6,
      .7,
      .8,
      .9
    ];
    const List<int> shades = <int>[
      50,
      100,
      200,
      300,
      400,
      500,
      600,
      700,
      800,
      900
    ];
    final Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;
    for (int i = 0; i < shades.length; i++) {
      swatch[shades[i]] = Color.fromRGBO(
        r + ((255 - r) * strengths[i]).round(),
        g + ((255 - g) * strengths[i]).round(),
        b + ((255 - b) * strengths[i]).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

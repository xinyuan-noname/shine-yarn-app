import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/components/first_view.dart';
import 'package:shine/pages/splash.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 预加载自定义字体
  final loader = FontLoader('SmileySans');
  loader.addFont(rootBundle.load('assets/fonts/SmileySans-Oblique.ttf'));
  await loader.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _prepareServer();
  }

  _prepareServer() async {
    ApiService.init();
    final tokenFuture = TokenStorage.getAccessToken();

    await Future.delayed(const Duration(seconds: 2));

    String? accessToken;
    try {
      accessToken = await tokenFuture;
    } catch (e) {
      accessToken = null;
    }

    if (accessToken != null) {
      ApiService.setAccessToken(accessToken);
      globalNavigatorKey.currentState?.pushReplacementNamed("/home");
    } else {
      globalNavigatorKey.currentState?.pushReplacementNamed("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: appRouters,
      navigatorKey: globalNavigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: bgColorLight,
        textTheme: TextTheme(labelMedium: TextStyle(fontSize: 14)),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      home: SplashPage(slot: firstViewLight),
    );
  }
}

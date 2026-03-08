import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shine/database/init_dependencies_datebase.dart';
import 'package:shine/pages/splash_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/event.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/worker/worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabase();
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
    _prepare();
  }

  _prepare() async {
    ApiService.init();
    await ApiService.waitOk();
    final tokenFuture = TokenStorage.getAccessToken();

    String? accessToken;
    try {
      accessToken = await tokenFuture;
    } catch (e) {
      accessToken = null;
    }

    if (accessToken != null) {
      ApiService.setAccessToken(accessToken);
      Worker.scheduleRefreshNow();
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
        appBarTheme: AppBarTheme(backgroundColor: bgColorLight),
        scaffoldBackgroundColor: bgColorLight,
        textTheme: TextTheme(labelMedium: TextStyle(fontSize: 14)),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      home: SplashPage(),
      builder: BotToastInit(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    EventBus.dispose();
  }
}

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shine/database/init_dependencies_datebase.dart';
import 'package:shine/services/launch_service.dart';
import 'package:shine/services/notification.dart';
import 'package:shine/pages/splash_page.dart';
import 'package:shine/routes.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/event.dart';
import 'package:shine/storage/token_storage.dart';
import 'package:shine/theme.dart';
import 'package:shine/utils/routes_utils.dart';
import 'package:shine/worker/worker.dart';

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  // 「打开方式」/「用闪纺打开」送来的文件要在界面就绪前先接住。
  LaunchService.init(arguments);
  initializeDatabase();
  final loader = FontLoader('SmileySans');
  loader.addFont(rootBundle.load('assets/fonts/SmileySans-Oblique.ttf'));
  await loader.load();
  NotificationService.init();
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
    try {
      ApiService.init();
      final serviceReady = ApiService.waitOk();
      if (LaunchService.hasPendingFile) {
        // 「打开方式」送来的文档在本地就能看，别让服务就绪检查把它卡在启动页
        // （网络不通时逐个探测服务器地址可能要等很久）。
        await serviceReady.timeout(const Duration(seconds: 3), onTimeout: () {});
      } else {
        await serviceReady;
      }
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
        globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          clearOldRouter,
        );
      } else {
        globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          "/login",
          clearOldRouter,
        );
      }
    } finally {
      // 上面的启动导航会清空路由栈，清完之后才能安全地打开外部送来的文档；
      // 即使准备过程出错也放行，用户双击的 PDF 不至于打不开。
      LaunchService.markReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: appRouters,
      navigatorKey: globalNavigatorKey,
      theme: ThemeData(
        fontFamily: kIsWeb
            ? 'SmileySans'
            : null,
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('zh', 'CN')],
    );
  }

  @override
  void dispose() {
    super.dispose();
    EventBus.dispose();
  }
}

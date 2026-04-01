import 'package:dio/dio.dart';

class AppConfig {
  // flutter run --dart-define=PRODUCTION=true
  // $env:CMAKE_TLS_VERIFY=0          
  // flutter run -d windows --dart-define=PRODUCTION=true
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  static const List<String> githubAndProxy = [
    "https://gitee.com/xinyuanwm",
    "https://gh.llkk.cc/https://raw.githubusercontent.com/xinyuan-noname",
    "https://raw.bgithub.xyz/xinyuan-noname",
    "https://raw.kkgithub.com/xinyuan-noname",
    "https://raw.githubusercontent.com/xinyuan-noname",
  ];

  static List<String> get serverUrlList {
    return githubAndProxy.map((origin) => getServerUrl(origin)).toList();
  }

  static String getServerUrl(String githubOrProxy) {
    if (githubOrProxy.isEmpty) return '';
    final String branch = isProduction ? 'prod' : 'main';
    final String repoPath =
        'git-github.com-xinyuan-noname-asset/$branch/url.txt';
    return '$githubOrProxy/$repoPath';
  }

  static String get stableServerUrl => getServerUrl(stableGithubOrProxy);
  static String stableGithubOrProxy = '';
  static void setStableGithubOrProxy(Response response) {
    stableGithubOrProxy = githubAndProxy.firstWhere(
      (origin) => response.realUri.toString().contains(origin),
    );
  }
}

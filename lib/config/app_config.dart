import 'package:dio/dio.dart';

class AppConfig {
  // flutter run --dart-define=PRODUCTION=true
  // flutter buil
  // flutter run -d windows --dart-define=PRODUCTION=true
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  static const List<String> githubAndProxy = [
    "https://gh.llkk.cc/https://raw.githubusercontent.com",
    "https://raw.bgithub.xyz",
    "https://raw.kkgithub.com",
    "https://raw.githubusercontent.com",
  ];

  static List<String> get serverUrlList {
    return githubAndProxy.map((origin) => getServerUrl(origin)).toList();
  }

  static String getServerUrl(String githubOrProxy) {
    if (githubOrProxy.isEmpty) return '';
    final String branch = isProduction ? 'prod' : 'main';
    final String repoPath =
        'xinyuan-noname/git-github.com-xinyuan-noname-asset/$branch/url.txt';
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

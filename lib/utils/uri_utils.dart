import 'package:shine/services/api.dart';

String ensureUrl(String url) {
  if (!Uri.parse(url).hasScheme) {
    if (url.startsWith('/')) {
      url = '${ApiService.url}$url';
    } else {
      url = '${ApiService.url}/$url';
    }
  }
  return url;
}

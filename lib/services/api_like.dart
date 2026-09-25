import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiLike {
  /// 把点赞接口的失败原因说清楚：带上状态码与服务端返回的说明
  ///
  /// 全局拦截器会把 4xx 统一改成「请求出错」，这里再补上细节，
  /// 否则用户只知道失败了却不知道是服务端没更新还是参数不合法。
  static String _describeError(DioException e, String fallback) {
    final status = e.response?.statusCode;
    if (status == 404) {
      return "$fallback: 服务器上没有这个接口(404)，请更新并重启服务端";
    }
    final data = e.response?.data;
    if (data is Map && data["error"] is String) {
      final message = (data["error"] as String).trim();
      if (message.isNotEmpty) return "$fallback: $message";
    }
    if (status != null) return "$fallback($status)";
    return e.message ?? fallback;
  }

  /// 给某个用户点赞, 成功返回 {targetId, likeCount, alreadyLiked}
  ///
  /// 每人每天对同一个用户只能点一次, 重复点击时 alreadyLiked 为 true
  static Future likeUser(String targetId) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.post('/like', data: {"targetId": targetId});
      return response.data;
    } on DioException catch (e) {
      return _describeError(e, "点赞失败");
    } catch (e) {
      return "点赞失败";
    }
  }

  /// 撤回今天给出的赞
  static Future cancelLike(String targetId) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.post(
        '/like/cancel',
        data: {"targetId": targetId},
      );
      return response.data;
    } on DioException catch (e) {
      return _describeError(e, "取消失败");
    } catch (e) {
      return "取消失败";
    }
  }

  /// 查询某个用户收到的赞, 返回 {targetId, likeCount, likedToday}
  static Future getLikeInfo(String targetId) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.get('/like/user/$targetId');
      return response.data;
    } on DioException catch (e) {
      return _describeError(e, "获取点赞信息失败");
    } catch (e) {
      return "获取点赞信息失败";
    }
  }

  /// 查询我今天已经赞了多少人, 返回 {day, likedCount}
  static Future getMyLikeSummary() async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.get('/like/my');
      return response.data;
    } on DioException catch (e) {
      return _describeError(e, "获取点赞信息失败");
    } catch (e) {
      return "获取点赞信息失败";
    }
  }
}

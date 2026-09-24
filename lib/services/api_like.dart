import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiLike {
  /// 给某个用户点赞, 成功返回 {targetId, likeCount, alreadyLiked}
  ///
  /// 每人每天对同一个用户只能点一次, 重复点击时 alreadyLiked 为 true
  static Future likeUser(String targetId) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.post('/like', data: {"targetId": targetId});
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "点赞失败";
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
      return e.message ?? "取消失败";
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
      return e.message ?? "获取点赞信息失败";
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
      return e.message ?? "获取点赞信息失败";
    } catch (e) {
      return "获取点赞信息失败";
    }
  }
}

import 'package:dio/dio.dart';
import 'package:shine/services/api.dart';
import 'package:shine/services/dio.dart';

class ApiVote {
  /// 发起投票, 成功返回 {taskId, onlineCount, offlineCount}
  static Future createVoteTask({
    required String title,
    required List<String> options,
    required List<String> voters,
    required bool multiple,
    required bool anonymous,
    required DateTime endedAt,
    int? maxChoices,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.post(
        '/task/vote/create',
        data: {
          "title": title,
          "options": options,
          "voters": voters,
          "multiple": multiple,
          "anonymous": anonymous,
          "endedAt": endedAt.millisecondsSinceEpoch,
          if (multiple && maxChoices != null) "maxChoices": maxChoices,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "发起投票失败";
    } catch (e) {
      return "发起投票失败";
    }
  }

  /// 获取投票详情(按身份裁剪字段: 发起人可看参与进度, 投票人可看自己的选择)
  static Future getVoteTask(int taskId) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.get('/task/vote/$taskId');
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "获取投票信息失败";
    } catch (e) {
      return "获取投票信息失败";
    }
  }

  /// 获取与我相关的投票: {participated: [...], created: [...]}
  static Future getMyVoteList() async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.get('/task/vote/mine');
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "获取投票列表失败";
    } catch (e) {
      return "获取投票列表失败";
    }
  }

  /// 提交投票, 重复提交会覆盖上一次的选择
  static Future submitVote({
    required int taskId,
    required List<int> optionIds,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
    try {
      final response = await dio.post(
        '/task/vote/submit',
        data: {"taskId": taskId, "optionIds": optionIds},
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "提交投票失败";
    } catch (e) {
      return "提交投票失败";
    }
  }

  /// 修改投票(仅发起人可用)
  static Future updateVoteTask({
    required int taskId,
    Map<String, dynamic>? taskData,
  }) async {
    if (!ApiService.prepared) return "服务未就绪";
    if (taskData == null || taskData.isEmpty) return null;
    try {
      final response = await dio.patch(
        '/task/vote/update',
        data: {"taskId": taskId, "taskData": taskData},
      );
      return response.data;
    } on DioException catch (e) {
      return e.message ?? "修改投票失败";
    } catch (e) {
      return "修改投票失败";
    }
  }
}

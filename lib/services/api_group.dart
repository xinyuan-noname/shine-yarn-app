import 'package:dio/dio.dart';
import 'package:shine/services/dio.dart';
import 'package:shine/storage/group_storage.dart';

class ApiGroup {
  static getGlobalGroupData(GroupStorageKey nameKeyEnum) async {
    try {
      final response = await dio.get('/group/${nameKeyEnum.name}');
      if (response.data is List) {
        return response.data;
      }
    } on DioException catch (e) {
      return e.message ?? "获取${nameKeyEnum.name}组信息失败";
    } catch (e) {
      return "获取${nameKeyEnum.name}组失败";
    }
  }
}

import 'package:shine/services/dio.dart';

class ApiAuth {
  static login(data) async {
    final response = await dio.post("/auth/login", data: data);
    print(response.data);
  }
}

import 'package:shine/services/api.dart';

class ApiAuth {
  static login(data) async {
    final response = await ApiService.dio.post("/auth/login", data: data);
    print(response.data);
  }
}

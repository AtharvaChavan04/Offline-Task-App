import 'dart:convert';
import 'package:frontend/core/constants/constants.dart';
import 'package:frontend/core/services/sp_services.dart';
import 'package:frontend/features/auth/repository/auth_local_repository.dart';
import 'package:frontend/models/user_model.dart';
import 'package:http/http.dart' as http;

class AuthRemoteRepository {
  final spServices = SpServices();
  final authLocalRepository = AuthLocalRepository();

  static const Duration _requestTimeout = Duration(seconds: 5);

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${Constants.backendUri}/auth/signup'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_requestTimeout); // Add timeout

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw jsonDecode(res.body)['error'] ?? 'Unknown error';
      }

      final responseData = jsonDecode(res.body);

      if (responseData['user'] != null) {
        return UserModel.fromMap(responseData['user']);
      } else {
        return UserModel.fromMap(responseData);
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${Constants.backendUri}/auth/login'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(_requestTimeout); // Add timeout

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'Unknown error';
      }

      return UserModel.fromJson(res.body);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      final token = await spServices.getToken();

      if (token == null) {
        return null;
      }

      final res = await http.post(
        Uri.parse('${Constants.backendUri}/auth/tokenIsValid'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      ).timeout(_requestTimeout); // Add timeout here!

      if (res.statusCode != 200 || jsonDecode(res.body) == false) {
        return null;
      }

      final userResponse = await http.get(
        Uri.parse('${Constants.backendUri}/auth'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      ).timeout(_requestTimeout); // Add timeout here too!

      if (userResponse.statusCode != 200) {
        throw jsonDecode(userResponse.body)['error'] ?? 'Unknown error';
      }

      final user = UserModel.fromJson(userResponse.body);
      return user;
    } catch (e) {
      try {
        final user = await authLocalRepository.getUser();
        return user;
      } catch (localError) {
        rethrow;
      }
    }
  }
}

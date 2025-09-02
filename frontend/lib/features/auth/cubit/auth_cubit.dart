import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/services/sp_services.dart';
import 'package:frontend/features/auth/repository/auth_local_repository.dart';
import 'package:frontend/features/auth/repository/auth_remote_repository.dart';
import 'package:frontend/models/user_model.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  final authRemoteRepository = AuthRemoteRepository();
  final spServices = SpServices();
  final authLocalRepository = AuthLocalRepository();

  void getUserData() async {
    try {
      emit(AuthLoading());

      final userModel = await authRemoteRepository.getUserData();

      if (userModel != null) {
        await authLocalRepository.insertUser(userModel);
        emit(AuthLoggedIn(user: userModel));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      try {
        final localUser = await authLocalRepository.getUser();

        if (localUser != null) {
          emit(AuthLoggedIn(user: localUser));
        } else {
          emit(AuthInitial());
        }
      } catch (localError) {
        emit(AuthInitial());
      }
    }
  }

  void signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      await authRemoteRepository.signUp(
        name: name,
        email: email,
        password: password,
      );
      emit(AuthSignUp());
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }

  void login({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      final userModel = await authRemoteRepository.login(
        email: email,
        password: password,
      );

      if (userModel.token.isNotEmpty) {
        await spServices.setToken(userModel.token);
      }

      await authLocalRepository.insertUser(userModel);

      emit(AuthLoggedIn(user: userModel));
    } catch (e) {
      emit(AuthError(error: e.toString()));
    }
  }
}

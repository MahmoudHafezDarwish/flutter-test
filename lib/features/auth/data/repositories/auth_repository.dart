import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fixit/core/cache/cache.dart';
import 'package:fixit/core/errors/exceptions.dart';
import 'package:fixit/core/errors/failures.dart';
import 'package:fixit/core/extension.dart';
import 'package:fixit/core/models/list_response.dart';
import 'package:fixit/core/models/single_m_response.dart';
import 'package:fixit/core/models/single_response.dart';
import 'package:fixit/core/models/success_response.dart';
import 'package:fixit/features/auth/data/dto/complete_registration.dart';
import 'package:fixit/features/auth/data/dto/social_account_user.dart';
import 'package:fixit/features/auth/data/models/country.dart';
import 'package:fixit/features/auth/data/models/user.dart';
import 'package:fixit/features/auth/data/models/user_meta.dart';
import 'package:fixit/features/profile/data/models/profile_meta.dart';
import 'package:fixit/injection_container.dart';

import '../datasources/auth_remote_data_source.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  static const cachedMobile = 'MOBILE';
  static const cachedUser = 'PROFILE';
  static const cachedToken = 'TOKEN';
  static const cachedTokenWC = 'WC_TOKEN';

  AuthRepository(this.remoteDataSource);

  Future<Either<Failure, SingleMResponse<User, UserMeta>>> login(
    String number,
    String password,
  ) async {
    try {
      final response = await remoteDataSource.login(number, password);
      await setUser(response);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    }
  }

  Future<Either<Failure, SingleMResponse<User, UserMeta>>> register(
    String number,
    String name,
    String password,
    String referralCode,
  ) async {
    try {
      final response =
          await remoteDataSource.register(number, name, password, referralCode);
      await setUser(response);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    }
  }

  Future<Either<Failure, SingleMResponse<User, ProfileMeta>>> profile() async {
    try {
      // TODO devmsh
      await loadCachedUser();
      final hasToken = await Cache.has(cachedToken);
      if (hasToken) {
        final response = await remoteDataSource.profile();
        setProfile(response);

        return Right(response);
      }
      return Left(ConnectionFailure());
    } on ServerException catch (e) {
      return Left(e.toFailure());
    } catch (error) {
      return Left(ConnectionFailure());
    }
  }

  Future loadCachedUser() async {
    try {
      appBloc.token = await Cache.get(cachedToken);
      appBloc.tokenWc = await Cache.get(cachedTokenWC);
      var profileResponse = await Cache.get(cachedUser,
          fromJsonFactory: SingleMResponse<User, ProfileMeta>.fromJson);

      appBloc.user = profileResponse.data;

      appBloc.profile = profileResponse.meta;

      appBloc.mobile = await Cache.get(cachedMobile);
    } catch (e) {
      appBloc.token = "123";
      appBloc.tokenWc = null;
    }
  }

  setUser(SingleMResponse<User, UserMeta> response) async {
    appBloc.user = response.data;
    await Cache.put(cachedUser, toProfile(response));
    appBloc.token = response.meta.token;
    appBloc.tokenWc = response.meta.wcToken;

    await Cache.put(cachedToken, response.meta.token);
    await Cache.put(cachedTokenWC, response.meta.wcToken);

    appBloc.mobile = response.data.mobile.replaceFirst("+966", "");

    await Cache.put(cachedMobile, response.data.mobile.englishNumbers());
  }

  SingleMResponse<User, ProfileMeta> toProfile(
    SingleMResponse<User, UserMeta> response,
  ) {
    return SingleMResponse<User, ProfileMeta>(
        response.data, ProfileMeta(restoredUser: true, id: response.data.id));
  }

  setProfile(SingleMResponse<User, ProfileMeta> response) async {
    appBloc.user = response.data;
    await Cache.put(cachedUser, response);
    await Cache.put(cachedMobile, response.data.mobile.englishNumbers());
  }

  Future<Either<Failure, SingleMResponse<User, UserMeta>>> completeRegistration(
      CompleteRegistration completeRegistrationData) async {
    try {
      final response =
          await remoteDataSource.completeRegistration(completeRegistrationData);
      await setUser(response);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    }
  }

  Future<Either<Failure, SingleMResponse<User, UserMeta>>> activation(
    String mobile,
    String code,
  ) async {
    try {
      final response = await remoteDataSource.activation(mobile, code);
      await setUser(response);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    }
  }

  Future<Either<Failure, SuccessResponse>> forget(String mobile) async {
    try {
      final response = await remoteDataSource.forget(mobile);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    } catch (error) {
      return Left(ConnectionFailure());
    }
  }

  Future<Either<Failure, String>> lastLoginMobile() async {
    try {
      final response = await Cache.get(cachedMobile);
      return Right(response);
    } on CacheException {
      return Left(CacheFailure());
    } catch (error) {
      return Left(CacheFailure());
    }
  }

  Future<Either<Failure, SuccessResponse>> resetPassword(
    String mobile,
    String newPassword,
    String confirmedPassword,
    String code,
  ) async {
    try {
      final response = await remoteDataSource.resetPassword(
        mobile,
        newPassword,
        confirmedPassword,
        code,
      );
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    } catch (error) {
      return Left(ConnectionFailure());
    }
  }

  Future<Either<Failure, void>> logout(other) async {
    try {
      final response = await remoteDataSource.logout(other);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    }
  }

  Future<Either<Failure, SuccessResponse>> resend(String mobile) async {
    try {
      final response = await remoteDataSource.resend(mobile);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    } catch (error) {
      return Left(ConnectionFailure());
    }
  }

  Future<Either<Failure, SuccessResponse>> changePassword(
    String currentPassword,
    String newPassword,
    String confirmedPassword,
  ) async {
    try {
      final response = await remoteDataSource.changePassword(
        currentPassword,
        newPassword,
        confirmedPassword,
      );
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    } catch (error) {
      return Left(ConnectionFailure());
    }
  }

  Future<Either<Failure, SingleResponse<User>>> editProfile(
    User profile,
  ) async {
    try {
      final response = await remoteDataSource.editProfile(profile);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    } catch (error) {
      return Left(ConnectionFailure());
    }
  }

  Future<Either<Failure, SuccessResponse>> delete(String reason) async {
    try {
      final response = await remoteDataSource.delete(reason);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    } catch (error) {
      return Left(ConnectionFailure());
    }
  }

  Future<Either<Failure, ListResponse<Country>>> countries() async {
    try {
      final response = await remoteDataSource.countries();
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    }
  }

  Future<Either<Failure, SingleResponse<User>>> clientInfo(
    int id,
  ) async {
    try {
      final response = await remoteDataSource.clientInfo(id);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    } catch (error) {
      return Left(ConnectionFailure());
    }
  }

  Future<Either<Failure, SuccessResponse>> updateToken() async {
    final hasToken = await Cache.has(cachedToken);
    if (hasToken) {
      try {
        final response = await remoteDataSource.updateToken();
        return Right(response);
      } on ServerException catch (e) {
        return Left(e.toFailure());
      } catch (error) {
        return Left(ConnectionFailure());
      }
    }
    return Future.error('no token');
  }

  clearAppData() {
    Cache.clear();
  }

  Future<Either<Failure, SingleMResponse<User, UserMeta>>> loginWithSocial({
    required SocialAccountUser user,
  }) async {
    try {
      final response = await remoteDataSource.loginWithSocial(user);
      await setUser(response);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    }
  }

  Future<Either<Failure, SingleMResponse<User, UserMeta>>>
      refreshToken() async {
    try {
      final response = await remoteDataSource.refreshToken();
      await setUser(response);
      return Right(response);
    } on ServerException catch (e) {
      return Left(e.toFailure());
    }
  }
}

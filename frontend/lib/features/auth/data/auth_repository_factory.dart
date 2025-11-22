import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/data/auth_repository_impl.dart';
import 'package:frontend/features/auth/data/auth_storage_impl.dart';

IAuthRepository createRemoteAuthRepository({required String baseUrl}) {
  final api = AuthApi(baseUrl: baseUrl);
  final storage = SecureTokenStorage();
  return AuthRepositoryImpl(api: api, storage: storage);
}

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/data/auth_repository_impl.dart';
import 'package:frontend/features/auth/data/auth_storage_impl.dart';
import 'package:frontend/features/my_account/data/user_repository_impl.dart';

IAuthRepository createRemoteAuthRepository({required String baseUrl}) {
  final api = AuthApi(baseUrl: baseUrl);
  final apiClient = ApiClient(baseUrl: baseUrl);
  final userRepository = UserRepositoryImpl(apiClient: apiClient);
  final storage = SecureTokenStorage();
  return AuthRepositoryImpl(
    api: api,
    userRepository: userRepository,
    storage: storage,
  );
}

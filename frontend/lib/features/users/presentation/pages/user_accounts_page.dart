import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/authenticated_client_factory.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_storage_impl.dart';
import 'package:frontend/features/users/application/bloc/user_accounts_bloc/user_accounts_bloc.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository_impl.dart';

/// User Accounts management page - accessible only to GLOBAL_ADMIN.
///
/// Access control is handled at the router level.
class UserAccountsPage extends StatelessWidget {
  /// Creates the user accounts page.
  const UserAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup repository with authenticated client
    final storage = SecureTokenStorage();
    final baseUrl = AppConfig.apiBaseUrl;
    final authenticatedClient = AuthenticatedClientFactory.create(
      storage: storage,
      onRefresh: (refreshToken) async {
        // Token refresh is handled by AuthenticatedClientFactory
        return '';
      },
    );
    final apiClient = ApiClient(baseUrl: baseUrl, client: authenticatedClient);
    final repository = UserRepositoryImpl(apiClient: apiClient);

    return BlocProvider(
      create: (context) => UserAccountsBloc(repository: repository)
        ..add(const UserAccountsLoadRequested(ordering: 'first_name')),
      child: const _UserAccountsPageContent(),
    );
  }
}

class _UserAccountsPageContent extends StatefulWidget {
  const _UserAccountsPageContent();

  @override
  State<_UserAccountsPageContent> createState() =>
      _UserAccountsPageContentState();
}

class _UserAccountsPageContentState extends State<_UserAccountsPageContent> {
  int _sortColumnIndex = 0;
  String _sortColumnKey = 'first_name';
  bool _sortAscending = true;
  User? _deletedUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<UserAccountsBloc, UserAccountsState>(
        listener: (context, state) {
          if (state.status == UserAccountsStatus.failure) {
            CustomSnackBar.showError(context, state.error ?? UserTexts.error);
          } else if (state.status == UserAccountsStatus.loaded &&
              _deletedUser != null) {
            final deleted = !state.users.any((u) => u.id == _deletedUser!.id);
            if (deleted) {
              CustomSnackBar.showSuccess(
                context,
                '${_deletedUser!.firstName} ${_deletedUser!.lastName} ${UserTexts.deleted}',
              );
              _deletedUser = null;
            }
          }
        },
        builder: (context, state) {
          if (state.status == UserAccountsStatus.loading &&
              state.users.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (state.status == UserAccountsStatus.failure &&
              state.users.isEmpty) {
            return _buildErrorState(context, state.error ?? 'Unknown error');
          }

          if (state.users.isEmpty &&
              state.status != UserAccountsStatus.loading &&
              state.status != UserAccountsStatus.failure) {
            return const _EmptyState();
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          UserTexts.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement add user functionality
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(UserTexts.addUser),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DataTable(
                            sortColumnIndex: _sortColumnIndex,
                            sortAscending: _sortAscending,
                            columns: _getColumns(),
                            rows: state.users
                                .map((user) => _buildUserRow(context, user))
                                .toList(),
                          ),
                          _buildPaginationControls(context, state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state.status == UserAccountsStatus.loading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<DataColumn> _getColumns() {
    return [
      DataColumn(
        columnWidth: const FlexColumnWidth(1.5),
        label: const Text(UserTexts.firstNameLastName),
        onSort: (columnIndex, ascending) {
          _onSort(columnIndex, 'first_name', ascending);
        },
      ),
      DataColumn(
        columnWidth: const FlexColumnWidth(1.5),
        label: const Text(UserTexts.username),
        onSort: (columnIndex, ascending) {
          _onSort(columnIndex, 'username', ascending);
        },
      ),
      DataColumn(
        columnWidth: const FlexColumnWidth(1.5),
        label: const Text(UserTexts.email),
        onSort: (columnIndex, ascending) {
          _onSort(columnIndex, 'email', ascending);
        },
      ),
      const DataColumn(
        columnWidth: const FlexColumnWidth(1.5),
        label: Text(UserTexts.role),
      ),
      const DataColumn(
          columnWidth: const FlexColumnWidth(1),
          label: Text(UserTexts.actions)),
    ];
  }

  DataRow _buildUserRow(BuildContext context, User user) {
    final currentUser = context.read<AuthBloc>().state.user;
    final isCurrentUser = user.id == currentUser?.id;
    final fullName = '${user.firstName} ${user.lastName}';

    return DataRow(
      cells: [
        DataCell(Text(fullName)),
        DataCell(Text(user.username)),
        DataCell(Text(user.email)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.role?.label ?? '-',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: UserTexts.edit,
                onPressed: () => _showEditDialog(context, user),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 18,
                  color: isCurrentUser ? Colors.grey : Colors.red,
                ),
                tooltip: isCurrentUser
                    ? UserTexts.cannotDeleteSelf
                    : UserTexts.delete,
                onPressed: isCurrentUser
                    ? null
                    : () => _showDeleteDialog(context, user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(BuildContext context, UserAccountsState state) {
    final start = (state.page - 1) * state.pageSize + 1;
    final end = (start + state.users.length - 1).clamp(0, state.count);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$start-$end ${UserTexts.on} ${state.count}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.previous != null
                ? () {
                    context.read<UserAccountsBloc>().add(
                          UserAccountsPageRequested(
                            page: state.page - 1,
                            ordering: _sortAscending
                                ? _sortColumnKey
                                : '-$_sortColumnKey',
                          ),
                        );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.next != null
                ? () {
                    context.read<UserAccountsBloc>().add(
                          UserAccountsPageRequested(
                            page: state.page + 1,
                            ordering: _sortAscending
                                ? _sortColumnKey
                                : '-$_sortColumnKey',
                          ),
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _onSort(int columnIndex, String columnKey, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortColumnKey = columnKey;
      _sortAscending = ascending;
    });
    context.read<UserAccountsBloc>().add(
          UserAccountsSortRequested(
            column: columnKey,
            ascending: ascending,
          ),
        );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            UserTexts.error,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context
                  .read<UserAccountsBloc>()
                  .add(const UserAccountsLoadRequested());
            },
            icon: const Icon(Icons.refresh),
            label: const Text(UserTexts.retry),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, User user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(UserTexts.editUserTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${UserTexts.editUser} ${user.username}'),
            const SizedBox(height: 16),
            const Text(UserTexts.editInProgress),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(UserTexts.close),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, User user) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(UserTexts.confirmDeleteTitle),
        content: Text(
          '${UserTexts.confirmDelete} ${user.firstName} ${user.lastName} (${user.username}) ?\n\n${UserTexts.irreversible}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(UserTexts.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _deletedUser = user;
              });
              context
                  .read<UserAccountsBloc>()
                  .add(UserAccountsDeleteRequested(userId: user.id));
            },
            child:
                const Text(UserTexts.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.globalAdmin:
        return AppColors.error;
      case UserRole.elected:
        return AppColors.warning;
      case UserRole.agent:
        return AppColors.info;
      case UserRole.citizen:
      default:
        return AppColors.success;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            UserTexts.noUsers,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            UserTexts.noUsersFound,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

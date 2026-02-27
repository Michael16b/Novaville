import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/users/data/user_repository_impl.dart';
import 'package:frontend/features/users/application/bloc/user_accounts_bloc/user_accounts_bloc.dart';
import 'package:frontend/core/network/authenticated_client_factory.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/auth_storage_impl.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';

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
        ..add(const UserAccountsLoadRequested()),
      child: const _UserAccountsPageContent(),
    );
  }
}

class _UserAccountsPageContent extends StatefulWidget {
  const _UserAccountsPageContent();

  @override
  State<_UserAccountsPageContent> createState() => _UserAccountsPageContentState();
}

class _UserAccountsPageContentState extends State<_UserAccountsPageContent> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  User? _deletedUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<UserAccountsBloc, UserAccountsState>(
        listener: (context, state) {
          if (state.status == UserAccountsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(UserTexts.error),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == UserAccountsStatus.loaded && _deletedUser != null) {
            final deleted = !state.users.any((u) => u.id == _deletedUser!.id);
            if (deleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_deletedUser!.firstName} ${_deletedUser!.lastName} ${UserTexts.deleted}'),
                  backgroundColor: Colors.green,
                ),
              );
              _deletedUser = null;
            }
          }
        },
        child: BlocBuilder<UserAccountsBloc, UserAccountsState>(
          builder: (context, state) {
            if (state.status == UserAccountsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == UserAccountsStatus.failure) {
              return _buildErrorState(context, state.error ?? 'Unknown error');
            }

            if (state.users.isEmpty) {
              return const _EmptyState();
            }

            return _buildUsersList(context, state.users);
          },
        ),
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

  Widget _buildUsersList(BuildContext context, List<User> users) {
    final blocState = context.watch<UserAccountsBloc>().state;
    final isLoading = blocState.status == UserAccountsStatus.loading;
    final page = blocState.page;
    final count = blocState.count;
    final pageSize = blocState.pageSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UserTexts.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: DataTable(
                    columns: [
                      DataColumn(
                        label: _buildSortableLabel(UserTexts.firstNameLastName, 0),
                        onSort: (columnIndex, ascending) {
                          _onSortColumn(columnIndex, 'first_name', ascending);
                        },
                      ),
                      DataColumn(
                        label: _buildSortableLabel(UserTexts.username, 1),
                        onSort: (columnIndex, ascending) {
                          _onSortColumn(columnIndex, 'username', ascending);
                        },
                      ),
                      DataColumn(
                        label: _buildSortableLabel(UserTexts.email, 2),
                        onSort: (columnIndex, ascending) {
                          _onSortColumn(columnIndex, 'email', ascending);
                        },
                      ),
                      DataColumn(
                        label: _buildSortableLabel(UserTexts.role, 3),
                        onSort: (columnIndex, ascending) {
                          _onSortColumn(columnIndex, 'role', ascending);
                        },
                      ),
                      DataColumn(label: const Text(UserTexts.actions)),
                    ],
                    rows: isLoading
                        ? [
                            DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(vertical: 32),
                                    child: const CircularProgressIndicator(),
                                  ),
                                ),
                                DataCell(Container()),
                                DataCell(Container()),
                                DataCell(Container()),
                                DataCell(Container()),
                              ],
                            ),
                          ]
                        : users
                            .map((user) => _buildUserRow(context, user))
                            .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: blocState.previous != null && !isLoading
                            ? () {
                                context.read<UserAccountsBloc>().add(
                                  UserAccountsPageRequested(page: page - 1),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text(UserTexts.previous),
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (_) {
                          final bool isLastPage = blocState.next == null;
                          final int end = isLastPage ? count : page * pageSize;
                          final int start = end - users.length + 1;
                          return Text('$start - $end ${UserTexts.on} $count', style: const TextStyle(fontWeight: FontWeight.w500));
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: blocState.next != null && !isLoading
                            ? () {
                                context.read<UserAccountsBloc>().add(
                                  UserAccountsPageRequested(page: page + 1),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text(UserTexts.next),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortableLabel(String label, int columnIndex) {
    final isSorted = _sortColumnIndex == columnIndex;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(label)),
        if (isSorted)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: Colors.blue,
            ),
          ),
      ],
    );
  }

  void _onSortColumn(int columnIndex, String columnKey, bool ascending) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
    });
    context.read<UserAccountsBloc>().add(
      UserAccountsSortRequested(
        column: columnKey,
        ascending: _sortAscending,
      ),
    );
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
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: UserTexts.edit,
                onPressed: () {
                  _showEditDialog(context, user);
                },
              ),
              // Delete button (disabled for current user)
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 18,
                  color: isCurrentUser ? Colors.grey : Colors.red,
                ),
                tooltip:
                    isCurrentUser ? UserTexts.cannotDeleteSelf : UserTexts.delete,
                onPressed: isCurrentUser
                    ? null
                    : () {
                        _showDeleteDialog(context, user);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.globalAdmin:
        return Colors.red;
      case UserRole.elected:
        return Colors.orange;
      case UserRole.agent:
        return Colors.blue;
      case UserRole.citizen:
      default:
        return Colors.green;
    }
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
      builder: (context) => AlertDialog(
        title: const Text(UserTexts.confirmDeleteTitle),
        content: Text(
          '${UserTexts.confirmDelete} ${user.firstName} ${user.lastName} (${user.username}) ?\n\n${UserTexts.irreversible}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(UserTexts.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _deletedUser = user;
              });
              context.read<UserAccountsBloc>().add(UserAccountsDeleteRequested(userId: user.id));
            },
            child: const Text(UserTexts.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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


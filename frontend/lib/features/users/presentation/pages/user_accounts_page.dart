import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/users/data/user_repository_impl.dart';
import 'package:frontend/features/users/application/bloc/user_accounts_bloc/user_accounts_bloc.dart';
import 'package:frontend/core/network/authenticated_client_factory.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/auth_storage_impl.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

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

class _UserAccountsPageContent extends StatelessWidget {
  const _UserAccountsPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des comptes utilisateurs'),
        actions: [
          // Refresh button
          BlocBuilder<UserAccountsBloc, UserAccountsState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context
                      .read<UserAccountsBloc>()
                      .add(const UserAccountsRefreshRequested());
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<UserAccountsBloc, UserAccountsState>(
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
            'Erreur',
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
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, List<User> users) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Prénom')),
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('Nom d\'utilisateur')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Rôle')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users
                .map((user) => _buildUserRow(context, user))
                .toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildUserRow(BuildContext context, User user) {
    final currentUser = context.read<AuthBloc>().state.user;
    final isCurrentUser = user.id == currentUser?.id;

    return DataRow(
      cells: [
        DataCell(Text(user.firstName ?? '-')),
        DataCell(Text(user.lastName ?? '-')),
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
                tooltip: 'Modifier',
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
                    isCurrentUser ? 'Impossible de supprimer votre compte' : 'Supprimer',
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
        title: const Text('Modifier l\'utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Édition du compte de ${user.username}'),
            const SizedBox(height: 16),
            const Text('Fonctionnalité en cours de développement'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, User user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${user.firstName} ${user.lastName} (${user.username}) ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<UserAccountsBloc>()
                  .add(UserAccountsDeleteRequested(userId: user.id));
              Navigator.pop(context);

              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('${user.firstName} ${user.lastName} a été supprimé'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
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
            'Aucun utilisateur',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun compte utilisateur trouvé',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/users/application/bloc/user_accounts_bloc/user_accounts_bloc.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:frontend/features/users/data/user_repository_factory.dart';
import 'package:frontend/features/users/presentation/widgets/user_account_card.dart';
import 'package:frontend/ui/widgets/expandable_fab_menu.dart';

/// User Accounts management page - accessible only to GLOBAL_ADMIN.
///
/// Access control is handled at the router level.
class UserAccountsPage extends StatelessWidget {
  /// Creates the user accounts page.
  ///
  /// [userRepository] can be provided for testing purposes.
  const UserAccountsPage({super.key, this.userRepository});

  /// The repository used to fetch user data.
  final IUserRepository? userRepository;

  @override
  Widget build(BuildContext context) {
    // Setup repository with authenticated client
    final repository = userRepository ?? _createDefaultRepository();

    return BlocProvider(
      create: (context) =>
          UserAccountsBloc(repository: repository)
            ..add(const UserAccountsLoadRequested(ordering: 'first_name')),
      child: const _UserAccountsPageContent(),
    );
  }

  IUserRepository _createDefaultRepository() {
    return createUserRepository();
  }
}

class _UserAccountsPageContent extends StatefulWidget {
  const _UserAccountsPageContent();

  @override
  State<_UserAccountsPageContent> createState() =>
      _UserAccountsPageContentState();
}

class _UserAccountsPageContentState extends State<_UserAccountsPageContent> {
  String _sortColumnKey = 'first_name';
  bool _sortAscending = true;
  int? _preferredCardsPerRow;
  User? _deletedUser;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _loadingTimer;
  String _searchQuery = '';
  bool _showLoadingOverlay = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _loadingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ExpandableFabMenu(
        heroTag: 'user-accounts-add-fab',
        tooltip: UserTexts.addActionsTooltip,
        actions: [
          FabMenuAction(
            label: UserTexts.addUser,
            icon: Icons.person_add_alt_1,
            onPressed: () => _showAddInProgressDialog(
              context,
              title: UserTexts.addUser,
              description: UserTexts.addSingleUserDescription,
            ),
          ),
          FabMenuAction(
            label: UserTexts.addUsers,
            icon: Icons.group_add,
            onPressed: () => _showAddInProgressDialog(
              context,
              title: UserTexts.addUsers,
              description: UserTexts.addMultipleUsersDescription,
            ),
          ),
        ],
      ),
      body: BlocConsumer<UserAccountsBloc, UserAccountsState>(
        listener: (context, state) {
          _handleLoadingOverlay(state);
          if (state.status == UserAccountsStatus.failure) {
            _deletedUser = null;
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
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      UserTexts.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildControlsSection(context, state),
                    const SizedBox(height: 12),
                    _buildResultsSection(context, state),
                  ],
                ),
              ),
              if (_showLoadingOverlay)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
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

  void _handleLoadingOverlay(UserAccountsState state) {
    if (state.status == UserAccountsStatus.loading) {
      if (_loadingTimer != null || _showLoadingOverlay) {
        return;
      }
      _loadingTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) {
          return;
        }
        final latest = context.read<UserAccountsBloc>().state;
        if (latest.status == UserAccountsStatus.loading) {
          setState(() {
            _showLoadingOverlay = true;
          });
        }
      });
      return;
    }

    _loadingTimer?.cancel();
    _loadingTimer = null;
    if (_showLoadingOverlay && mounted) {
      setState(() {
        _showLoadingOverlay = false;
      });
    }
  }

  Widget _buildControlsSection(BuildContext context, UserAccountsState state) {
    final sortItems = [
      (label: UserTexts.firstNameLastName, key: 'first_name'),
      (label: UserTexts.username, key: 'username'),
      (label: UserTexts.email, key: 'email'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: UserTexts.search,
                hintText: UserTexts.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSortAndLayoutControls(sortItems),
            const SizedBox(height: 8),
            _buildPaginationControls(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildSortAndLayoutControls(
    List<({String label, String key})> sortItems,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showCardsPerRowFilter =
            _maxCardsAllowedForWidth(constraints.maxWidth) > 1;

        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSortControlsWrap(sortItems),
              if (showCardsPerRowFilter) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  child: _buildCardsPerRowDropdown(constraints.maxWidth),
                ),
              ],
            ],
          );
        }

        if (!showCardsPerRowFilter) {
          return _buildSortControlsWrap(sortItems);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSortControlsWrap(sortItems)),
            const SizedBox(width: 12),
            SizedBox(
              width: 220,
              child: _buildCardsPerRowDropdown(constraints.maxWidth),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortControlsWrap(List<({String label, String key})> sortItems) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(UserTexts.sortBy, style: Theme.of(context).textTheme.titleSmall),
        for (final sortItem in sortItems)
          ChoiceChip(
            label: Text(sortItem.label),
            selected: _sortColumnKey == sortItem.key,
            onSelected: (_) => _applySort(sortItem.key, _sortAscending),
          ),
        OutlinedButton.icon(
          onPressed: () => _applySort(_sortColumnKey, !_sortAscending),
          icon: Icon(
            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
          ),
          label: Text(
            _sortAscending ? UserTexts.ascending : UserTexts.descending,
          ),
        ),
      ],
    );
  }

  Widget _buildCardsPerRowDropdown(double width) {
    final maxAllowedCount = _maxCardsAllowedForWidth(width);
    final options = <int?>[
      null,
      for (var count = 1; count <= maxAllowedCount; count++) count,
    ];
    final selectedValue =
        (_preferredCardsPerRow != null &&
            _preferredCardsPerRow! <= maxAllowedCount)
        ? _preferredCardsPerRow
        : null;

    return DropdownButtonFormField<int?>(
      value: selectedValue,
      isDense: true,
      decoration: const InputDecoration(
        labelText: UserTexts.cardsPerRow,
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<int?>(
              value: option,
              child: Text(option == null ? UserTexts.auto : option.toString()),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _preferredCardsPerRow = value;
        });
      },
    );
  }

  Widget _buildResultsSection(BuildContext context, UserAccountsState state) {
    if ((state.status == UserAccountsStatus.initial ||
            state.status == UserAccountsStatus.loading) &&
        state.users.isEmpty) {
      return _buildUsersSkeleton(context);
    }

    if (state.status == UserAccountsStatus.failure && state.users.isEmpty) {
      return _buildErrorState(context, state.error ?? 'Unknown error');
    }

    if (state.users.isEmpty) {
      return const _EmptyState();
    }

    return _buildUsersGrid(context, state.users);
  }

  ({int crossAxisCount, double childAspectRatio}) _computeGridLayout(
    double width,
  ) {
    const spacing = 14.0;
    const minCardWidth = 250.0;
    final maxByWidth = _maxCardsAllowedForWidth(width);

    final estimatedCount = ((width + spacing) / (minCardWidth + spacing))
        .floor()
        .clamp(1, maxByWidth);

    final maxAllowedCount = estimatedCount.clamp(1, maxByWidth);

    final chosenCount = _preferredCardsPerRow == null
        ? maxAllowedCount
        : _preferredCardsPerRow!.clamp(1, maxAllowedCount);

    final cardWidth = (width - (spacing * (chosenCount - 1))) / chosenCount;
    final estimatedCardHeight = chosenCount == 1
        ? 165.0
        : chosenCount == 2
        ? 185.0
        : 205.0;

    final childAspectRatio = (cardWidth / estimatedCardHeight).clamp(1.15, 2.4);

    return (crossAxisCount: chosenCount, childAspectRatio: childAspectRatio);
  }

  int _maxCardsAllowedForWidth(double width) {
    if (width < 700) {
      return 1;
    }
    if (width < 1000) {
      return 2;
    }
    if (width < 1300) {
      return 3;
    }
    return 4;
  }

  Widget _buildUsersSkeleton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _computeGridLayout(constraints.maxWidth);
        final crossAxisCount = layout.crossAxisCount;
        final childAspectRatio = layout.childAspectRatio;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _UserCardSkeleton();
          },
        );
      },
    );
  }

  Widget _buildUsersGrid(BuildContext context, List<User> users) {
    final currentUser = context.read<AuthBloc>().state.user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _computeGridLayout(constraints.maxWidth);
        final crossAxisCount = layout.crossAxisCount;
        final childAspectRatio = layout.childAspectRatio;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final user = users[index];
            return UserAccountCard(
              user: user,
              isCurrentUser: user.id == currentUser?.id,
              onEdit: (value) => _showEditDialog(context, value),
              onDelete: (value) => _showDeleteDialog(context, value),
              getRoleColor: _getRoleColor,
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationControls(
    BuildContext context,
    UserAccountsState state,
  ) {
    final start = (state.page - 1) * state.pageSize + 1;
    final end = (start + state.users.length - 1).clamp(0, state.count);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                        search: _searchQuery,
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
                        search: _searchQuery,
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _applySort(String columnKey, bool ascending) {
    setState(() {
      _sortColumnKey = columnKey;
      _sortAscending = ascending;
    });
    context.read<UserAccountsBloc>().add(
      UserAccountsSortRequested(
        column: columnKey,
        ascending: ascending,
        search: _searchQuery,
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      final nextQuery = value.trim();
      if (nextQuery == _searchQuery) {
        return;
      }
      setState(() {
        _searchQuery = nextQuery;
      });
      context.read<UserAccountsBloc>().add(
        UserAccountsSearchRequested(
          query: _searchQuery,
          ordering: _sortAscending ? _sortColumnKey : '-$_sortColumnKey',
        ),
      );
    });
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
              context.read<UserAccountsBloc>().add(
                UserAccountsLoadRequested(
                  ordering: _sortAscending
                      ? _sortColumnKey
                      : '-$_sortColumnKey',
                  search: _searchQuery,
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text(UserTexts.retry),
          ),
        ],
      ),
    );
  }

  void _showAddInProgressDialog(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 12),
            const Text(UserTexts.featureComingSoon),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(UserTexts.close),
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
              context.read<UserAccountsBloc>().add(
                UserAccountsDeleteRequested(userId: user.id),
              );
            },
            child: const Text(
              UserTexts.delete,
              style: TextStyle(color: Colors.red),
            ),
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
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
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

class _UserCardSkeleton extends StatefulWidget {
  const _UserCardSkeleton();

  @override
  State<_UserCardSkeleton> createState() => _UserCardSkeletonState();
}

class _UserCardSkeletonState extends State<_UserCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final barColor = Color.lerp(
          AppColors.secondaryText.withValues(alpha: 0.12),
          AppColors.secondaryText.withValues(alpha: 0.24),
          pulseValue,
        );
        final avatarColor = Color.lerp(
          AppColors.highlight.withValues(alpha: 0.6),
          AppColors.highlight,
          pulseValue,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: avatarColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 14, width: 120, color: barColor),
                          const SizedBox(height: 8),
                          Container(height: 12, width: 90, color: barColor),
                        ],
                      ),
                    ),
                    Container(height: 20, width: 72, color: barColor),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 12, width: double.infinity, color: barColor),
                const Spacer(),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(child: Container(height: 32, color: barColor)),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 32, color: barColor)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

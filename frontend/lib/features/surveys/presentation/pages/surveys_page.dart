import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_surveys.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/surveys/application/bloc/surveys_bloc.dart';
import 'package:frontend/features/surveys/data/models/survey.dart';
import 'package:frontend/features/surveys/data/survey_repository.dart';
import 'package:frontend/features/surveys/data/survey_repository_factory.dart';
import 'package:frontend/features/surveys/presentation/widgets/survey_card.dart';
import 'package:frontend/features/surveys/presentation/widgets/survey_form_dialog.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/ui/widgets/breadcrumb.dart';
import 'package:frontend/ui/widgets/expandable_fab_menu.dart';
import 'package:frontend/ui/widgets/page_header.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';

/// Surveys feature page.
class SurveysPage extends StatelessWidget {
  /// Creates the surveys page.
  const SurveysPage({super.key, this.surveyRepository});

  /// Repository used to fetch and mutate surveys.
  final ISurveyRepository? surveyRepository;

  @override
  Widget build(BuildContext context) {
    final repository = surveyRepository ?? createSurveyRepository();
    return BlocProvider(
      create: (_) =>
          SurveysBloc(repository: repository)
            ..add(const SurveysLoadRequested(citizenTargetSet: true)),
      child: const _SurveysPageContent(),
    );
  }
}

class _SurveysPageContent extends StatefulWidget {
  const _SurveysPageContent();

  @override
  State<_SurveysPageContent> createState() => _SurveysPageContentState();
}

class _SurveysPageContentState extends State<_SurveysPageContent> {
  final TextEditingController _addressController = TextEditingController();
  UserRole? _selectedTarget;
  int? _preferredCardsPerRow;
  String _sortColumnKey = 'created_at';
  bool _sortAscending = false;

  String get _currentOrdering =>
      _sortAscending ? _sortColumnKey : '-$_sortColumnKey';

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final isGlobalAdmin = authState.user?.isGlobalAdmin ?? false;
    final canManageSurveys =
        isGlobalAdmin || (authState.user?.isElected ?? false);
    final canFilterTarget =
        isGlobalAdmin || (authState.user?.isElected ?? false);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: canManageSurveys
          ? ExpandableFabMenu(
              heroTag: 'surveys-fab',
              tooltip: SurveysTexts.createSurvey,
              actions: [
                FabMenuAction(
                  label: SurveysTexts.createSurvey,
                  icon: Icons.how_to_vote,
                  onPressed: () => _showCreateDialog(context),
                ),
              ],
            )
          : null,
      body: BlocConsumer<SurveysBloc, SurveysState>(
        listener: _onStateChanged,
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  title: SurveysTexts.title,
                  description: SurveysTexts.titleDescription,
                  icon: Icons.how_to_vote,
                  breadcrumbItems: [BreadcrumbItem(label: SurveysTexts.title)],
                ),
                const SizedBox(height: 16),
                _buildFiltersCard(
                  context,
                  state,
                  canFilterTarget: canFilterTarget,
                ),
                const SizedBox(height: 12),
                _buildResults(
                  context: context,
                  state: state,
                  isAuthenticated: isAuthenticated,
                  canManageSurveys: canManageSurveys,
                  currentUserRole: authState.user?.role,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersCard(
    BuildContext context,
    SurveysState state, {
    required bool canFilterTarget,
  }) {
    final hasActiveFilter =
        _addressController.text.trim().isNotEmpty ||
        (canFilterTarget && _selectedTarget != null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: SurveysTexts.searchAddress,
                    hintText: SurveysTexts.searchAddressHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _applyFilters(context, page: 1),
                ),
                const SizedBox(height: 10),
                _buildSortControls(constraints.maxWidth),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 18,
                      color: AppColors.secondaryText,
                    ),
                    Text(
                      SurveysTexts.advancedFilters,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      onPressed: hasActiveFilter
                          ? () {
                              _addressController.clear();
                              setState(() {
                                if (canFilterTarget) {
                                  _selectedTarget = null;
                                }
                              });
                              _applyFilters(context, page: 1);
                            }
                          : null,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text(AppTextsGeneral.resetFilters),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (canFilterTarget) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SurveysTexts.filterByCitizenType,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _buildCitizenTargetChips(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                _buildPaginationControls(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResults({
    required BuildContext context,
    required SurveysState state,
    required bool isAuthenticated,
    required bool canManageSurveys,
    required UserRole? currentUserRole,
  }) {
    if (state.status == SurveysStatus.initial ||
        state.status == SurveysStatus.loading) {
      return _buildSurveysSkeleton();
    }

    if (state.status == SurveysStatus.failure && state.surveys.isEmpty) {
      return _buildError(context, state.error ?? SurveysTexts.loadError);
    }

    if (state.surveys.isEmpty) {
      return _buildEmpty(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _effectiveCardsPerRow(constraints.maxWidth);
        const spacing = 14.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final mainAxisExtent = _maxSurveyCardHeight(
          state: state,
          cardWidth: cardWidth,
          isAuthenticated: isAuthenticated,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.surveys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            final survey = state.surveys[index];
            return SurveyCard(
              survey: survey,
              isAuthenticated: isAuthenticated,
              isStaff: canManageSurveys,
              canVote: _canVoteOnSurvey(currentUserRole, survey),
              onVote: (optionId) => _onVoteTapped(
                context,
                surveyId: survey.id,
                optionId: optionId,
                isAuthenticated: isAuthenticated,
              ),
              onEdit: canManageSurveys
                  ? (s) => _showEditDialog(context, s)
                  : null,
              onDelete: canManageSurveys
                  ? () => _showDeleteDialog(context, survey.id)
                  : null,
            );
          },
        );
      },
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
      isExpanded: true,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(12),
      decoration: const InputDecoration(
        labelText: SurveysTexts.cardsPerRow,
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<int?>(
              value: option,
              child: Text(
                option == null ? SurveysTexts.auto : option.toString(),
              ),
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

  Widget _buildSortControls(double width) {
    final sortItems = [(label: SurveysTexts.sortByDate, key: 'created_at')];

    if (width < 860) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                SurveysTexts.sortBy,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final item in sortItems)
                ChoiceChip(
                  label: Text(item.label),
                  selected: _sortColumnKey == item.key,
                  onSelected: (_) => _applySort(item.key, _sortAscending),
                ),
              OutlinedButton.icon(
                onPressed: () => _applySort(_sortColumnKey, !_sortAscending),
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
                label: Text(
                  _sortAscending
                      ? SurveysTexts.ascending
                      : SurveysTexts.descending,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(width: 220, child: _buildCardsPerRowDropdown(width)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                SurveysTexts.sortBy,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final item in sortItems)
                ChoiceChip(
                  label: Text(item.label),
                  selected: _sortColumnKey == item.key,
                  onSelected: (_) => _applySort(item.key, _sortAscending),
                ),
              OutlinedButton.icon(
                onPressed: () => _applySort(_sortColumnKey, !_sortAscending),
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
                label: Text(
                  _sortAscending
                      ? SurveysTexts.ascending
                      : SurveysTexts.descending,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 220, child: _buildCardsPerRowDropdown(width)),
      ],
    );
  }

  List<Widget> _buildCitizenTargetChips(BuildContext context) {
    final options = <UserRole?>[null, ...UserRole.values];
    return options.map((role) {
      final isSelected = _selectedTarget == role;
      final label = role == null ? SurveysTexts.allCitizenTypes : role.label;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedTarget = role;
          });
          _applyFilters(context, page: 1);
        },
      );
    }).toList();
  }

  bool _canVoteOnSurvey(UserRole? role, Survey survey) {
    if (role == null) return false;
    if (role == UserRole.globalAdmin) return true;
    return survey.citizenTarget == null || survey.citizenTarget == role;
  }

  Widget _buildSurveysSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _effectiveCardsPerRow(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: 360,
          ),
          itemBuilder: (_, __) => const _SurveyCardSkeleton(),
        );
      },
    );
  }

  int _maxCardsAllowedForWidth(double width) {
    if (width < 700) return 1;
    if (width < 1000) return 2;
    if (width < 1300) return 3;
    return 3;
  }

  int _effectiveCardsPerRow(double width) {
    final maxAllowedCount = _maxCardsAllowedForWidth(width);
    if (_preferredCardsPerRow == null) {
      return maxAllowedCount;
    }
    return _preferredCardsPerRow!.clamp(1, maxAllowedCount);
  }

  double _maxSurveyCardHeight({
    required SurveysState state,
    required double cardWidth,
    required bool isAuthenticated,
  }) {
    var maxHeight = 280.0;
    for (final survey in state.surveys) {
      final estimated = _estimateCardHeight(
        survey: survey,
        cardWidth: cardWidth,
        isAuthenticated: isAuthenticated,
      );
      if (estimated > maxHeight) {
        maxHeight = estimated;
      }
    }
    return maxHeight;
  }

  double _estimateCardHeight({
    required Survey survey,
    required double cardWidth,
    required bool isAuthenticated,
  }) {
    final textWidth = (cardWidth - 32).clamp(180.0, 520.0);
    final titleLines = (survey.title.length / (textWidth / 10)).ceil().clamp(
      1,
      3,
    );
    final descriptionLines = survey.description.trim().isEmpty
        ? 0
        : (survey.description.length / (textWidth / 9.5)).ceil().clamp(1, 4);
    final optionsHeight = survey.options.length * 48.0;
    final unauthHint = isAuthenticated ? 0.0 : 24.0;

    return 180 +
        (titleLines * 20) +
        (descriptionLines * 18) +
        optionsHeight +
        unauthHint;
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.poll_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            SurveysTexts.noSurveys,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            SurveysTexts.noSurveysFound,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            SurveysTexts.loadError,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.read<SurveysBloc>().add(
              const SurveysLoadRequested(citizenTargetSet: true),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text(AppTextsGeneral.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, SurveysState state) {
    if (state.count == 0) {
      return const SizedBox.shrink();
    }

    final start = (state.page - 1) * state.pageSize + 1;
    final end = (start + state.surveys.length - 1).clamp(0, state.count);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$start-$end sur ${state.count}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.previous != null
                ? () => context.read<SurveysBloc>().add(
                    SurveysPageRequested(page: state.page - 1),
                  )
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.next != null
                ? () => context.read<SurveysBloc>().add(
                    SurveysPageRequested(page: state.page + 1),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _applyFilters(BuildContext context, {int page = 1}) {
    context.read<SurveysBloc>().add(
      SurveysFilterChanged(
        exactAddress: _addressController.text.trim(),
        citizenTarget: _selectedTarget,
        ordering: _currentOrdering,
        page: page,
        citizenTargetSet: true,
      ),
    );
  }

  void _applySort(String columnKey, bool ascending) {
    setState(() {
      _sortColumnKey = columnKey;
      _sortAscending = ascending;
    });

    context.read<SurveysBloc>().add(
      SurveysFilterChanged(
        exactAddress: _addressController.text.trim(),
        citizenTarget: _selectedTarget,
        ordering: _currentOrdering,
        page: 1,
        citizenTargetSet: true,
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const SurveyFormDialog(),
    );

    if (result == null || !mounted) return;

    context.read<SurveysBloc>().add(
      SurveyCreateRequested(
        question: result['question'] as String,
        description: result['description'] as String,
        address: result['address'] as String,
        options: result['options'] as List<String>,
        citizenTarget: result['citizen_target'] as UserRole?,
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, Survey survey) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SurveyFormDialog(survey: survey),
    );

    if (result == null || !mounted) return;

    context.read<SurveysBloc>().add(
      SurveyUpdateRequested(
        surveyId: survey.id,
        question: result['question'] as String,
        description: result['description'] as String,
        address: result['address'] as String,
        citizenTarget: result['citizen_target'] as UserRole?,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int surveyId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StyledDialog(
        title: SurveysTexts.deleteConfirmTitle,
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.error,
        closeTooltip: AppTextsGeneral.cancel,
        actions: [
          StyledDialog.cancelButton(
            label: AppTextsGeneral.cancel,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          StyledDialog.destructiveButton(
            label: AppTextsGeneral.delete,
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SurveysBloc>().add(
                SurveyDeleteRequested(surveyId: surveyId),
              );
            },
          ),
        ],
        body: const Text(SurveysTexts.deleteConfirmBody),
      ),
    );
  }

  void _onVoteTapped(
    BuildContext context, {
    required int surveyId,
    required int optionId,
    required bool isAuthenticated,
  }) {
    if (!isAuthenticated) {
      CustomSnackBar.showError(context, SurveysTexts.loginRequiredToVote);
      return;
    }
    context.read<SurveysBloc>().add(
      SurveyVoteRequested(surveyId: surveyId, optionId: optionId),
    );
  }

  void _onStateChanged(BuildContext context, SurveysState state) {
    switch (state.status) {
      case SurveysStatus.created:
        CustomSnackBar.showSuccess(context, SurveysTexts.createSuccess);
        break;
      case SurveysStatus.deleted:
        CustomSnackBar.showSuccess(context, SurveysTexts.deleteSuccess);
        break;
      case SurveysStatus.updated:
        CustomSnackBar.showSuccess(context, SurveysTexts.updateSuccess);
        break;
      case SurveysStatus.voted:
        CustomSnackBar.showSuccess(context, SurveysTexts.voteSuccess);
        break;
      case SurveysStatus.failure:
        CustomSnackBar.showError(
          context,
          state.error ?? SurveysTexts.genericError,
        );
        break;
      case SurveysStatus.initial:
      case SurveysStatus.loading:
      case SurveysStatus.loaded:
      case SurveysStatus.creating:
      case SurveysStatus.deleting:
      case SurveysStatus.updating:
      case SurveysStatus.voting:
        break;
    }
  }
}

class _SurveyCardSkeleton extends StatefulWidget {
  const _SurveyCardSkeleton();

  @override
  State<_SurveyCardSkeleton> createState() => _SurveyCardSkeletonState();
}

class _SurveyCardSkeletonState extends State<_SurveyCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
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

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(height: 24, width: 120, color: barColor),
                    const Spacer(),
                    Container(height: 24, width: 80, color: barColor),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 14, width: double.infinity, color: barColor),
                const SizedBox(height: 8),
                Container(height: 14, width: 220, color: barColor),
                const SizedBox(height: 12),
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    height: 36,
                    width: double.infinity,
                    color: barColor,
                  ),
                  const SizedBox(height: 8),
                ],
                const Spacer(),
                Container(height: 12, width: 100, color: barColor),
              ],
            ),
          ),
        );
      },
    );
  }
}

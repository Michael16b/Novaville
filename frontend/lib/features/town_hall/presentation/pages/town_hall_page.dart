import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_town_hall.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/neighborhood/data/neighborhood_repository.dart';
import 'package:frontend/features/neighborhood/data/neighborhood_repository_factory.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/ui/widgets/breadcrumb.dart';
import 'package:frontend/ui/widgets/expandable_fab_menu.dart';
import 'package:frontend/ui/widgets/page_header.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';

int _maxCardsAllowedForWidth(double width) {
  if (width < 600) return 1;
  if (width < 900) return 2;
  if (width < 1200) return 3;
  return 4;
}

/// Simple page for managing neighborhoods (Ma mairie)
class TownHallPage extends StatefulWidget {
  const TownHallPage({super.key, this.neighborhoodRepository});

  final INeighborhoodRepository? neighborhoodRepository;

  @override
  State<TownHallPage> createState() => _TownHallPageState();
}

class _TownHallPageState extends State<TownHallPage> {
  late final INeighborhoodRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  static const int _pageSize = 20;
  List<Neighborhood> _neighborhoods = [];
  bool _loading = false;
  String _searchQuery = '';
  int _currentPage = 1;
  int? _preferredCardsPerRow;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.neighborhoodRepository ?? createNeighborhoodRepository();
    _loadNeighborhoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNeighborhoods() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final list = await _repository.listNeighborhoods();
      if (!mounted) return;
      setState(() {
        _neighborhoods = list;
        _currentPage = 1;
      });
    } catch (_) {
      if (!mounted) return;
      CustomSnackBar.showError(context, TownHallTexts.loadError);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final result = await _showNeighborhoodDialog(
      title: TownHallTexts.createDialogTitle,
    );

    if (result != null && mounted) {
      final name = result['name']?.trim() ?? '';
      final postalCode = result['postal_code']?.trim() ?? '';
      if (name.isEmpty || postalCode.isEmpty) {
        CustomSnackBar.showWarning(context, TownHallTexts.requiredFieldsError);
        return;
      }

      try {
        await _repository.createNeighborhood(name, postalCode);
        await _loadNeighborhoods();
        if (!mounted) return;
        CustomSnackBar.showSuccess(context, TownHallTexts.createSuccess);
      } catch (_) {
        if (!mounted) return;
        CustomSnackBar.showError(context, TownHallTexts.createError);
      }
    }
  }

  Future<void> _showEditDialog(Neighborhood neighborhood) async {
    final result = await _showNeighborhoodDialog(
      title: TownHallTexts.editDialogTitle,
      initialName: neighborhood.name,
      initialPostalCode: neighborhood.postalCode,
    );

    if (result != null && mounted) {
      final name = result['name']?.trim() ?? '';
      final postalCode = result['postal_code']?.trim() ?? '';
      if (name.isEmpty || postalCode.isEmpty) {
        CustomSnackBar.showWarning(context, TownHallTexts.requiredFieldsError);
        return;
      }

      try {
        await _repository.updateNeighborhood(neighborhood.id, name, postalCode);
        await _loadNeighborhoods();
        if (!mounted) return;
        CustomSnackBar.showSuccess(context, TownHallTexts.updateSuccess);
      } catch (_) {
        if (!mounted) return;
        CustomSnackBar.showError(context, TownHallTexts.updateError);
      }
    }
  }

  Future<void> _confirmDelete(Neighborhood neighborhood) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StyledDialog(
        title: TownHallTexts.deleteDialogTitle,
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.error,
        closeTooltip: AppTextsGeneral.cancel,
        maxWidth: 420,
        actions: [
          StyledDialog.cancelButton(
            label: AppTextsGeneral.cancel,
            onPressed: () => Navigator.pop(d, false),
          ),
          StyledDialog.destructiveButton(
            label: AppTextsGeneral.delete,
            onPressed: () => Navigator.pop(d, true),
          ),
        ],
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(TownHallTexts.confirmDelete(neighborhood.name)),
            const SizedBox(height: 8),
            Text(
              TownHallTexts.irreversible,
              style: Theme.of(d).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await _repository.deleteNeighborhood(neighborhood.id);
        await _loadNeighborhoods();
        if (!mounted) return;
        CustomSnackBar.showSuccess(context, TownHallTexts.deleteSuccess);
      } catch (_) {
        if (!mounted) return;
        CustomSnackBar.showError(context, TownHallTexts.deleteError);
      }
    }
  }

  Future<Map<String, String?>?> _showNeighborhoodDialog({
    required String title,
    String? initialName,
    String? initialPostalCode,
  }) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final postalCtrl = TextEditingController(text: initialPostalCode ?? '');

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (dialogContext) => StyledDialog(
        title: title,
        icon: initialName == null ? Icons.add_location_alt : Icons.edit,
        closeTooltip: AppTextsGeneral.cancel,
        maxWidth: 500,
        actions: [
          StyledDialog.cancelButton(
            label: AppTextsGeneral.cancel,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          StyledDialog.primaryButton(
            label: initialName == null
                ? AppTextsGeneral.create
                : AppTextsGeneral.save,
            icon: initialName == null ? Icons.send_outlined : Icons.check,
            onPressed: () {
              Navigator.pop(dialogContext, {
                'name': nameCtrl.text,
                'postal_code': postalCtrl.text,
              });
            },
          ),
        ],
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TownHallTexts.createDialogMessage,
              style: Theme.of(
                dialogContext,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: TownHallTexts.neighborhoodNameLabel,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: postalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: TownHallTexts.postalCodeLabel,
              ),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    postalCtrl.dispose();
    return result;
  }

  List<Neighborhood> _filterNeighborhoods() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _neighborhoods;
    return _neighborhoods
        .where(
          (n) =>
              n.name.toLowerCase().contains(query) ||
              n.postalCode.toLowerCase().contains(query),
        )
        .toList();
  }

  int _computeTotalPages(int totalCount) {
    if (totalCount == 0) return 1;
    return (totalCount / _pageSize).ceil();
  }

  List<Neighborhood> _paginateNeighborhoods(List<Neighborhood> filteredItems) {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filteredItems.length) return const [];
    final end = (start + _pageSize).clamp(0, filteredItems.length);
    return filteredItems.sublist(start, end);
  }

  int _autoCrossAxisCount(double width) {
    return _maxCardsAllowedForWidth(width);
  }

  int _getCrossAxisCount(double width) {
    final count = _preferredCardsPerRow ?? _autoCrossAxisCount(width);
    return count.clamp(1, _maxCardsAllowedForWidth(width));
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
        labelText: TownHallTexts.cardsPerRow,
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<int?>(
              value: option,
              child: Text(
                option == null ? TownHallTexts.auto : option.toString(),
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

  Widget _buildControls(
    BuildContext context, {
    required int totalCount,
    required int pageCount,
    required int totalPages,
  }) {
    final start = totalCount == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
    final end = (start + pageCount - 1).clamp(0, totalCount);
    final hasPrevious = _currentPage > 1;
    final hasNext = _currentPage < totalPages;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },
              decoration: InputDecoration(
                labelText: TownHallTexts.search,
                hintText: TownHallTexts.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _currentPage = 1;
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final selectorWidth = constraints.maxWidth < 220
                    ? constraints.maxWidth
                    : 220.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: selectorWidth,
                          child: _buildCardsPerRowDropdown(
                            constraints.maxWidth,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          '$start-$end ${TownHallTexts.on} $totalCount',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        IconButton(
                          tooltip: TownHallTexts.previousPage,
                          onPressed: hasPrevious
                              ? () => setState(() => _currentPage--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          tooltip: TownHallTexts.nextPage,
                          onPressed: hasNext
                              ? () => setState(() => _currentPage++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNeighborhoods = _filterNeighborhoods();
    final totalCount = filteredNeighborhoods.length;
    final totalPages = _computeTotalPages(totalCount);
    final paginatedNeighborhoods = _paginateNeighborhoods(
      filteredNeighborhoods,
    );

    return Scaffold(
      backgroundColor: AppColors.page,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ExpandableFabMenu(
        heroTag: 'town-hall-fab',
        tooltip: TownHallTexts.createNeighborhood,
        actions: [
          FabMenuAction(
            label: TownHallTexts.createNeighborhood,
            icon: Icons.add_location_alt_outlined,
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: TownHallTexts.title,
              description: TownHallTexts.titleDescription,
              icon: Icons.account_balance_outlined,
              breadcrumbItems: [BreadcrumbItem(label: TownHallTexts.title)],
            ),
            const SizedBox(height: 16),
            if (_loading)
              _TownHallLoadingSkeleton(
                preferredCardsPerRow: _preferredCardsPerRow,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildControls(
                    context,
                    totalCount: totalCount,
                    pageCount: paginatedNeighborhoods.length,
                    totalPages: totalPages,
                  ),
                  const SizedBox(height: 12),
                  if (paginatedNeighborhoods.isEmpty)
                    _EmptyState(
                      message: _searchQuery.trim().isEmpty
                          ? TownHallTexts.noNeighborhoods
                          : TownHallTexts.noNeighborhoodsFound,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _getCrossAxisCount(
                                  constraints.maxWidth,
                                ),
                                mainAxisExtent: 190,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: paginatedNeighborhoods.length,
                          itemBuilder: (context, index) {
                            final neighborhood = paginatedNeighborhoods[index];
                            return _TownHallNeighborhoodCard(
                              neighborhood: neighborhood,
                              onEdit: () => _showEditDialog(neighborhood),
                              onDelete: () => _confirmDelete(neighborhood),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TownHallNeighborhoodCard extends StatelessWidget {
  const _TownHallNeighborhoodCard({
    required this.neighborhood,
    required this.onEdit,
    required this.onDelete,
  });

  final Neighborhood neighborhood;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apartment_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    neighborhood.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'CP: ${neighborhood.postalCode}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: _TownHallActionButton(
                    icon: Icons.edit_outlined,
                    label: AppTextsGeneral.edit,
                    color: AppColors.primary,
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _TownHallActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: AppTextsGeneral.delete,
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TownHallActionButton extends StatelessWidget {
  const _TownHallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap != null ? color : AppColors.disabled;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TownHallLoadingSkeleton extends StatefulWidget {
  const _TownHallLoadingSkeleton({this.preferredCardsPerRow});

  final int? preferredCardsPerRow;

  @override
  State<_TownHallLoadingSkeleton> createState() =>
      _TownHallLoadingSkeletonState();
}

class _TownHallLoadingSkeletonState extends State<_TownHallLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  int _skeletonCrossAxisCount(double width) {
    final maxAllowed = _maxCardsAllowedForWidth(width);
    final preferred = widget.preferredCardsPerRow;
    if (preferred == null) return maxAllowed;
    return preferred.clamp(1, maxAllowed);
  }

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
        final pulse = _pulseController.value;
        final barColor = Color.lerp(
          AppColors.secondaryText.withValues(alpha: 0.12),
          AppColors.secondaryText.withValues(alpha: 0.24),
          pulse,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final dropdownWidth =
                            constraints.maxWidth < 220
                                ? constraints.maxWidth
                                : 220.0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: dropdownWidth,
                              height: 46,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Container(
                          width: 150,
                          height: 16,
                          color: barColor,
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: barColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: barColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _skeletonCrossAxisCount(
                  constraints.maxWidth,
                );
                final itemCount = crossAxisCount * 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itemCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 190,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(height: 14, color: barColor),
                                ),
                                const SizedBox(width: 8),
                                Container(width: 44, height: 16, color: barColor),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 48,
              color: AppColors.emptyState,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.secondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

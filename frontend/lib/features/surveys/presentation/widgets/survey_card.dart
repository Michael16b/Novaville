import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_surveys.dart';
import 'package:frontend/features/surveys/data/models/survey.dart';

/// Card displaying one survey and direct vote actions.
class SurveyCard extends StatefulWidget {
  /// Creates a [SurveyCard].
  const SurveyCard({
    required this.survey,
    required this.isAuthenticated,
    required this.isStaff,
    required this.canVote,
    required this.onVote,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  /// Survey to render.
  final Survey survey;

  /// Whether the current user is authenticated.
  final bool isAuthenticated;

  /// Whether the current user has staff privileges.
  final bool isStaff;

  /// Whether the current user can answer this survey.
  final bool canVote;

  /// Callback called when user changes selected options.
  final ValueChanged<List<int>> onVote;

  /// Optional edit callback for staff.
  final ValueChanged<Survey>? onEdit;

  /// Optional delete callback for staff.
  final VoidCallback? onDelete;

  @override
  State<SurveyCard> createState() => _SurveyCardState();
}

class _SurveyCardState extends State<SurveyCard> {
  late Set<int> _selectedOptionIds;

  @override
  void initState() {
    super.initState();
    _selectedOptionIds = _initialSelectedOptionIds();
  }

  @override
  void didUpdateWidget(covariant SurveyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.survey != widget.survey) {
      _selectedOptionIds = _initialSelectedOptionIds();
    }
  }

  Set<int> _initialSelectedOptionIds() {
    final selectedIds = widget.survey.currentUserVoteOptionIds;
    if (selectedIds.isNotEmpty) {
      return selectedIds.toSet();
    }
    final selectedId = widget.survey.currentUserVoteOptionId;
    return selectedId == null ? <int>{} : <int>{selectedId};
  }

  @override
  Widget build(BuildContext context) {
    final survey = widget.survey;
    final isMultipleAnswers = survey.multipleAnswers;
    final totalVotes = survey.totalVotes;
    final canManage = widget.isStaff;
    final dateStr = _formatDate(survey.createdAt);
    final neighborhoodLabel =
        survey.neighborhood?.name ??
        (survey.address.trim().isNotEmpty
            ? survey.address
            : SurveysTexts.allNeighborhoods);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: isMultipleAnswers
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMultipleAnswers
                        ? AppColors.primary.withValues(alpha: 0.24)
                        : AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.how_to_vote,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    survey.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (survey.description.trim().isNotEmpty)
                    _SurveyDescription(
                      title: survey.title,
                      description: survey.description,
                    ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: neighborhoodLabel,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.groups_2_outlined,
                    text:
                        '${SurveysTexts.targetedAudience}: '
                        '${survey.citizenTarget?.label ?? SurveysTexts.targetAll}',
                  ),
                  if (survey.multipleAnswers) ...[
                    const SizedBox(height: 6),
                    const _InfoRow(
                      icon: Icons.checklist_rounded,
                      text: SurveysTexts.multipleAnswersBadge,
                    ),
                  ],
                  const SizedBox(height: 10),
                  ...survey.options.map((option) {
                    final isSelected = _selectedOptionIds.contains(option.id);
                    final percentage = totalVotes == 0
                        ? 0
                        : ((option.voteCount * 100) / totalVotes).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.tonal(
                        onPressed: widget.isAuthenticated && widget.canVote
                            ? () => _onOptionTapped(option.id)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: isSelected
                              ? AppColors.secondary
                              : null,
                          foregroundColor: isSelected
                              ? AppColors.primaryText
                              : null,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              survey.multipleAnswers
                                  ? (isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank)
                                  : (isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$percentage%'),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  Text(
                    '${survey.totalVotes} ${SurveysTexts.totalVotes}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (!widget.isAuthenticated) ...[
                    const SizedBox(height: 8),
                    Text(
                      SurveysTexts.loginRequiredToVote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canManage)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.edit_outlined,
                      label: AppTextsGeneral.edit,
                      color: AppColors.primary,
                      onTap: widget.onEdit != null
                          ? () => widget.onEdit!(survey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: AppTextsGeneral.delete,
                      color: AppColors.error,
                      onTap: widget.onDelete,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _onOptionTapped(int optionId) {
    final survey = widget.survey;
    final nextSelection = Set<int>.of(_selectedOptionIds);
    if (survey.multipleAnswers) {
      if (nextSelection.contains(optionId)) {
        if (nextSelection.length == 1) return;
        nextSelection.remove(optionId);
      } else {
        nextSelection.add(optionId);
      }
    } else {
      nextSelection
        ..clear()
        ..add(optionId);
    }

    setState(() {
      _selectedOptionIds = nextSelection;
    });
    widget.onVote(nextSelection.toList(growable: false));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primaryText),
          ),
        ),
      ],
    );
  }
}

class _SurveyDescription extends StatelessWidget {
  const _SurveyDescription({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.35);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: description, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
            if (isOverflowing)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _showFullDescription(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(SurveysTexts.seeMore),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFullDescription(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppTextsGeneral.close),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
